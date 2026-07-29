FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=7860

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Collect static files for Whitenoise
RUN python manage.py collectstatic --noinput

# Hugging Face Spaces default port
EXPOSE 7860

# Start Daphne ASGI Server
CMD ["daphne", "-b", "0.0.0.0", "-p", "7860", "core.asgi:application"]
