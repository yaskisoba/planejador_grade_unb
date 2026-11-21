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

Testes Prolog Regras: `swipl -g run_tests -t halt tests/prolog/regras.plt`
