provider "aws" {
  region = "${var.aws_region}"
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
