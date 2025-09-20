provider "aws" {
  region = "us-east-1"
}

########## backend ##############################################################################################################
terraform {
  backend "s3" {
    bucket         = "ia-motivational-automotivational-phrases"
    key            = "terraform/state/motivational/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "demoMotivationalphrases"
    encrypt        = true
  }
}

resource "aws_dynamodb_table" "terraform_backend_lock" {
  name         = "demoMotivationalphrases"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project = "Terraform Backend Lock"
    Owner   = "Kode-Soul"
  }
}
########## /backend ##############################################################################################################

# 🪣 S3 Bucket para frases, logs o backups
resource "aws_s3_bucket" "motivational_bucket" {
  bucket = "ia-motivational-automotivational-phrases"

  tags = {
    Project = "Kode-Soul  Motivational AI"
    Owner   = "Kode-Soul"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.motivational_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 🧾 DynamoDB Table para frases motivacionales
resource "aws_dynamodb_table" "motivational_quotes" {
  name         = "MotivationalQuotes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Project = "Kode-Soul  Motivational AI"
  }
}

# 🔐 IAM Role para Lambda con permisos mínimos

# 🛡️ Policy: acceso a DynamoDB y Bedrock
resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_motivational_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["bedrock:InvokeModel"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ],
        Resource = aws_dynamodb_table.motivational_quotes.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_motivational_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


resource "aws_lambda_function" "generate_motivation" {
  filename         = "lambda_generator.zip"
  function_name    = "generateMotivationalQuote"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_generator.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("lambda_generator.zip")
  timeout          = 12

  environment {
    variables = {
      DYNAMO_TABLE = aws_dynamodb_table.motivational_quotes.name
    }
  }
}


resource "aws_lambda_function" "read_motivation" {
  filename         = "lambda_reader.zip"
  function_name    = "readMotivationalQuote"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_reader.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("lambda_reader.zip")

  environment {
    variables = {
      DYNAMO_TABLE = aws_dynamodb_table.motivational_quotes.name
    }
  }
}

# eventbridge:
resource "aws_cloudwatch_event_rule" "daily_motivation_trigger" {
  name                = "daily-motivation-trigger"
  description         = "Dispara la Lambda que genera frases motivacionales todos los días"
  schedule_expression = "cron(0 8 * * ? *)"  # 8 AM UTC = 3 AM Colombia 🇨🇴

  tags = {
    Project = "Kode-Soul  Motivational AI"
  }
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_motivation_trigger.name
  target_id = "generateMotivationalQuote"
  arn       = aws_lambda_function.generate_motivation.arn
}

resource "aws_lambda_permission" "allow_eventbridge_invoke" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_motivation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_motivation_trigger.arn
}

resource "aws_api_gateway_rest_api" "motivation_api" {
  name        = "MotivationAPI"
  description = "API para obtener frases motivacionales"
}

resource "aws_api_gateway_resource" "motivation_resource" {
  rest_api_id = aws_api_gateway_rest_api.motivation_api.id
  parent_id   = aws_api_gateway_rest_api.motivation_api.root_resource_id
  path_part   = "motivation"
}

resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.motivation_api.id
  resource_id   = aws_api_gateway_resource.motivation_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.motivation_auth.id
}


resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.motivation_api.id
  resource_id             = aws_api_gateway_resource.motivation_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.read_motivation.invoke_arn
}

# rate and resources limit --> apigateway:
resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.motivation_api.id
  description = "Deployment for prod stage"
}

resource "aws_api_gateway_stage" "prod_stage" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.motivation_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}

resource "aws_api_gateway_method_settings" "prod_throttle" {
  rest_api_id = aws_api_gateway_rest_api.motivation_api.id
  stage_name  = aws_api_gateway_stage.prod_stage.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 100
  }
}

# grants over DynamoDB apigateway for invoke lambdas:
resource "aws_lambda_permission" "apigw_invoke_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.read_motivation.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.motivation_api.execution_arn}/*/*"
}


# lambda authorizer for API Gateway:
resource "aws_lambda_function" "auth_lambda" {
  filename         = "lambda_authorizer.zip"
  function_name    = "motivationAuthorizer"
  handler          = "lambda_authorizer.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_exec_role.arn
  source_code_hash = filebase64sha256("lambda_authorizer.zip")
  timeout          = 5
}

resource "aws_lambda_permission" "allow_apigw_auth" {
  statement_id  = "AllowAPIGatewayInvokeAuth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_api_gateway_authorizer" "motivation_auth" {
  name                   = "MotivationAuth"
  rest_api_id            = aws_api_gateway_rest_api.motivation_api.id
  authorizer_uri         = aws_lambda_function.auth_lambda.invoke_arn
  authorizer_result_ttl_in_seconds = 0
  type                   = "TOKEN"
  identity_source        = "method.request.header.Authorization"
}

