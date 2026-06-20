#!/usr/bin/env bash
# Interview demo helper: verify the deployed POC (ALB + EC2 + nginx/uWSGI) is alive
# and let you toggle the enable_uwsgi bonus live.
#
# Usage (run from anywhere, it cd's to the repo root itself):
#   scripts/demo.sh curl              -> curl the ALB and show response headers/body
#   scripts/demo.sh status            -> SSM into the instance (no session needed) and
#                                          show systemctl/socket/nginx config/journal
#   scripts/demo.sh session           -> open an interactive SSM session (no SSH)
#   scripts/demo.sh toggle-on         -> set enable_uwsgi=true, apply, wait, curl
#   scripts/demo.sh toggle-off        -> set enable_uwsgi=false, apply, wait, curl
#
# Requires: aws CLI configured with the "personal-poc" profile (or set AWS_PROFILE),
# terraform, and for `session` only: `brew install --cask session-manager-plugin`.

set -euo pipefail
cd "$(dirname "$0")/.."

PROFILE="${AWS_PROFILE:-personal-poc}"
REGION="${AWS_REGION:-us-east-2}"

alb_dns() { terraform output -raw alb_dns_name; }
instance_id() { terraform output -raw app_server_instance_id; }

cmd_curl() {
  local dns; dns=$(alb_dns)
  echo "--- curl -i http://${dns} ---"
  curl -i -m 10 "http://${dns}"
}

cmd_status() {
  local id; id=$(instance_id)
  echo "--- Querying instance ${id} via SSM (no SSH, no interactive session needed) ---"
  local cmd_id
  cmd_id=$(aws ssm send-command \
    --instance-ids "${id}" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["echo === systemctl status uwsgi ===","systemctl status uwsgi --no-pager -l || true","echo === uwsgi socket ===","ls -la /run/uwsgi/ 2>&1","echo === active nginx site config ===","cat /etc/nginx/sites-enabled/default","echo === nginx -t ===","nginx -t","echo === recent uwsgi requests ===","journalctl -u uwsgi -n 15 --no-pager"]' \
    --profile "${PROFILE}" --region "${REGION}" \
    --query "Command.CommandId" --output text)
  sleep 4
  aws ssm get-command-invocation \
    --command-id "${cmd_id}" --instance-id "${id}" \
    --profile "${PROFILE}" --region "${REGION}" \
    --query "StandardOutputContent" --output text
}

cmd_session() {
  local id; id=$(instance_id)
  echo "--- Opening interactive SSM session on ${id} (Ctrl+D to exit) ---"
  aws ssm start-session --target "${id}" --profile "${PROFILE}" --region "${REGION}"
}

cmd_toggle() {
  local value="$1" # true|false
  local expect
  [[ "${value}" == "true" ]] && expect="nginx + uWSGI" || expect="nginx static"

  echo "--- Setting enable_uwsgi = ${value} in terraform.tfvars ---"
  sed -i.bak -E "s/^enable_uwsgi[[:space:]]*=.*/enable_uwsgi   = ${value}/" terraform.tfvars
  rm -f terraform.tfvars.bak

  echo "--- terraform apply (will force-replace the EC2 instance) ---"
  terraform apply -auto-approve

  echo "--- Waiting for the new instance to boot and serve '${expect}' (cloud-init takes ~30-90s, longer the first time uWSGI is compiled) ---"
  until curl -s -m 5 "http://$(alb_dns)" 2>/dev/null | grep -q "${expect}"; do
    sleep 5
  done

  echo "--- Done ---"
  cmd_curl
}

case "${1:-}" in
  curl)       cmd_curl ;;
  status)     cmd_status ;;
  session)    cmd_session ;;
  toggle-on)  cmd_toggle true ;;
  toggle-off) cmd_toggle false ;;
  *)
    echo "Usage: $0 {curl|status|session|toggle-on|toggle-off}"
    exit 1
    ;;
esac
