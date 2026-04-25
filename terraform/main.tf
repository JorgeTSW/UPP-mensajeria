# Configuración del Provider
provider "aws" {
  region  = "us-east-1"
  # profile = "upp-practica" # En GitHub Actions esto se ignora porque usa secretos
}

# 1. Crear VPC y Subnet (Red básica para la EC2)
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "vpc-upp-mensajeria" }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 2. Security Group (Abrir puertos 22, 80 y 8000)
resource "aws_security_group" "web_sg" {
  name   = "allow_web_traffic"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Tu App FastAPI
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Instancia EC2 (Free Tier)
resource "aws_instance" "app_server" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 24.04 LTS en us-east-1
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name      = "upp-proyecto-key" # <--- IMPORTANTE: Cámbiala por el nombre de tu .pem en AWS

  # Script de instalación automática de Docker al iniciar
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y docker.io docker-compose-v2
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ubuntu
              EOF

  tags = { Name = "Servidor-App-UPP" }
}

# 4. Mantén tus recursos de SNS y SQS que ya tenías
resource "aws_sns_topic" "user_updates" {
  name = "tema-comunicaciones-upp"
}

resource "aws_sqs_queue" "terraform_queue" {
  name = "cola-mensajes-alumnos"
}

output "instance_public_ip" {
  description = "IP pública de la instancia EC2"
  value       = aws_instance.app_server.public_ip
}
