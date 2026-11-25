import json
import re
from pathlib import Path
from threading import Lock
from typing import Literal

import janus_swi as janus
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

ROOT = Path(__file__).resolve().parent.parent
CATALOGO_UNB = json.loads(Path(__file__).with_name("catalogo_unb.json").read_text(encoding="utf-8"))
OFERTA_SIGAA = json.loads(Path(__file__).with_name("oferta_sigaa_2026_2.json").read_text(encoding="utf-8"))
CODIGOS_COM_TURMAS = {turma["codigo"] for turma in OFERTA_SIGAA["turmas"]}


def grupos_prerequisitos(texto: str | None) -> list[list[str]]:
    if not texto:
        return []

    codigo = r"[A-Z]{2,6}\d{4}"
    alternativa = rf"(?:{codigo}|\({codigo}(?: ou {codigo})+\))"
    grupos = texto.split(" e ")
    if not all(re.fullmatch(rf"{alternativa}(?: ou {alternativa})*", grupo) for grupo in grupos):
        raise ValueError(f"Formato de pré-requisito não reconhecido: {texto}")

    return [re.findall(codigo, grupo) for grupo in grupos]


def carregar_oferta_sigaa() -> None:
    disciplinas = CATALOGO_UNB["disciplinas"]
    requerimentos = [
        [disciplina["codigo"], grupo]
        for disciplina in disciplinas
        for grupo in grupos_prerequisitos(disciplina["prerequisitos"])
    ]
    dados = {
        "Disciplinas": [[d["codigo"], d["nome"], d["carga_horaria"] // 15] for d in disciplinas],
        "Turmas": [
            [t["codigo"], t["turma"], t["horarios"], max(0, t["vagas_ofertadas"] - t["vagas_ocupadas"])]
            for t in OFERTA_SIGAA["turmas"]
        ],
        "Requisitos": requerimentos,
    }
    resposta = janus.query_once("turmas:carregar_oferta(Disciplinas, Turmas, Requisitos)", dados)
    if not resposta.get("truth"):
        raise RuntimeError("Falha ao carregar a oferta do SIGAA no motor Prolog.")


janus.consult(str(ROOT / "prolog" / "ranking.pl"))
carregar_oferta_sigaa()

trava = Lock()

app = FastAPI(title="Planejador de Grade UnB")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class Requisicao(BaseModel):
    cursadas: list[str] = []
    desejadas: list[str] = []
    bloqueados: list[str] = []
    peso_janelas: int = 7
    peso_dias: int = 1


class Disciplina(BaseModel):
    codigo: str
    nome: str
    categoria: Literal["obrigatoria", "optativa"]
    carga_horaria: int
    creditos: int
    prerequisitos: str | None
    tem_turmas: bool


class Catalogo(BaseModel):
    matriz: str
    fonte: str
    fonte_turmas: Literal["sigaa"]
    periodo_turmas: str
    disciplinas: list[Disciplina]


# O findall converte resultado(...) e turma(...) em listas simples,
# que o janus traduz direto para listas Python.
# Variáveis com "_" no início não são devolvidas ao Python pelo janus.
# Sem isso, ele tenta converter as variáveis internas (livres ou compostas)
# e dá erro. Só R volta para o Python.
CONSULTA = """
    ranking:top_5_grades(Cursadas, Desejadas, Bloqueados, _Top5),
    findall([_Pontuacao, _Janelas, _Dias, _Turmas],
            ( member(resultado(_Pontuacao, _Janelas, _Dias, _Grade), _Top5),
              findall([_Codigo, _Id, _Horarios],
                      member(turma(_Codigo, _Id, _, _Horarios, _), _Grade),
                      _Turmas) ),
            R)
"""


@app.get("/api/saude")
def saude():
    return {"status": "ok"}


@app.get("/api/disciplinas")
def listar_disciplinas() -> Catalogo:
    return Catalogo(
        matriz=CATALOGO_UNB["matriz"],
        fonte=CATALOGO_UNB["fonte"],
        fonte_turmas="sigaa",
        periodo_turmas=OFERTA_SIGAA["periodo"],
        disciplinas=[
            Disciplina(
                **disciplina,
                creditos=disciplina["carga_horaria"] // 15,
                tem_turmas=disciplina["codigo"] in CODIGOS_COM_TURMAS,
            )
            for disciplina in CATALOGO_UNB["disciplinas"]
        ],
    )


@app.get("/api/turmas")
def listar_turmas(codigo: str | None = None):
    if codigo is None:
        return OFERTA_SIGAA

    codigo = codigo.strip().upper()
    return {
        **OFERTA_SIGAA,
        "turmas": [turma for turma in OFERTA_SIGAA["turmas"] if turma["codigo"] == codigo],
    }


@app.post("/api/gerar-grades")
def gerar_grades(req: Requisicao):
    if not req.desejadas:
        raise HTTPException(status_code=400, detail="Selecione ao menos uma disciplina.")

    with trava:
        resposta = janus.query_once(
            CONSULTA,
            {"Cursadas": req.cursadas, "Desejadas": req.desejadas, "Bloqueados": req.bloqueados},
        )

    if not resposta.get("truth"):
        raise HTTPException(status_code=500, detail="Falha ao consultar o motor Prolog.")

    grades = []
    for rank, (pontuacao, janelas, dias, turmas) in enumerate(resposta["R"], start=1):
        grades.append({
            "rank": rank,
            "score": pontuacao,
            "janelas": janelas,
            "dias_campus": dias,
            "turmas": [
                {"codigo": codigo, "turma": turma, "horarios": horarios}
                for codigo, turma, horarios in turmas
            ],
        })

    # Lista vazia é resposta válida: o Elm mostra "nenhuma grade compatível".
    return {"grades": grades}


@app.get("/grade.css", include_in_schema=False)
def estilos_grade() -> FileResponse:
    return FileResponse(ROOT / "frontend" / "grade.css", media_type="text/css")


# Precisa vir DEPOIS das rotas /api, senão o "/" captura tudo.
FRONTEND = ROOT / "frontend" / "build"
if FRONTEND.is_dir():
    app.mount("/", StaticFiles(directory=FRONTEND, html=True), name="frontend")


def main():
    uvicorn.run("server:app", host="127.0.0.1", port=8000)


if __name__ == "__main__":
    main()
