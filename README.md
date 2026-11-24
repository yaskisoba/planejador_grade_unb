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

## Como testar

Requisito: SWI-Prolog instalado, com `swipl` no PATH. Testado na versão 9.2.9.
Execute os comandos na raiz do projeto.

Testes Prolog Regras: `swipl -g run_tests -t halt tests/prolog/regras.plt`

Todos os testes (regras e ranking):

```sh
swipl -s tests/prolog/regras.plt -s tests/prolog/ranking.plt -g run_tests -t halt
```

Para experimentar o ranking, abra `swipl -s prolog/ranking.pl` e consulte:

```prolog
?- top_5_grades(['FGA0158'], ['FGA0210', 'FGA0244'], [], Top5).
```

Os argumentos são disciplinas cursadas, desejadas, horários bloqueados e saída.
Esse exemplo retorna três grades, com pontuações 4, 4 e 24, no formato
`resultado(Pontuacao, Janelas, DiasCampus, Grade)`.
