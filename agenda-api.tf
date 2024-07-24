// API Gateway - "AgendaAPI"
resource "aws_api_gateway_rest_api" "agenda_api" {
  name        = "AgendaAPI"
  description = "API para gerenciar a agenda"
}

// Recursos para Lambda 1 - Agenda ----------------------------------------------------------------------------------
// API Gateway Resource - "agenda"
resource "aws_api_gateway_resource" "agenda_resource" {
  rest_api_id = aws_api_gateway_rest_api.agenda_api.id
  parent_id   = aws_api_gateway_rest_api.agenda_api.root_resource_id
  path_part   = "agenda"
}

// Define um método HTTP "POST" para o recurso /agenda
resource "aws_api_gateway_method" "agenda_method" {
  rest_api_id   = aws_api_gateway_rest_api.agenda_api.id
  resource_id   = aws_api_gateway_resource.agenda_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

// Configura a integração do méotodo "POST" do API Gateway com a função Lambda
// A integração é do tipo "AWS_PROXY"
resource "aws_api_gateway_integration" "agenda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.agenda_api.id
  resource_id             = aws_api_gateway_resource.agenda_resource.id
  http_method             = aws_api_gateway_method.agenda_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.agenda_lambda.invoke_arn
}

// Lambda 1 - Agenda --------------------------------------------------------------------------------------------------
// Define a função Lambda chamada "AgendaFunction"
resource "aws_lambda_function" "agenda_lambda" {
  function_name = "AgendaFunction"
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"

  image_uri = "----.dkr.ecr.your-region.amazonaws.com/agenda-api:latest"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.agenda_table.name
    }
  }
}

// Recursos para Lambda 2 - Geolocalização ----------------------------------------------------------------------
# Recurso e método para a segunda função Lambda (Geolocalização)
resource "aws_api_gateway_resource" "geo_location_resource" {
  rest_api_id = aws_api_gateway_rest_api.agenda_api.id
  parent_id   = aws_api_gateway_rest_api.agenda_api.root_resource_id
  path_part   = "geo-location"
}

resource "aws_api_gateway_method" "geo_location_method" {
  rest_api_id   = aws_api_gateway_rest_api.agenda_api.id
  resource_id   = aws_api_gateway_resource.geo_location_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "geo_location_integration" {
  rest_api_id             = aws_api_gateway_rest_api.agenda_api.id
  resource_id             = aws_api_gateway_resource.geo_location_resource.id
  http_method             = aws_api_gateway_method.geo_location_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.geo_location_lambda.invoke_arn
}

// Lambda 2 - Geolocalização ----------------------------------------------------------------------------------
// Segunda função Lambda (Geolocalização)
resource "aws_lambda_function" "geo_location_lambda" {
  function_name = "GeolocationFunction"
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"

  image_uri = "----.dkr.ecr.your-region.amazonaws.com/agenda-api:latest"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.agenda_table.name
    }
  }
}

// Outros recursos ----------------------------------------------------------------------------------------------
// IAM Role e Policy Attachment (Compartilhada)
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

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

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// DynamoDB Table - Cria uma tabela DynamoDB chamada "Agenda"
resource "aws_dynamodb_table" "agenda_table" {
  name           = "Agenda"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ID"

  attribute {
    name = "ID"
    type = "S"
  }
}

// Cria um tópico SNS chamado "AgendaNotifications" - usado para publicar notificações relacionadas à agenda
resource "aws_sns_topic" "agenda_sns" {
  name = "AgendaNotifications"
}

// Cria uma fila SQS chama "AgendaQueue" que vai ser usada para processar mensagens relacionadas à agenda
resource "aws_sqs_queue" "agenda_queue" {
  name = "AgendaQueue"
}

// Configura uma identidade de e-mail no Simple Email Service
resource "aws_ses_email_identity" "agenda_email" {
  email = "healthmed@dominio.com"
}
