variable "tags" {
  type = "map"
}

variable "cluster_name" {
  type    = "string"
  default = "ecs-experiment"
}

variable "role_name" {
  type    = "string"
  default = "ecsRole"
}

variable "ecs_policy_arn" {
  type    = "string"
  default = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

variable "vpc_id" {
  type = "string"
}
