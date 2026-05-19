resource "aws_s3_bucket" "frontend" {
  bucket = "itai-cloud-ops-dashboard"
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_iam_role" "api_role" {
  name = "cloud-ops-dashboard-api-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_logs" {
  role       = aws_iam_role.api_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "api_ddb" {
  name = "cloud-ops-dashboard-ddb"
  role = aws_iam_role.api_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:Scan"]
      Resource = "arn:aws:dynamodb:eu-central-1:*:table/cloud-ops-incidents"
    }]
  })
}

resource "aws_lambda_function" "api" {
  function_name = "cloud-ops-dashboard-api"
  role          = aws_iam_role.api_role.arn
  runtime       = "python3.11"
  handler       = "app.lambda_handler"
  filename = "${path.module}/dashboard-api/dashboard.zip"


  source_code_hash = filebase64sha256("${path.module}/dashboard-api/dashboard.zip")
}

resource "aws_lambda_function_url" "api_url" {
  function_name      = aws_lambda_function.api.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}

resource "aws_lambda_permission" "public_url" {
  statement_id           = "AllowPublicFunctionUrl"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.api.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicRead"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = [
          "${aws_s3_bucket.frontend.arn}/*"
        ]
      }
    ]
  })
}
