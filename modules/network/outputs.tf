output "vpc_id" {
  value = "${aws_vpc.ecs_vpc.id}"
}

output "subnets" {
  value = ["${aws_subnet.ecs_subnet.*.id}"]
}
