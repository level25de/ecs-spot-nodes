resource "aws_vpc" "ecs_vpc" {
  cidr_block                       = "${var.netmask}"
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = "${var.tags}"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.ecs_vpc.id}"

  tags = "${var.tags}"
}

resource "aws_default_route_table" "r" {
  default_route_table_id = "${aws_vpc.ecs_vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = "${aws_internet_gateway.gw.id}"
  }

  tags = "${var.tags}"
}

resource "aws_subnet" "ecs_subnet" {
  count           = "${var.subnet_count}"
  vpc_id          = "${aws_vpc.ecs_vpc.id}"
  cidr_block      = "${cidrsubnet(aws_vpc.ecs_vpc.cidr_block,ceil(log(var.subnet_count * 2, 2)),count.index)}"
  ipv6_cidr_block = "${cidrsubnet(aws_vpc.ecs_vpc.ipv6_cidr_block, 8, count.index)}"
  tags            = "${var.tags}"
}
