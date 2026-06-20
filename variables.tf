variable "project" {
  description = "Project name (naming/tagging)"
  type        = string
  default     = "poc"
}

variable "environment" {
  description = "Logical environment used for tagging"
  type        = string
  default     = "nonproduction"
}

variable "region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.20.0.0/16"
}

variable "azs" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "Public subnet CIDRs (ALB + EC2 app server, no NAT Gateway)"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "ami_id" {
  description = "Application Server AMI. Recommended: a current Ubuntu 22.04/24.04 LTS AMI in the chosen region."
  type        = string
}

variable "instance_type" {
  description = "Application Server EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "enable_uwsgi" {
  description = "Exercise bonus: true = nginx + uWSGI; false = nginx serves the static HTML directly"
  type        = bool
  default     = false
}

variable "html_title" {
  description = "Title of the test page"
  type        = string
  default     = "POC AWS — Sergio Hernandez"
}

variable "html_message" {
  description = "Message shown on the test page"
  type        = string
  default     = "Infrastructure deployed with Terraform: VPC + ALB + EC2"
}
