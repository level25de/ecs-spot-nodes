variable "netmask" {
  type    = "string"
  default = "10.0.0.0/16"
}

variable "subnet_count" {
  type    = "string"
  default = "3"
}

variable "tags" {
  type = "map"
}
