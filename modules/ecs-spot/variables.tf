variable "subnets" {
  type = "list"
}

variable "region" {
  type    = "string"
  default = "eu-central-1"
}

variable "asg_name" {
  type    = "string"
  default = "ecs-spot"
}

variable "cluster_name" {
  type = "string"
}

variable "instance_size" {
  type    = "string"
  default = "t2.micro"
}

variable "spot_price" {
  type    = "string"
  default = "0.001"
}

variable "security_groups" {
  type = "list"
}

variable "asg_min" {
  type    = "string"
  default = "0"
}

variable "asg_max" {
  type    = "string"
  default = "10"
}

variable "asg_desired" {
  type    = "string"
  default = "0"
}

variable "instance_profile" {
  type = "string"
}

variable "tags" {
  type = "map"
}
