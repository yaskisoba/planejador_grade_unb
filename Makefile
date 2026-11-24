# Atalhos do projeto. Uso: `make <alvo>`.
# Cada linha de receita roda num shell separado (por isso o `cd pasta && ...`).

ELM      ?= elm
ELM_TEST ?= elm-test

.PHONY: install build start dev test test-prolog test-elm validar

install:      ## instala as dependências Python (uv) e baixa os pacotes Elm
	cd backend && uv sync
	cd frontend && $(ELM) make src/Main.elm --output=/dev/null

build:        ## compila o Elm para frontend/build/index.html
	cd frontend && $(ELM) make src/Main.elm --optimize --output=build/index.html

start: build  ## compila o Elm e sobe a API em http://localhost:8000
	cd backend && uv run start

dev: start

test: test-prolog test-elm

test-prolog:  ## testes plunit (regras e ranking)
	swipl -s tests/prolog/regras.plt -s tests/prolog/ranking.plt -g run_tests -t halt

test-elm:     ## testes elm-test (horários, semana, codecs e grade)
	cd frontend && $(ELM_TEST)

validar:      ## confere a forma do RELATORIO.md
	uv run scripts/validar_entrega.py RELATORIO.md
