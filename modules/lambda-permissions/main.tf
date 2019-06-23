data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid = "AllowECS"

    actions = [
      "ecs:ListContainerInstances",
      "ecs:DescribeContainerInstances",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "AllowAutoscaling"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = [
      "*",
    ]
  }
  
  statement {
    sid = "Logging"
    
    actions = [
        "logs:CreateLogGroup",
        "logs:PutRetentionPolicy",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:GetLogEvents"
    ]
    
    resources = [
        "arn:aws:logs:*:*:log-group:/*",
        "arn:aws:logs:*:*:log-group:/*:log-stream:*"
    ]
  }
}

resource "aws_iam_policy" "lambda_role" {
  name   = "autoscaler-permissions"
  policy = "${data.aws_iam_policy_document.lambda_policy.json}"
}

resource "aws_iam_role" "lambda_role" {
  name = "autoscaler-permissions-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.lambda_role.arn}"
}
