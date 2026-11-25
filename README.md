# Planejador Inteligente de Grade Horária da UnB

```
prolog/regras.pl     P1  restrições (choques, pré-requisitos, créditos)
prolog/ranking.pl    P2  ranking e Top 5
prolog/turmas.pl     P3  base de turmas
backend/             P3  API (uv + janus_swi)
frontend/src/        P4, P5, P6  Elm
frontend/tests/      P7  elm-test
tests/prolog/        P7  plunit
docs/                P7  apresentação
```

## Implementado até o momento

- **Regras Prolog:** geração de grades sem choques, respeitando pré-requisitos,
  créditos, vagas e horários bloqueados, com CLP(FD).
- **Ranking Prolog:** retorno de até cinco grades válidas, priorizando menos
  períodos livres entre aulas e depois menos dias no campus. A pontuação é
  `7 × janelas + dias`; quanto menor, melhor.
- **Base e testes:** base demonstrativa com 4 disciplinas e 8 turmas;
  47 testes Prolog aprovados (18 de regras e 29 de ranking).
- **Interface Elm:** seleção de disciplinas cursadas e desejadas, grade clicável
  para horários bloqueados e ciclo de requisição HTTP com estados de carregamento,
  erro e resultados. O catálogo atual acompanha a base demonstrativa Prolog.

A API Python ainda será implementada. Até ela estar disponível, a interface pode
ser compilada, mas o botão de geração não receberá uma resposta válida.

## Interface Elm

Requisito: Elm 0.19.1 e dependências definidas em `frontend/elm.json`.
Na pasta `frontend`, compile a aplicação com:

```sh
elm make src/Main.elm --output=main.js
```

O fluxo de entrada envia `cursadas`, `desejadas`, `bloqueados`, `peso_janelas`
e `peso_dias` para `POST /api/gerar-grades`. O backend deve responder com o
formato `{"grades": [...]}` definido no cronograma do projeto.

## Estrutura

| Caminho | Conteúdo | Responsáveis |
| --- | --- | --- |
| `prolog/regras.pl` | Restrições de montagem da grade com CLP(FD) | P1 |
| `prolog/ranking.pl` | Cálculo da pontuação e seleção das melhores grades | P2 |
| `prolog/turmas.pl` | Base demonstrativa de disciplinas, turmas e pré-requisitos | P3 |
| `backend/server.py` | API FastAPI que consulta o Prolog via janus | P3 |
| `frontend/src/` | Pasta reservada para a interface Elm | P4, P5, P6 |
| `frontend/tests/` | Pasta reservada para elm-test | P7 |
| `tests/prolog/` | Testes PlUnit de regras e ranking | P7 |
| `docs/` | Pasta reservada para a apresentação | P7 |

## API

Requisitos: SWI-Prolog 9.1.22 ou mais novo com `swipl` no PATH, e
[uv](https://docs.astral.sh/uv/). Na pasta `backend/`:

```sh
uv sync
uv run start
```

O servidor sobe em http://localhost:8000. A documentação interativa fica em
http://localhost:8000/docs. Se a pasta `frontend/build/` existir, o servidor
também entrega a interface Elm compilada em `/`.

| Rota | Entrada | Saída |
| --- | --- | --- |
| `POST /api/gerar-grades` | `{"cursadas": [...], "desejadas": [...], "bloqueados": [...], "peso_janelas": 3, "peso_dias": 2}` | `{"grades": [{"rank", "score", "janelas", "dias_campus", "turmas"}]}` |
| `GET /api/saude` | nada | `{"status": "ok"}` |

`peso_janelas` e `peso_dias` são aceitos, mas o motor usa sempre a pontuação
`7 × janelas + dias`. Sem grade compatível, a resposta é `{"grades": []}`.
Uma lista `desejadas` vazia devolve 400, e tipos errados devolvem 422.

## Testes PlUnit

Instale o SWI-Prolog, coloque `swipl` no PATH e execute o comando abaixo
na raiz do projeto. A suíte foi verificada com SWI-Prolog 9.2.9.

```sh
swipl -s tests/prolog/regras.plt -s tests/prolog/ranking.plt -g run_tests -t halt
```

São 51 casos, com 22 em regras e 29 em ranking. A suíte verifica a interpretação
de horários, a geração de grades, a pontuação e a integração entre regras e
ranking no Prolog.

<!-- ## Cenários para elm-test e ponta a ponta

Implemente os casos de elm-test quando os módulos Elm estiverem disponíveis,
usando os tipos e as funções que a interface adotar. Execute os cenários ponta
a ponta quando o navegador puder enviar uma solicitação à API ligada ao
SWI-Prolog.

| Suíte | Cenário | Resultado esperado |
| --- | --- | --- |
| elm-test | Preparar uma consulta com disciplinas cursadas, desejadas e horários bloqueados | Os valores selecionados chegam ao formato de entrada adotado pela interface. |
| elm-test | Interpretar a resposta da API | Os dados das turmas e as métricas ficam disponíveis na ordem recebida. Inclua casos com lista vazia e com erro. |
| Ponta a ponta | Com `FGA0158` cursada, pedir `FGA0210` e `FGA0244` | A tela exibe três grades com pontuações 4, 4 e 24, nessa ordem. |
| Ponta a ponta | Repetir a consulta com o bloqueio `2M3` | A tela exibe uma grade com as turmas B de `FGA0210` e `FGA0244`. |
| Ponta a ponta | Pedir `FGA0210` sem ter cursado `FGA0158` | A tela informa que não há grades compatíveis. |
-->

## Experimentar o motor Prolog

Na raiz do projeto, execute este comando no PowerShell para abrir o SWI-Prolog
com o módulo de ranking carregado.

```powershell
swipl -s prolog/ranking.pl
```

Se o SWI-Prolog já estiver aberto na raiz do projeto, carregue o módulo com
`use_module('prolog/ranking.pl').` no prompt `?-`.

No prompt `?-` do SWI-Prolog, digite a consulta abaixo, incluindo o ponto final.

```prolog
top_5_grades(['FGA0158'], ['FGA0210', 'FGA0244'], [], Top5).
```

Os argumentos são as disciplinas cursadas, as desejadas, os horários bloqueados
e a saída. Cada item de `Top5` tem o formato
`resultado(Pontuacao, Janelas, DiasCampus, Grade)`.
