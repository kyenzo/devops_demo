FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8086

CMD ["gunicorn", "--bind", "0.0.0.0:8086", "--workers", "2", "--access-logfile", "-", "--error-logfile", "-", "app:app"]
