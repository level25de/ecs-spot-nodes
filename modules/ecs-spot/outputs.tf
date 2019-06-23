output "asg_name" {
  value = "${aws_autoscaling_group.asg.name}"
}

output "asg_spot_name" {
  value = "${aws_autoscaling_group.asg_spot.name}"
}
