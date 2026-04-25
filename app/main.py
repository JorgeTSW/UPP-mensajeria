import boto3
import asyncio
from fastapi import FastAPI, Request, Form, BackgroundTasks
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates

app = FastAPI()
templates = Jinja2Templates(directory="templates")

# AWS Setup (Usando el perfil que mapearemos en Docker)
SESSION = boto3.Session(profile_name='upp-practica', region_name='us-east-1')
SNS = SESSION.client('sns')
SQS = SESSION.client('sqs')

TOPIC_ARN = "arn:aws:sns:us-east-1:634531197719:tema-comunicaciones-upp"
QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/634531197719/cola-mensajes-alumnos"

@app.get("/", response_class=HTMLResponse)
async def login(request: Request):
    return templates.TemplateResponse("login.html", {"request": request})

@app.post("/enviar")
async def enviar(alumno: str = Form(...)):
    # Paso 1: Enviado (SNS -> SQS)
    SNS.publish(TopicArn=TOPIC_ARN, Message=f"Alumno: {alumno}")
    return RedirectResponse(url="/status?estado=enviado", status_code=303)

@app.get("/dashboard", response_class=HTMLResponse)
async def dashboard(request: Request):
    response = SQS.receive_message(QueueUrl=QUEUE_URL, MaxNumberOfMessages=10, WaitTimeSeconds=2)
    mensajes = response.get('Messages', [])
    return templates.TemplateResponse("dashboard.html", {"request": request, "mensajes": mensajes})

@app.post("/procesar")
async def procesar(receipt_handle: str = Form(...)):
    # Simulación: El mensaje se queda "Procesando" (invisible en la cola) por 10s
    # En SQS, esto se logra no borrándolo inmediatamente.
    await asyncio.sleep(5) # Simula carga de trabajo
    SQS.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=receipt_handle)
    return RedirectResponse(url="/dashboard", status_code=303)
