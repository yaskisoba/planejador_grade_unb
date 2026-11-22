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

A API Python e a interface Elm ainda serão implementadas.

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
