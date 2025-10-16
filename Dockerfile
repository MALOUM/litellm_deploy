FROM ghcr.io/berriai/litellm:main-latest

# Install additional dependencies if needed
RUN pip install --no-cache-dir boto3

# Set working directory
WORKDIR /app

# Copy configuration file
COPY config.yaml /app/config.yaml

# Expose LiteLLM proxy port
EXPOSE 4002

# Set environment variables for AWS region
ENV AWS_REGION=us-east-1
ENV AWS_DEFAULT_REGION=us-east-1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:4002/health || exit 1

# Run LiteLLM with config
CMD ["--config", "/app/config.yaml", "--port", "4002", "--num_workers", "4"]

