provider "aws" {
  region     = "${var.aws_region}"
}

module "network" {
  source = "./modules/network"

  tags = {
    Name = "demo-default"
  }
}

module "ecs" {
  source       = "./modules/ecs"
  vpc_id       = "${module.network.vpc_id}"
  cluster_name = "ecsdemo"

  tags = {
    Name = "demo-default"
  }
}

module "ecs_spot" {
  source           = "./modules/ecs-spot"
  subnets          = "${module.network.subnets}"
  security_groups  = ["${module.ecs.security_group}"]
  instance_profile = "${module.ecs.ecs_role}"
  cluster_name     = "ecsdemo"
  instance_size    = "m5.large"
  asg_desired      = "2"

  tags = [{
    key                 = "Name"
    value               = "demo-default"
    propagate_at_launch = true
  }]
}

module "lambda-permissions" {
  source = "./modules/lambda-permissions"
}

module "lambda-ecs" {
  source           = "./modules/lambda"
  source_file_path = "./lambda-handler/bin/ecs-linux"
  output_path      = "./ecs.zip"
  description      = "ECS state function"
  function_name    = "ecs"
  lambda_handler   = "ecs-linux"
  role_arn         = "${module.lambda-permissions.role_arn}"

  environment_variables = {
    "ASG_SPOT"     = "${module.ecs_spot.asg_spot_name}"
    "ASG_ONDEMAND" = "${module.ecs_spot.asg_name}"
  }

  tags = {
    "key" = "val"
  }

  event_description = "Cloudwatch event for ECS cluster instance change"

  event_pattern = <<PATTERN
{
  "detail-type": [
    "ECS Container Instance State Change"
  ],
  "detail": {
    "status": ["DRAINING"]
  }
}
PATTERN
}

module "lambda-scale" {
  source           = "./modules/lambda"
  source_file_path = "./lambda-handler/bin/scale-linux"
  output_path      = "./scale.zip"
  description      = ""
  function_name    = "scale"
  lambda_handler   = "scale-linux"
  description      = "scale function"
  role_arn         = "${module.lambda-permissions.role_arn}"

  environment_variables = {
    "ASG_SPOT"     = "${module.ecs_spot.asg_spot_name}"
    "ASG_ONDEMAND" = "${module.ecs_spot.asg_name}"
  }

  tags = {
    "key" = "val"
  }

  event_description = "Cloudwatch event for on demand ASG"

  event_pattern = <<PATTERN
{
  "detail-type": [
    "EC2 Instance Launch Successful",
    "EC2 Instance Terminate Successful"
  ]
}
PATTERN
}
