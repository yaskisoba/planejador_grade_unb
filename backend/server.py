from pathlib import Path
from threading import Lock

import janus_swi as janus
import uvicorn
from fastapi import FastAPI
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


@app.get("/api/saude")
def saude():
    return {"status": "ok"}



def main():
    uvicorn.run("server:app", host="127.0.0.1", port=8000)


if __name__ == "__main__":
    main()
