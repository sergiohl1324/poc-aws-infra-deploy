# poc-aws-infra-deploy

AWS infrastructure POC for a job interview exercise: **VPC + ALB + Application Server (nginx, with a uWSGI bonus)**.

All configuration lives at the repo root (single-environment setup, no multi-account/multi-tier structure).

Orchestrates 4 of my own Terraform modules:
- [mod-aws-vpc](https://github.com/sergiohl1324/mod-aws-vpc)
- [mod-aws-security-group](https://github.com/sergiohl1324/mod-aws-security-group) (ALB security group)
- [mod-aws-alb](https://github.com/sergiohl1324/mod-aws-alb)
- [mod-aws-app-server](https://github.com/sergiohl1324/mod-aws-app-server) (itself uses `mod-aws-security-group` and [mod-aws-iam-role](https://github.com/sergiohl1324/mod-aws-iam-role))

## Architecture

- 1 VPC, no NAT Gateway (cost saving) — the Application Server lives in a **public** subnet with its own public IP for outbound internet access (apt/pip/SSM).
- 1 ALB (HTTP:80) → 1 Target Group → the EC2 instance.
- The EC2 security group only allows ingress on :80 **from the ALB's security group** — no SSH exposed. Administrative access via **SSM Session Manager**.
- uWSGI bonus controlled by the `enable_uwsgi` variable: `false` serves the static HTML via nginx; `true` makes nginx reverse-proxy to uWSGI.

## State backend

Remote S3 (bucket created/managed outside this repo):

```hcl
backend "s3" {
  bucket       = "chebogime-s3-states"
  key          = "poc/terraform.tfstate"
  region       = "us-east-1"
  use_lockfile = true
  encrypt      = true
}
```

`use_lockfile = true` uses S3's native locking (Terraform >= 1.15.5) — no DynamoDB table needed.

## Visibility requirement

`mod-aws-security-group` is a legacy repo. Since `main.tf` and `mod-aws-app-server` reference it via `git::https://github.com/...`, it must stay **public** (same as `mod-aws-vpc`) so `terraform init` works without extra credentials.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set ami_id to a current Ubuntu 22.04/24.04 LTS AMI in your region

terraform init
terraform plan
terraform apply
```

Test it:

```bash
curl http://$(terraform output -raw alb_dns_name)
```

Should return the HTML with "Served via: nginx static".

### Enabling the uWSGI bonus

```bash
# in terraform.tfvars: enable_uwsgi = true
terraform apply
```

The plan will show `# forces replacement` on the EC2 instance (the `user_data` change is intentionally not ignored — see `mod-aws-app-server`'s README). Wait for boot (~2-3 min, compiles uWSGI) and `curl` again — it should now respond "Served via: nginx + uWSGI".

### Debugging

No SSH exposed:

```bash
aws ssm start-session --target $(terraform output -raw app_server_instance_id)
cat /var/log/user-data.log
journalctl -u uwsgi
```

### When done — destroy

```bash
terraform destroy
```

**Important:** the ALB has a fixed hourly cost (~$0.0225/h + LCU) and so does the EC2 instance — don't leave the infrastructure running after the interview.

## Implementation notes

- **Versions:** `required_version >= 1.15.5`, provider `hashicorp/aws ~> 6.47` across all modules and here — matching the reference examples.
- Modules are referenced with `?ref=main` (no `v0.1.0` tags exist yet — the tool used to automate this didn't have permission to create git tags via the API). To pin a real version: in each module repo run `git fetch && git tag v0.1.0 && git push --tags`, then change `?ref=main` to `?ref=v0.1.0` in `main.tf`.
- Both the ALB's security group and the Application Server's security group are created via the `mod-aws-security-group` module (no inline `resource "aws_security_group"` in this repo or in `mod-aws-app-server`).
