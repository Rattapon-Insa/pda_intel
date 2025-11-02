FROM python:3.11-slim

WORKDIR /app

# Install UV
RUN pip install uv

# Copy project files
COPY pyproject.toml uv.lock* ./
COPY src/ ./src
COPY tests/ ./tests

# Sync dependencies with UV
RUN uv sync --frozen --no-dev

# Expose port for Streamlit
EXPOSE 8501

# Run Streamlit app
CMD ["uv", "run", "streamlit", "run", "src/pda_intel/ui/app.py", "--server.port=8501", "--server.address=0.0.0.0"]
