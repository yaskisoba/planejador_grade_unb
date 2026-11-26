#!/bin/sh
set -eu

cd /app
printf '\nTestes Prolog (PlUnit)\n'
swipl -s prolog/tests/regras.pl -s prolog/tests/ranking.pl -s prolog/tests/oferta.pl -g run_tests -t halt

cd /app/backend
printf '\nTestes Python (pytest, Janus e Prolog reais)\n'
python -m pytest -q

cd /app/frontend
printf '\nTestes Elm\n'
elm-test
