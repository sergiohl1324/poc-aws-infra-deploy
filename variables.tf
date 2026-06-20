variable "project" {
  description = "Nombre del proyecto (naming/tagging)"
  type        = string
  default     = "poc"
}

variable "environment" {
  description = "Ambiente lógico usado para tagging"
  type        = string
  default     = "nonproduction"
}

variable "region" {
  description = "Región AWS donde desplegar"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block de la VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "azs" {
  description = "Availability zones a usar"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "CIDRs de subnets públicas (ALB + EC2 app server, sin NAT Gateway)"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "ami_id" {
  description = "AMI del Application Server. Recomendado: Ubuntu 22.04/24.04 LTS vigente en la región elegida."
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2 del Application Server"
  type        = string
  default     = "t3.micro"
}

variable "enable_uwsgi" {
  description = "Bonus del ejercicio: true = nginx + uWSGI; false = nginx sirve el HTML estático directo"
  type        = bool
  default     = false
}

variable "html_title" {
  description = "Título de la página de prueba"
  type        = string
  default     = "POC AWS — Sergio Hernández"
}

variable "html_message" {
  description = "Mensaje de la página de prueba"
  type        = string
  default     = "Infraestructura desplegada con Terraform: VPC + ALB + EC2"
}
