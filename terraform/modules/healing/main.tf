resource "aws_iam_role" "lambda_role" {
  name = "cloud-ops-healing-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RebootInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan"
        ]
        Resource = "*"
        # Resource = "arn:aws:dynamodb:eu-central-1:*:table/cloud-ops-incidents"
      }
    ]
  })
}

resource "aws_lambda_function" "healer" {
  function_name = "cloud-ops-healer"

  filename         = "${path.module}/function.zip"
  source_code_hash = filebase64sha256("${path.module}/function.zip")

  role    = aws_iam_role.lambda_role.arn
  handler = "recover.lambda_handler"
  runtime = "python3.11"

  environment {
    variables = {
      INSTANCE_ID = var.instance_id
      TABLE       = "cloud-ops-incidents"
    }
  }
}

resource "aws_sns_topic_subscription" "lambda_sub" {
  topic_arn = var.topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.healer.arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.healer.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.topic_arn
}