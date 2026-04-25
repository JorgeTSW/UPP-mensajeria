FROM python:3.11-slim

WORKDIR /code

# Instalamos dependencias primero para aprovechar el cache
COPY ./app/requirements.txt /code/requirements.txt
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r /code/requirements.txt

# COPIAMOS TODO EL CONTENIDO DE LA CARPETA APP A LA RAÍZ DE /CODE
# Esto pondrá main.py en /code/ y templates/ en /code/templates/
COPY ./app /code/

# Ajustamos el comando para que apunte a main.py en la raíz
CMD ["python3", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
