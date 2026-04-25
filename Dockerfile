# Dockerfile
FROM python:3.11-slim

WORKDIR /code

# Instalamos dependencias
COPY ./requirements.txt /code/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# Copiamos el código
COPY ./app /code/app
COPY ./templates /code/templates

# Comando para iniciar FastAPI
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]
