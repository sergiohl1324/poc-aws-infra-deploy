output "alb_dns_name" {
  description = "ALB DNS name — test with: curl http://<this_value>"
  value       = module.alb.alb_dns_name
}

output "app_server_instance_id" {
  description = "EC2 instance ID — use with: aws ssm start-session --target <id>"
  value       = module.app_server.instance_id
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}
