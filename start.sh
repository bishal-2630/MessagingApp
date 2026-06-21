#!/bin/bash

# Create media and staticfiles directory if they don't exist
mkdir -p /app/media
mkdir -p /app/staticfiles

# Run migrations
python manage.py migrate --noinput

# Collect Django static files (admin, drf)
python manage.py collectstatic --noinput

# Start Gunicorn in the background
gunicorn core.wsgi:application --bind 127.0.0.1:8000 --workers 3 &

# Start Nginx in the foreground
nginx -g "daemon off;"
