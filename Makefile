.DEFAULT_GOAL := help

HOST ?= 127.0.0.1
PORT ?= 8000
PROLOG_TESTS := $(sort $(wildcard prolog/tests/*.pl))

.PHONY: help check install build dev test test-prolog test-backend test-frontend

help:
	@echo "make install       Prepara as dependências e compila o frontend"
	@echo "make dev           Compila o frontend e inicia a aplicação"
	@echo "make dev PORT=8001 Usa outra porta"
	@echo "make build         Recompila o Elm após alterações"
	@echo "make test          Executa todos os testes (Prolog, Python e Elm)"
	@echo "make test-prolog   Executa os testes PlUnit"
	@echo "make test-backend  Executa os testes pytest da integração Python–Prolog"
	@echo "make test-frontend Executa os testes Elm"

check:
	@command -v uv >/dev/null || { echo "Instale o uv antes de continuar (veja o README)."; exit 1; }
	@command -v npm >/dev/null || { echo "Instale Node.js e npm antes de continuar."; exit 1; }
	@command -v swipl >/dev/null || { echo "Instale SWI-Prolog >= 9.1.12 antes de continuar."; exit 1; }
	@swipl -q -g 'current_prolog_flag(version, V), (V >= 90112 -> halt(0) ; writeln(user_error, "SWI-Prolog >= 9.1.12 é necessário para janus-swi."), halt(1))'

install: check
	cd backend && uv sync --locked
	cd frontend && npm ci --no-audit --no-fund
	$(MAKE) build

build:
	cd frontend && npm run build

dev: check build
	cd backend && uv run --locked uvicorn server:app --reload --host $(HOST) --port $(PORT)

test: test-prolog test-backend test-frontend

test-prolog:
	swipl $(foreach file,$(PROLOG_TESTS),-s $(file)) -g run_tests -t halt

test-backend:
	cd backend && uv run --locked pytest -q

test-frontend:
	cd frontend && npm test
