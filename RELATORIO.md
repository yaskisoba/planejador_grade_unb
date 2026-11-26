# Planejador de Grade Horária da UnB

Relatório do grupo GradeHoráriaGX para o trabalho final de Paradigmas de Programação.

## 1. Identificação

| Nome completo | Matrícula | Turma (14h/16h) | Usuário GitHub |
|---------------|-----------|-----------------|----------------|
| Gabriel Felipe Mesquita Esteves | 190106956 | 16h | @GabrielMEsteves |
| Filipe Carvalho da Silva | 211030747 | 16h | @Filipe-002 |
| Joao Victor Marques Reis de Miranda | 200058576 | 16h | @jmarquees |
| Yasmim Oliveira Rosa | 200029088 | 16h | @yaskisoba |
| Fabio Gabriel da Silva Barbosa | 222006712 | 16h | @fabinsz |
| Cibelly Lourenço Ferreira | 231026680 | 16h | @cibelinda |

- **Nome do projeto:** Planejador de Grade Horária da UnB
- **Nome do grupo:** GradeHoráriaGX
- **Repositório:** https://github.com/yaskisoba/planejador_grade_unb
- **Commit ou tag entregue:** [Commit ou tag final]
- **Ponto de partida:** jogo inventado
- **Slides da apresentação oral:** (https://canva.link/oa6g6is5446x5zd)

O sistema é um planejador acadêmico. Como as faixas do modelo se referem a
jogos, o enquadramento e a aprovação do tema precisam ser confirmados com o
professor. O commit ou tag de entrega deve identificar a versão final do código
e deste relatório, após a revisão do grupo.

## 2. Resumo

O sistema auxilia estudantes de Engenharia de Software da UnB a montar a grade semestral.
O aluno informa disciplinas cursadas, disciplinas desejadas e horários indisponíveis.
O Prolog gera combinações de turmas que respeitam pré-requisitos, vagas, créditos e ausência de choques.
As opções são classificadas por janelas entre aulas e dias no campus; o Elm mostra até cinco sugestões.
Os dados incluem 102 disciplinas do catálogo e 162 turmas de 66 disciplinas da oferta de 2026/2.

![Interface com seleção de disciplinas, horários bloqueáveis e três sugestões reais para FGA0210](docs/captura.png)

Captura feita em 25/11/2026, com `FGA0158` e `FGA0003` cursadas, `FGA0210`
desejada e nenhum bloqueio. A primeira opção corresponde à turma `01`.

## 3. Como executar

Há duas formas de executar: ambiente local com Make ou contêineres com Docker Compose.
Em ambas, o backend entrega a API e o frontend compilado no mesmo endereço.

### 3.1 Ambiente local com Make

**Requisitos e versões verificadas:**

- SWI-Prolog 11.0.1; o Janus exige pelo menos 9.1.12 e `swipl` no PATH.
- Node.js 22.17.0 e npm 10.9.2.
- uv 0.12.13 e Python 3.13.11; o projeto exige Python >= 3.12.
- GNU Make 4.3.
- Elm 0.19.2 e elm-test 0.19.2-0, instalados por `npm ci` com as versões de `frontend/package-lock.json`.

Na raiz do repositório:

```sh
make install    # instala dependências do projeto e compila o Elm
make dev        # inicia a API e disponibiliza a interface
```

Abra http://127.0.0.1:8000. O Swagger fica em http://127.0.0.1:8000/docs.
Encerre com `Ctrl + C`. Se a porta estiver ocupada:

```sh
make dev PORT=8001
```

Nesse caso, abra http://127.0.0.1:8001. `make install` não instala as ferramentas
do sistema; SWI-Prolog, Node.js, uv e Make devem estar disponíveis antes.
A instalação inicial exige internet. Repita-a quando as dependências mudarem.

Para atualizar a aplicação durante o desenvolvimento:

- Elm: executar `make build` em outro terminal e atualizar o navegador com `Ctrl + Shift + R`.
- CSS: salvar e atualizar o navegador.
- Python: `make dev` reinicia a API automaticamente.
- Prolog e dados JSON: encerrar e iniciar `make dev` novamente.

Os testes não exigem o servidor aberto:

```sh
make test           # todas as suítes
make test-prolog    # PlUnit
make test-backend   # pytest
make test-frontend  # elm-test
```

### 3.2 Contêineres com Docker Compose

**Requisitos:** Docker Engine com o plugin Compose, ou Docker Desktop usando
contêineres Linux. O Compose disponível na máquina desta revisão é o v2.39.1.
Não é necessário instalar Python, SWI-Prolog, Node.js, Elm ou Make no host
para essa opção. A primeira construção precisa de internet para baixar
imagens e dependências.

Na raiz do repositório:

```sh
docker compose up --build -d --wait
```

Acesse http://127.0.0.1:8000 ou http://127.0.0.1:8000/docs. O serviço `app`
publica a porta apenas em `127.0.0.1`; `--wait` espera a verificação de saúde
da API antes de concluir. Para acompanhar os logs e, depois, encerrar:

```sh
docker compose logs -f app
# Ctrl + C encerra apenas o acompanhamento dos logs
docker compose down
```

Se a porta 8000 estiver ocupada, no Linux/macOS:

```sh
PORTA=8001 docker compose up --build -d --wait
```

No PowerShell:

```powershell
$env:PORTA = "8001"
docker compose up --build -d --wait
```

Abra http://127.0.0.1:8001. O nome da variável no Compose é `PORTA`; no Make,
o parâmetro é `PORT`. O contêiner continua usando a porta interna 8000.
Após editar o código, reconstrua com `docker compose up --build -d --wait`;
essa configuração não há sincronização automática dos arquivos do host.

Execute todas as suítes no contêiner com:

```sh
docker compose run --build --rm testes
```

O serviço `testes` executa PlUnit, pytest e elm-test em sequência e retorna erro
se uma suíte falhar. Ele não exige que o serviço `app` esteja em execução.
Seu perfil evita que seja iniciado junto da aplicação no comando normal.

O `Dockerfile` separa a compilação Elm, as dependências Python/Janus, a imagem
da aplicação e a imagem de testes. A aplicação executa como usuário sem
privilégios. Os arquivos `backend/uv.lock` e `frontend/package-lock.json`
fixam as dependências utilizadas no build.

**Validação da execução:** o fluxo local foi testado no Ubuntu 22.04.5 LTS,
com compilação, 144 testes e geração de grades no navegador integrado do
Codex. A configuração Compose foi conferida nesta revisão; o build e a
execução dos contêineres não foram repetidos. A reprodução em máquina limpa
e em outros sistemas operacionais ainda não foi verificada.

## 4. Arquitetura

```text
Navegador / Elm  <-- HTTP + JSON -->  FastAPI / Python  <-- Janus -->  SWI-Prolog
                                          |
                              catálogo e oferta em JSON
```

| Parte | Responsabilidade | Arquivos principais |
|-------|------------------|---------------------|
| Prolog | Gerar grades válidas, aplicar restrições e selecionar o Top 5 | `prolog/regras.pl`, `prolog/ranking.pl`, `prolog/turmas.pl` |
| Elm | Gerenciar seleções e estado da tela, interpretar horários, enviar pedidos e apresentar resultados | `frontend/src/Main.elm`, `frontend/src/Types.elm`, `frontend/src/Codec.elm`, `frontend/src/Horario.elm`, `frontend/src/Semana.elm`, `frontend/src/GradeView.elm` |
| Python | Expor rotas, validar o formato dos pedidos, preparar a oferta e converter dados entre JSON e Prolog | `backend/server.py` |
| Empacotamento | Compilar e executar a aplicação e as suítes em contêineres separados | `Dockerfile`, `compose.yaml`, `scripts/testar.sh` |
| Dados | Preservar o catálogo curricular e a oferta usada na geração | `backend/catalogo_unb.json`, `backend/oferta_sigaa_2026_2.json` |

Na inicialização, o backend carrega os JSONs, converte carga horária em créditos
e calcula vagas disponíveis. O Prolog substitui sua base demonstrativa pela
oferta importada, dentro de uma transação. A geração e o ranking continuam no
Prolog. A interface usa URLs relativas à mesma API que serve a página.

## 5. Parte em Prolog

### 5.1 Predicados principais

Nas assinaturas, `+` indica entrada, `-` saída e `?` um argumento que pode estar
parcialmente instanciado.

| Predicado | Local | O que faz |
|-----------|-------|-----------|
| `horario_slots/2`: `horario_slots(+Horario, -Slots)` | `prolog/regras.pl:31` | Interpreta códigos como `24M34` e produz períodos inteiros ordenados, sem repetição |
| `choque/2`: `choque(+HorariosA, +HorariosB)` | `prolog/regras.pl:56` | Tem sucesso quando duas listas de horários compartilham algum período |
| `apto/2`: `apto(+Cursadas, +Codigo)` | `prolog/regras.pl:64` | Exige ao menos uma alternativa de cada grupo de pré-requisitos e rejeita disciplina já cursada |
| `grade/6`: `grade(+Cursadas, +Desejadas, +Bloqueados, +Min, +Max, -Grade)` | `prolog/regras.pl:87` | Gera uma turma por disciplina, respeitando todas as restrições; `grade/4` usa 2 a 32 créditos |
| `turma_disponivel/4`: `turma_disponivel(+Bloqueados, +Codigo, -Turma, -Slots)` | `prolog/regras.pl:105` | Filtra vagas positivas e períodos não bloqueados |
| `compativeis/4`: `compativeis(+OpcoesA, ?EscolhaA, +OpcoesB, ?EscolhaB)` | `prolog/regras.pl:121` | Restringe dois índices de escolha aos pares de turmas sem choque |
| `metricas_grade/3`: `metricas_grade(+Grade, -Janelas, -DiasCampus)` | `prolog/ranking.pl:22` | Conta períodos livres entre aulas do mesmo dia e dias com aula |
| `top_5_grades/4`: `top_5_grades(+Cursadas, +Desejadas, +Bloqueados, -Top5)` | `prolog/ranking.pl:61` | Ordena todas as soluções e retorna até cinco, com pesos padrão 7 e 1 |
| `top_5_grades_pesos/6`: `top_5_grades_pesos(+Cursadas, +Desejadas, +Bloqueados, +PesoJanelas, +PesoDias, -Top5)` | `prolog/ranking.pl:73` | Ordena as grades com os pesos informados pela API |
| `carregar_oferta/3`: `carregar_oferta(+Disciplinas, +Turmas, +Requisitos)` | `prolog/turmas.pl:27` | Substitui os fatos da oferta com transação, preservando a base anterior se a carga falhar |

### 5.2 Conceitos do paradigma lógico utilizados

- [x] **Fatos e regras:** disciplinas, turmas e pré-requisitos em `prolog/turmas.pl:6`; restrições em `prolog/regras.pl:87`.
- [x] **Unificação:** a cabeça de `turma_disponivel/4` decompõe o termo `turma/5` em `prolog/regras.pl:105`.
- [x] **Recursão sobre listas:** `sem_choques/2` compara cada disciplina com as seguintes em `prolog/regras.pl:116`.
- [x] **Backtracking:** `label/1` enumera escolhas que satisfazem os domínios e as restrições em `prolog/regras.pl:98`.
- [x] **Coleta de soluções:** `findall/3` reúne opções em `prolog/regras.pl:102` e grades em `prolog/ranking.pl:79`; o projeto não usa `bagof/3` nem `setof/3`.
- [x] **Corte e negação:** o corte em `digitos//1` consome a sequência de dígitos (`prolog/regras.pl:46`); `\+ memberchk/2` rejeita disciplina cursada (`prolog/regras.pl:67`), com a lista já instanciada.
- [x] **CLP(FD):** soma e limites de créditos, domínio dos índices de turmas e tabela de pares permitidos com `tuples_in/2` em `prolog/regras.pl:75`, `prolog/regras.pl:111` e `prolog/regras.pl:121`.
- [x] **Ordem superior:** `maplist/3`, `include/3` e aplicação parcial em `prolog/regras.pl:71`; `call/2` permite reutilizar o ranking com diferentes geradores em `prolog/ranking.pl:79`.
- [x] **DCG e transações:** gramática para horários em `prolog/regras.pl:41` e atualização atômica da oferta em `prolog/turmas.pl:27`.

### 5.3 Trecho em destaque

Trecho de `prolog/regras.pl:121`:

```prolog
compativeis(OpcoesA, EscolhaA, OpcoesB, EscolhaB) :-
    findall([IA, IB],
            ( nth1(IA, OpcoesA, _-SlotsA),
              nth1(IB, OpcoesB, _-SlotsB),
              ord_disjoint(SlotsA, SlotsB) ),
            Permitidos),
    tuples_in([[EscolhaA, EscolhaB]], Permitidos).
```

Cada variável de escolha representa o índice de uma turma. `findall/3` monta
uma relação com os pares de índices cujos períodos não se sobrepõem.
`tuples_in/2` declara que as escolhas precisam pertencer a essa relação.
`sem_choques/2` aplica essa restrição entre todas as disciplinas; só depois
`grade/6` chama `label/1` para enumerar soluções.

A propagação de restrições elimina valores incompatíveis antes da enumeração
completa. A lógica de compatibilidade é expressa como relação, sem manter um
estado mutável de tentativas. Por exemplo, `24M34` e `4M45` têm o período `4M4`
em comum; o par dessas turmas não entra em `Permitidos`.

## 6. Parte em Elm

### 6.1 Modelo e mensagens

Tipos de `frontend/src/Main.elm:20`:

```elm
type alias Model =
    { requisicao : Request
    , estado : Estado
    , opcaoSelecionada : Int
    , catalogo : EstadoCatalogo
    , buscaCursadas : String
    , buscaDesejadas : String
    , pesoJanelasTexto : String
    , pesoDiasTexto : String
    }

type Estado
    = Pronto
    | Carregando
    | Falhou String
    | Carregado (List Grade)

type EstadoCatalogo
    = CarregandoCatalogo
    | FalhouCatalogo String
    | CatalogoCarregado Catalogo

type Msg
    = GerarGrades
    | AlternarCursada String
    | AlternarDesejada String
    | AlternarBloqueio String
    | SelecionouOpcao Int
    | BuscouCursadas String
    | BuscouDesejadas String
    | AlterouPesoJanelas String
    | AlterouPesoDias String
    | CarregarCatalogo
    | RecebeuCatalogo (Result Http.Error Catalogo)
    | RecebeuResposta (Result Http.Error (List Grade))
```

Os custom types tornam os estados de cada requisição mutuamente exclusivos:
`estado` não pode ser `Carregando` e `Falhou` simultaneamente. O erro carrega
sua mensagem; o sucesso carrega as grades. Catálogo e geração têm ciclos
independentes. Os pesos mantêm o texto digitado separado do inteiro válido;
`pesosValidos` desabilita a geração se houver texto vazio, negativo ou não inteiro.
`Result` obriga o `update` a tratar sucesso e falha HTTP.

O domínio também usa `Dia`, `Turno` e os tipos opacos `Periodo` e `Horario`
em `frontend/src/Horario.elm:26`. A leitura de um horário devolve `Maybe Horario`,
com `Nothing` para código inválido (`frontend/src/Horario.elm:243`). A célula
semanal distingue `Livre`, `Janela`, `Aula` e `Choque` em
`frontend/src/Semana.elm:32`.

Essa proteção não cobre todos os valores: códigos de disciplinas na requisição
ainda são strings e o índice selecionado é um inteiro. A exclusão entre listas
de cursadas e desejadas é mantida por `alterarSelecao`, não pelo tipo `Request`.

### 6.2 Conceitos do paradigma funcional utilizados

- [x] **Arquitetura Elm:** `Browser.element` liga `init`, `update` e `view` em `frontend/src/Main.elm:60`.
- [x] **Custom types e `case` exaustivo:** `Estado` e `Msg` em `frontend/src/Main.elm:32`; `Conteudo` em `frontend/src/Semana.elm:32`.
- [x] **Maybe e Result:** `Horario.deTexto` em `frontend/src/Horario.elm:243` e mensagens HTTP em `frontend/src/Main.elm:45`.
- [x] **Ordem superior e aplicação parcial:** `List.filter ((/=) codigo)` em `frontend/src/Main.elm:165`; `lerTodos (lerPeriodo valor)` em `frontend/src/Horario.elm:243`.
- [x] **Composição:** pipelines com `|>` em `frontend/src/Semana.elm:43` e `>>` no encoder de `frontend/src/Codec.elm:31`.
- [x] **JSON tipado:** `Types.encodeRequest` e `Types.decodeCatalogo` em `frontend/src/Types.elm`; `Codec.respostaDecoder` em `frontend/src/Codec.elm:70`.
- [x] **Efeitos controlados:** HTTP retorna `Cmd Msg` em `frontend/src/Main.elm:221`. A aplicação declara `subscriptions = always Sub.none`; não há assinaturas de eventos externos ativas.
- [x] **Imutabilidade:** `update` produz novos records e comandos em `frontend/src/Main.elm:95`.
- [x] **Encapsulamento:** os construtores de `Horario` e `Periodo` não são expostos pelo módulo `frontend/src/Horario.elm:1`.

### 6.3 Trecho em destaque

Trecho de `frontend/src/Horario.elm:243`:

```elm
deTexto : String -> Maybe Horario
deTexto texto =
    let
        ( digitosDias, resto ) =
            separarDigitos (String.toList texto)
    in
    case resto of
        letra :: digitosPeriodos ->
            Maybe.map2
                (\diasLidos periodosLidos ->
                    Horario texto (combinar diasLidos periodosLidos)
                )
                (lerTodos lerDia digitosDias)
                (turnoDaLetra letra
                    |> Maybe.andThen
                        (\valor -> lerTodos (lerPeriodo valor) digitosPeriodos)
                )

        [] ->
            Nothing
```

O parser separa dias, turno e períodos do código SIGAA. `Maybe.andThen`
interpreta os períodos apenas se o turno for válido. `Maybe.map2` constrói o
horário apenas quando as duas leituras têm sucesso. Uma falha se propaga como
`Nothing`, sem exceção nem valor substituto que esconda a entrada inválida.
O decoder da resposta transforma essa falha em erro de JSON em
`frontend/src/Codec.elm:95`.

## 7. Integração

Rotas implementadas em `backend/server.py:111`:

| Rota / chamada | Entrada | Saída | Predicado Prolog |
|----------------|---------|-------|------------------|
| `GET /api/saude` | Nenhuma | `{"status":"ok"}` | Nenhum |
| `GET /api/disciplinas` | Nenhuma | Matriz, fontes, período e disciplinas com créditos e indicação de turmas | Nenhum; lê o catálogo em memória |
| `GET /api/turmas` | Código opcional em `?codigo=FGA0210` | Oferta do semestre, horários e vagas | Nenhum; lê a oferta em memória |
| `POST /api/gerar-grades` | Listas `cursadas`, `desejadas`, `bloqueados`; pesos opcionais | Objeto `grades`, com ranking, métricas e turmas | `ranking:top_5_grades_pesos/6` |
| Inicialização da API | Disciplinas, turmas e grupos de requisitos dos JSONs | Base Prolog carregada ou falha na inicialização | `turmas:carregar_oferta/3` |

Exemplo de requisição:

```json
{
  "cursadas": ["FGA0158", "FGA0003"],
  "desejadas": ["FGA0210"],
  "bloqueados": []
}
```

Cada item de `grades` contém `rank`, `score`, `janelas`, `dias_campus` e
`turmas`; cada turma contém `codigo`, `turma` e `horarios`. O Janus recebe
argumentos separados da consulta, e a consulta converte os termos Prolog em
listas antes da serialização (`backend/server.py:99`). Um lock serializa as
chamadas ao motor.

Sem combinação válida, a API devolve `{"grades":[]}`. Desejadas vazias geram
HTTP 400. O Pydantic trata erros de formato com HTTP 422; isso não equivale a
validar todos os códigos e horários do domínio. A pontuação é
`peso_janelas * janelas + peso_dias * dias_campus`. A API usa 7 e 1 por padrão;
a interface inicia com 3 e 2. Os pesos precisam ser inteiros não negativos;
zero ignora o respectivo critério.

## 8. Testes e validação

Execução verificada em 25/11/2026: `make test` concluiu com 144 testes passando.

| Suíte | Quantidade | Cobertura |
|-------|------------|-----------|
| PlUnit | 62 | 22 casos de regras, 30 de ranking e 10 de carregamento da oferta em `prolog/tests/` |
| pytest | 9 | Parser de requisitos e integração Python–Janus–Prolog com a oferta real em `backend/tests/test_oferta.py` |
| elm-test | 73 | Horários, JSON, células semanais, janelas, choques e visualização em `frontend/tests/` |

Casos de borda incluem horários inválidos, repetidos e fora de ordem,
disciplinas duplicadas ou inexistentes, pré-requisitos com “e” e “ou”, turmas
sem vagas, todos os períodos bloqueados, limites de créditos, empates no
ranking e ausência de soluções. Os testes de oferta verificam substituição,
recarga sem duplicatas e preservação da base anterior após falha, usando
`snapshot/1` para isolar alterações.

Na oferta real, o pytest verifica as turmas `01`, `02` e `03` de `FGA0210`,
a exclusão da turma `01` ao bloquear `3T4` e a falta de resultados quando um
pré-requisito está ausente. Também verifica a pontuação com pesos enviados e
a rejeição de peso negativo; o PlUnit verifica a mudança de ordem com pesos
personalizados. Os testes chamam a função do endpoint diretamente;
não constituem uma suíte de transporte HTTP ou de navegador. Os testes Elm
não cobrem o ciclo completo de `Main.update` nem diretamente o encoder
`Types.encodeRequest`, usado pela tela.

Também foram verificados a instalação e a compilação pelo Makefile, HTTP 200
na página, no CSS e na rota de saúde, e o fluxo no navegador para gerar as
três opções de `FGA0210` usadas na captura. Roteiro manual adicional: bloquear
terça-feira T4, gerar novamente e conferir apenas as turmas `02` e `03`;
retirar um pré-requisito e conferir a mensagem de ausência de grades.



## 9. Limitações e problemas conhecidos

- A oferta é uma cópia de 2026/2, consultada em 25/11/2026. Não há atualização de vagas em tempo real nem matrícula no SIGAA.
- O catálogo é da matriz 6360/2 de Engenharia de Software, com 42 disciplinas obrigatórias e 60 optativas; não cobre todos os cursos da UnB.
- Datas de vigência diferentes são tratadas como parte de uma mesma semana. Isso pode descartar combinações que só se sobrepõem no horário, mas ocorrem em partes distintas do semestre.
- Pré-requisito vazio ou ausente no JSON vira ausência de restrição. O parser aceita o formato de grupos “e/ou” do catálogo, não expressões booleanas arbitrárias.
- O Top 5 enumera todas as grades válidas antes de ordenar. Muitas disciplinas com muitas turmas podem tornar a busca lenta e consumir memória; não há limite de tempo configurado.
- O ranking mede janelas em períodos, não em minutos. A ponderação padrão 7 e 1 garante prioridade a menos janelas; com pesos personalizados, essa prioridade depende da relação entre os pesos escolhidos.
- Os limites padrão são 2 a 32 créditos. Há limites configuráveis no predicado `grade/6`, mas a interface não os expõe.
- A ausência de solução não informa qual restrição causou o problema. Também não há persistência das seleções após recarregar a página.


as prioridades seriam explicar a ausência de soluções,
modelar a vigência das turmas, ampliar os testes de integração e melhorar a
busca do ranking sem precisar materializar todas as soluções.

## 10. Contribuição de cada integrante

As contribuições abaixo correspondem aos integrantes informados e ao histórico
de commits do repositório. As contribuições de outros autores são reconhecidas
na seção 11.

| Integrante | Principais contribuições |
|------------|--------------------------|
| Gabriel Felipe Mesquita Esteves | Métricas, classificação e Top 5 em Prolog, com testes de ranking. Conteinerização, fluxo de testes em Docker e dependências npm  |
| Filipe Carvalho da Silva | Estado inicial da aplicação Elm, mensagens, atualização e integração HTTP |
| Joao Victor Marques Reis de Miranda | Filtros de disciplinas e horários bloqueados. Pesos configuráveis no Elm, na API e no Prolog, com validação e testes|
| Yasmim Oliveira Rosa | Organização inicial, regras Prolog, base demonstrativa e testes de regras` |
| Cibelly Lourenço Ferreira | Interpretação de horários, codecs JSON, distribuição semanal, GradeView, estilos da grade, demonstração e testes Elm |
| Fabio Gabriel da Silva Barbosa | Integração de GradeView com a API, catálogo e oferta SIGAA, requisitos compostos, padronização visual |

## 11. Fontes, código de terceiros e uso de IA

**Código reaproveitado e créditos.** O projeto não partiu do código do Sudoku,
mas adotou a arquitetura Elm–FastAPI–Janus–Prolog. Os scripts de avaliação do
professor foram incorporados ao diretório `scripts/`; o script `scripts/testar.sh`
faz parte do fluxo de testes Docker do projeto.

**Referências e fontes dos dados.**

- Projeto pedagógico de Engenharia de Software da FCTE, tabelas 41 e 42: [PPC de 2024](https://software.unb.br/images/ESW/PPC_Software_2024_12_16.pdf). Fonte registrada em `backend/catalogo_unb.json`.
- [Consulta pública de turmas do SIGAA](https://sigaa.unb.br/sigaa/public/turmas/listar.jsf), Campus Gama, 2026/2. Fonte e data registradas em `backend/oferta_sigaa_2026_2.json`.
- Documentação do SWI-Prolog sobre CLP(FD), DCG e Janus; guia oficial do Elm; documentação do FastAPI e do uv, citados no rascunho anterior.
- Material da disciplina: repositório `fabiommendes/paradigmas-trabalho-final`, citado no rascunho anterior como origem do modelo e do validador.

**Uso de ferramentas de IA.**

A IA ajudou a equipe a montar o código, incluindo a geração e o ajuste de
trechos da implementação. Seu uso também apoiou a análise de erros, os testes
e a documentação. Os resultados foram conferidos pela compilação, pelos
testes automatizados e pela execução dos fluxos da aplicação.

| Ferramenta | Para que foi usada | Como o grupo verificou o resultado |
|------------|--------------------|------------------------------------|
| Codex (OpenAI) / Claude | Auxílio na montagem do código, com geração e ajuste de trechos, integração entre componentes, correção de erros, criação de testes, configuração do Makefile e organização da documentação | Compilação do Elm, execução das suítes PlUnit, pytest e elm-test, consultas à API com Prolog real e verificação da geração de grades no navegador |


## 12. Apresentação oral

- **Slides:** [Caminho dos slides, link ou não há]
- **Roteiro:** proposta de 15 minutos; definir responsáveis e garantir a participação de todos.

| Parte | Duração | Quem apresenta |
|-------|:-------:|----------------|
| Contexto, público e objetivo | 2 min | Filipe Carvalho |
| Demonstração: seleção, geração, bloqueio e comparação de grades | 5 min | Yasmim Oliveira, Joao Victor |
| Prolog: restrições CLP(FD), pré-requisitos e ranking | 3 min | Gabriel Felipe  |
| Elm: Model, Msg, update e interpretação dos horários | 3 min | Cibelly Lourenço |
| Limitações e aprendizados | 2 min | Fabio Gabriel |

## 13. Reflexão sobre os paradigmas

No Prolog, a montagem da grade é descrita por condições que precisam valer
simultaneamente. Domínios de turmas e pares compatíveis permitem separar a
declaração das restrições da enumeração com `label/1`. Isso facilita acrescentar
regras sem escrever um controle manual de tentativas. A dificuldade aparece
na representação dos horários, nos modos dos predicados e no custo de reunir
todas as soluções para ordenar o Top 5.

No Elm, o foco passa para transformações explícitas de estado. Uma mensagem
produz um novo modelo e, quando necessário, um comando HTTP. Tipos como
`Estado` evitam combinações contraditórias dentro de uma requisição, e
`Maybe Horario` exige tratar entradas inválidas. O compilador também rejeitou
a atualização direta de um record aninhado, corrigida no commit `ee754d0` com
uma referência local ao pedido. Ainda assim, tipos não eliminam todas as
validações: as listas de disciplinas usam strings e precisam de regras de
atualização e conferência no motor.

A integração exige distinguir o dado recebido em JSON do dado já validado
pelo domínio. Prolog responde quais combinações satisfazem as regras; Elm
representa as escolhas e respostas como dados e constrói a interface a partir
delas. Essa separação permite testar a lógica de horários e a geração de
grades sem depender do navegador, mantendo a comunicação com o motor no Python.
