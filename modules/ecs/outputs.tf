output "ecs_role" {
  value = "${aws_iam_instance_profile.ecs_node.name}"
}

output "security_group" {
  value = "${aws_security_group.ecs_basic.id}"
}
