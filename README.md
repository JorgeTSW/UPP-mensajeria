# UPP - Proyecto Cómputo en la Nube: Mensajería Desacoplada

Este proyecto implementa un sistema de mensajería usando una arquitectura orientada a eventos con **AWS SNS** y **SQS**.

## 🛠️ Tecnologías
- **Infraestructura:** Terraform
- **Backend:** FastAPI (Python)
- **Containerización:** Docker & Docker Compose
- **Servicios Cloud:** AWS SNS (Simple Notification Service) y SQS (Simple Queue Service)

## 🚀 Cómo ejecutarlo

### 1. Infraestructura
```bash
cd terraform
terraform init
terraform apply
```

### 2. Aplicación
```bash
docker compose up --build
```
Accede a `http://localhost:8000` para ver el Login del alumno y el Dashboard.
