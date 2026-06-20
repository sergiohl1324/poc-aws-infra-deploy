### SECURITY GROUP — ALB ###

module "sg_alb" {
  source = "git::https://github.com/sergiohl1324/mod-aws-security-group.git?ref=main"

  name        = "${var.project}-sg-alb"
  description = "Allow HTTP entrance from Internet"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP from internet"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_rules = ["all-all"]

  project     = var.project
  environment = var.environment
}

### VPC ###

module "vpc" {
  source = "git::https://github.com/sergiohl1324/mod-aws-vpc.git?ref=main"

  project     = var.project
  environment = var.environment

  cidr               = var.vpc_cidr
  azs                = var.azs
  public_subnets     = var.public_subnets
  enable_nat_gateway = false
}

### ALB ###

module "alb" {
  source = "git::https://github.com/sergiohl1324/mod-aws-alb.git?ref=main"

  project            = var.project
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnets
  security_group_ids = [module.sg_alb.this_security_group_id]

  target_groups = {
    web = {
      port = 80
      health_check = {
        path     = "/"
        interval = 15
        timeout  = 10
      }
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type             = "forward"
        target_group_key = "web"
      }
    }
  }
}

### APPLICATION SERVER (nginx, toggle uWSGI) ###

module "app_server" {
  source = "git::https://github.com/sergiohl1324/mod-aws-app-server.git?ref=main"

  project     = var.project
  environment = var.environment

  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.public_subnets[0]
  alb_security_group_id = module.sg_alb.this_security_group_id
  target_group_arn      = module.alb.target_group_arns["web"]

  enable_uwsgi = var.enable_uwsgi
  html_title   = var.html_title
  html_message = var.html_message
}
