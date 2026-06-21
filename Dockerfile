# Stage 1: Flutter Build
FROM debian:bookworm-slim AS flutter-builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    zip \
    xz-utils \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Download and install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter doctor to verify and pre-download binaries
RUN flutter doctor -v

# Set working directory and copy frontend files
WORKDIR /app
COPY frontend/ /app

# Enable web support and build the release app
RUN flutter config --enable-web
RUN flutter build web --release

# Stage 2: Runtime Environment
FROM python:3.10-slim

# Install system dependencies and nginx
RUN apt-get update && apt-get install -y \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Set up work directory
WORKDIR /app

# Copy python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy Django project code
COPY core /app/core
COPY chat /app/chat
COPY manage.py /app/

# Copy built frontend assets from builder stage
COPY --from=flutter-builder /app/build/web /usr/share/nginx/html

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/sites-available/default
# On Debian/Ubuntu, sites-enabled might contain a symlink. We ensure default is active.
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Copy startup script
COPY start.sh /app/
RUN chmod +x /app/start.sh

# Expose port 7860 (Hugging Face default)
EXPOSE 7860

# Run the startup script
CMD ["/app/start.sh"]
