# Planejador Inteligente de Grade Horária da UnB

O planejador gera até cinco opções de grade com as disciplinas desejadas.
O motor em SWI-Prolog combina turmas com vagas e verifica choques de horário,
pré-requisitos, bloqueios e limites de créditos. A pontuação é
`7 × janelas + dias no campus`. Quanto menor, melhor.

O motor usa uma base demonstrativa de quatro disciplinas e oito turmas.
A API Python e a interface Elm estão previstas para as próximas etapas.

## Estrutura

| Caminho | Conteúdo | Responsáveis |
| --- | --- | --- |
| `prolog/regras.pl` | Restrições de montagem da grade com CLP(FD) | P1 |
| `prolog/ranking.pl` | Cálculo da pontuação e seleção das melhores grades | P2 |
| `prolog/turmas.pl` | Base demonstrativa de disciplinas, turmas e pré-requisitos | P3 |
| `backend/` | Pasta reservada para a API Python | P3 |
| `frontend/src/` | Pasta reservada para a interface Elm | P4, P5, P6 |
| `frontend/tests/` | Pasta reservada para elm-test | P7 |
| `tests/prolog/` | Testes PlUnit de regras e ranking | P7 |
| `docs/` | Pasta reservada para a apresentação | P7 |

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
