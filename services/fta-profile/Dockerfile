# Use multi-stage builds for a slimmer and safer image
FROM python:3.12-slim-bookworm AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Stage 2: Run
FROM python:3.12-slim-bookworm AS runner

# Copy Python dependencies from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages

# Copy executables from builder
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application from builder
COPY --from=builder /app /app

# Set working directory
WORKDIR /app

# Use a non-root user to run the application, which is safer
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

# Expose port
EXPOSE 8000

# Run using Uvicorn
# CMD ["sh", "-c", "uvicorn main:app --host ${APP_HOST} --port ${APP_PORT} --log-level ${APP_LOG_LEVEL}"]

# Run using Gunicorn
CMD ["sh", "-c", "gunicorn main:app -k uvicorn.workers.UvicornWorker -b ${APP_HOST}:${APP_PORT} -w ${APP_WORKERS} --log-level ${APP_LOG_LEVEL}"]

# ENTRYPOINT ["gunicorn", "-k", "uvicorn.workers.UvicornWorker"]
# CMD ["-b", "0.0.0.0:8000", "-w", "4", "main:app", "--log-level", "info"]