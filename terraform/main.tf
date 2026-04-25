terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Usamos el perfil que configuraste en la terminal
provider "aws" {
  region  = "us-east-1"
  profile = "upp-practica"
}

# 1. El "Tema" de Mensajería (SNS)
resource "aws_sns_topic" "mensajeria_topic" {
  name = "tema-comunicaciones-upp"
}

# 2. La "Cola" de Mensajes (SQS)
resource "aws_sqs_queue" "mensajeria_queue" {
  name = "cola-mensajes-alumnos"
}

# 3. La suscripción: Conecta SNS con SQS
resource "aws_sns_topic_subscription" "sns_to_sqs" {
  topic_arn = aws_sns_topic.mensajeria_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.mensajeria_queue.arn
}

# 4. Política de Seguridad: Permite que el SNS escriba en la Cola
resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.mensajeria_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.mensajeria_queue.arn
        Condition = {
          ArnEquals = { "aws:SourceArn" = aws_sns_topic.mensajeria_topic.arn }
        }
      }
    ]
  })
}
