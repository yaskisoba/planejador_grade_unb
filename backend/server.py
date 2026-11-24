from pathlib import Path
from threading import Lock

import janus_swi as janus
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

ROOT = Path(__file__).resolve().parent.parent

janus.consult(str(ROOT/"prolog"/"ranking.pl"))

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



def main():
    uvicorn.run("server:app", host="127.0.0.1", port=8000)


if __name__ == "__main__":
    main()
