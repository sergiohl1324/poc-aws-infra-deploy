output "alb_dns_name" {
  description = "DNS name del ALB — probar con: curl http://<este_valor>"
  value       = module.alb.alb_dns_name
}

output "app_server_instance_id" {
  description = "ID de la instancia EC2 — usar con: aws ssm start-session --target <id>"
  value       = module.app_server.instance_id
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.vpc.vpc_id
}
