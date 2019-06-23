data "archive_file" "lambda_zip_file" {
  type        = "zip"
  source_file = "${var.source_file_path}"
  output_path = "${var.output_path}"
}

resource "aws_lambda_function" "lambda" {
  filename      = "${data.archive_file.lambda_zip_file.output_path}"
  function_name = "${var.function_name}"

  #TODO: build role either within module or pass in arn
  role             = "${var.role_arn}"
  handler          = "${var.lambda_handler}"
  source_code_hash = "${data.archive_file.lambda_zip_file.output_base64sha256}"
  timeout          = "${var.timeout}"
  runtime          = "${var.runtime}"
  description      = "${var.description}"
  depends_on       = ["data.archive_file.lambda_zip_file"]
  tags             = "${var.tags}"

  environment {
    variables = "${var.environment_variables}"
  }
}

resource "aws_lambda_permission" "lambdaevents" {
  statement_id  = "AllowInvokeFromEvents"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.function_name}"
  principal     = "events.amazonaws.com"
}

resource "aws_cloudwatch_event_rule" "event" {
  description   = "${var.event_description}"
  event_pattern = "${var.event_pattern}"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = "${aws_cloudwatch_event_rule.event.name}"
  arn  = "${aws_lambda_function.lambda.arn}"
}
