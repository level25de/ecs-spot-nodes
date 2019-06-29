variable "source_file_path" {}
variable "output_path" {}
variable "function_name" {}
variable "lambda_handler" {}
variable "event_description" {}
variable "event_pattern" {}
variable "description" {}
variable "role_arn" {}

variable "environment_variables" {
  type = "map"
}

variable "tags" {
  type = "map"
}

variable "runtime" {
  default = "go1.x"
}

variable "timeout" {
  default = 10
}
