import boto3
import asyncio
import os
from fastapi import FastAPI, Request, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates

app = FastAPI()

# --- SOLUCIÓN DE RUTAS PARA DOCKER ---
# BASE_DIR será /code/app dentro del contenedor
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# Esto buscará en /code/app/templates
templates = Jinja2Templates(directory="templates")

# AWS Setup
SESSION = boto3.Session(profile_name='upp-practica', region_name='us-east-1')
SNS = SESSION.client('sns')
SQS = SESSION.client('sqs')

TOPIC_ARN = "arn:aws:sns:us-east-1:634531197719:tema-comunicaciones-upp"
QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/634531197719/cola-mensajes-alumnos"

@app.get("/", response_class=HTMLResponse)
async def login(request: Request):
    # Sintaxis compatible con FastAPI moderno
    return templates.TemplateResponse(request=request, name="login.html")

@app.post("/enviar")
async def enviar(request: Request, alumno: str = Form(...)):
    # Publicar en SNS
    SNS.publish(
        TopicArn=TOPIC_ARN, 
        Message=f"Registro de práctica para: {alumno}",
        MessageAttributes={'Alumno': {'DataType': 'String', 'StringValue': alumno}}
    )
    return RedirectResponse(url="/status?estado=enviado", status_code=303)

@app.get("/status", response_class=HTMLResponse)
async def status(request: Request, estado: str = "enviado"):
    return templates.TemplateResponse(
        request=request, 
        name="status.html", 
        context={"estado": estado}
    )

@app.get("/dashboard", response_class=HTMLResponse)
async def dashboard(request: Request):
    response = SQS.receive_message(
        QueueUrl=QUEUE_URL, 
        MaxNumberOfMessages=10, 
        WaitTimeSeconds=2
    )
    mensajes = response.get('Messages', [])
    return templates.TemplateResponse(
        request=request, 
        name="dashboard.html", 
        context={"mensajes": mensajes}
    )

@app.post("/procesar")
async def procesar(receipt_handle: str = Form(...)):
    await asyncio.sleep(5) 
    SQS.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=receipt_handle)
    return RedirectResponse(url="/dashboard", status_code=303)
