data "aws_ami" "ecs" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["591542846629"] # amazon
}

data "template_file" "userdata" {
  template = <<SUPER
#!/bin/bash -xe
export PATH=/usr/local/bin:$PATH
yum -y --security update
yum -y install jq
easy_install pip
pip install awscli
aws configure set default.region ${var.region}
echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
echo ECS_ENABLE_TASK_IAM_ROLE=true >> /etc/ecs/ecs.config
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable --now amazon-ssm-agent

cat <<EOF > /usr/local/bin/spot-instance-termination-notice-handler.sh
#!/bin/bash
while sleep 5; do
if [ -z \$(curl -Isf http://169.254.169.254/latest/meta-data/spot/termination-time)];then
/bin/false
else
logger "[spot-instance-termination-notice-handler.sh]: spot instance terminationnotice detected"
STATUS=DRAINING
ECS_CLUSTER=\$(curl -s http://localhost:51678/v1/metadata | jq .Cluster | tr -d \")
CONTAINER_INSTANCE=\$(curl -s http://localhost:51678/v1/metadata | jq .ContainerInstanceArn| tr -d \")
logger "[spot-instance-termination-notice-handler.sh]: putting instance in state\$STATUS"
logger "[spot-instance-termination-notice-handler.sh]: running: /bin/aws ecs update-container-instances-state --cluster \$ECS_CLUSTER --container-instances \$CONTAINER_INSTANCE --status \$STATUS"
/bin/aws ecs update-container-instances-state --cluster \$ECS_CLUSTER --container-instance \$CONTAINER_INSTANCE --status \$STATUS
logger "[spot-instance-termination-notice-handler.sh]: putting myself to sleep..."
sleep 120
fi
done
EOF

chmod +x /usr/local/bin/spot-instance-termination-notice-handler.sh

cat <<EOF > /etc/systemd/system/spot-instance-termination-notice-handler.service
[Unit]
Description=instance termination notice handler systemd service.

[Service]
Type=simple
ExecStart=/bin/bash /usr/local/bin/spot-instance-termination-notice-handler.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now spot-instance-termination-notice-handler
  SUPER
}

resource "aws_launch_template" "launchconfig" {
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 80
    }
  }

  disable_api_termination = false

  ebs_optimized = true

  iam_instance_profile {
    name = "${var.instance_profile}"
  }

  image_id = "${data.aws_ami.ecs.id}"

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "${var.instance_size}"

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = ["${var.security_groups}"]
    delete_on_termination       = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "test"
    }
  }

  user_data = "${base64encode(data.template_file.userdata.rendered)}"
}

resource "aws_autoscaling_group" "asg" {
  name             = "${var.asg_name}"
  max_size         = "${var.asg_max}"
  min_size         = "0"
  desired_capacity = "0"

  launch_template {
    id      = "${aws_launch_template.launchconfig.id}"
    version = "$$Latest"
  }

  vpc_zone_identifier = ["${var.subnets}"]

  tags = ["${var.tags}"]
}

resource "aws_autoscaling_group" "asg_spot" {
  name             = "${var.asg_name}-spot"
  max_size         = "${var.asg_max}"
  min_size         = "${var.asg_min}"
  desired_capacity = "${var.asg_desired}"

  mixed_instances_policy {
    instances_distribution {
      on_demand_percentage_above_base_capacity = 0
    }

    launch_template {
      launch_template_specification {
        launch_template_id = "${aws_launch_template.launchconfig.id}"
        version            = "$$Latest"
      }

      override {
        instance_type = "m4.large"
      }

      override {
        instance_type = "m5.large"
      }
    }
  }

  vpc_zone_identifier = ["${var.subnets}"]

  tags = ["${var.tags}"]
}
