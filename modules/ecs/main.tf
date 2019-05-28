resource "aws_ecs_cluster" "default" {
  name = "${var.cluster_name}"
  tags = "${var.tags}"
}

resource "aws_iam_role" "ecs_node" {
  name = "${var.role_name}"
  tags = "${var.tags}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com", "spotfleet.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_node" {
  role       = "${aws_iam_role.ecs_node.name}"
  policy_arn = "${var.ecs_policy_arn}"
}

resource "aws_iam_role_policy_attachment" "ecs_node_spot" {
  role       = "${aws_iam_role.ecs_node.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetRole"
}

resource "aws_iam_role_policy_attachment" "ecs_node_ssm" {
  role       = "${aws_iam_role.ecs_node.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "ecs_node" {
  name = "${aws_iam_role.ecs_node.name}"
  role = "${aws_iam_role.ecs_node.name}"
}

resource "aws_security_group" "ecs_basic" {
  name        = "ecs_basic"
  description = "Allow HTTP traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["165.225.73.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.tags}"
}
