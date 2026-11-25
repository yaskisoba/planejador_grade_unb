# syntax=docker/dockerfile:1

FROM node:24-bookworm-slim AS frontend
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY frontend/elm.json ./
COPY frontend/src/ ./src/
RUN npm run build

FROM python:3.14-slim-trixie AS backend-base
COPY --from=ghcr.io/astral-sh/uv:0.13.10 /uv /usr/local/bin/uv
RUN apt-get update \
    && apt-get install -y --no-install-recommends swi-prolog-nox ca-certificates \
    && rm -rf /var/lib/apt/lists/*
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_PYTHON_DOWNLOADS=never \
    UV_PROJECT_ENVIRONMENT=/opt/venv \
    PATH="/opt/venv/bin:$PATH"
WORKDIR /app/backend

FROM backend-base AS backend-dependencies
# No Linux, Janus precisa compilar a ponte contra o SWI-Prolog instalado.
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential pkg-config \
    && rm -rf /var/lib/apt/lists/*
COPY backend/pyproject.toml backend/uv.lock ./
RUN uv sync --locked --no-dev --no-install-project --no-cache

FROM backend-base AS application
COPY --from=backend-dependencies /opt/venv /opt/venv
COPY backend/ /app/backend/
COPY prolog/ /app/prolog/
COPY frontend/grade.css /app/frontend/grade.css
COPY --from=frontend /app/frontend/build/ /app/frontend/build/
RUN useradd --create-home --uid 10001 app
USER app
EXPOSE 8000
# Dentro do contêiner, o servidor precisa aceitar conexões pela interface de rede.
CMD ["python", "-m", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]

FROM application AS testes
USER root
RUN uv sync --locked --no-install-project --no-cache
COPY --from=frontend /usr/local/bin/node /usr/local/bin/node
COPY --from=frontend /app/frontend/ /app/frontend/
COPY --from=frontend /root/.elm/ /home/app/.elm/
COPY frontend/tests/ /app/frontend/tests/
COPY scripts/testar.sh /app/scripts/testar.sh
ENV PATH="/app/frontend/node_modules/.bin:$PATH"
RUN chown -R app:app /app /home/app/.elm
USER app
WORKDIR /app
CMD ["sh", "/app/scripts/testar.sh"]

# Um docker build sem --target também produz a aplicação.
FROM application AS app
