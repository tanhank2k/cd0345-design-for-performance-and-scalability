# TODO: Designate a cloud provider, region, and credentials
provider "aws" {
  region     = "us-east-1"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${var.lambda_name}.py"
  output_path = var.lambda_output_path
}

resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "lambda_logging_policy"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 7
}

resource "aws_iam_role" "lambda_iam_role" {
  name = "lambda_iam_role"

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

resource "aws_iam_role_policy_attachment" "lambda_logging_policy" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_lambda_function" "lambda_greeting" {
  description      = "Greeting lambda function"
  role             = aws_iam_role.lambda_iam_role.arn
  filename         = "output.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = var.lambda_name
  handler          = "${var.lambda_name}.lambda_handler"
  runtime          = "python3.8"

  environment {
    variables = {
      greeting = "Say hi to world"
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_log_group, aws_iam_role_policy_attachment.lambda_logging_policy]
}
