from typing import Annotated, Literal

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from app import prolog

app = FastAPI(title="Sokoban Sudoku (Prolog + Elm)")

Indice = Annotated[int, Field(ge=1, le=9)]
Digito = Annotated[int, Field(ge=0, le=4)]
Linha = Annotated[list[Digito], Field(min_length=4, max_length=4)]
Grade = Annotated[list[Linha], Field(min_length=4, max_length=4)]
Direcao = Literal["cima", "baixo", "esquerda", "direita"]


class Posicao(BaseModel):
    linha: Indice
    coluna: Indice


class Caixa(Posicao):
    numero: Annotated[int, Field(ge=1, le=4)]


class Estado(BaseModel):
    jogador: Posicao
    caixas: Annotated[list[Caixa], Field(max_length=4)]
    entradas: Grade


class Pedido(BaseModel):
    fase: str
    estado: Estado


class PedidoJogada(Pedido):
    direcao: Direcao


class Padrao(BaseModel):
    tipo: Literal["padrao"]


class Casa(BaseModel):
    tipo: Literal["casa"]
    linha: Indice
    coluna: Indice


class Sentido(BaseModel):
    tipo: Literal["direcao"]
    direcao: Direcao


class PedidoDiagnostico(Pedido):
    consulta: Annotated[Padrao | Casa | Sentido, Field(discriminator="tipo")]


FASE_DESCONHECIDA = "Fase desconhecida."
ESTADO_INVALIDO = "Estado invalido para esta fase."
SEM_DIAGNOSTICO = "Esta fase nao tem diagnostico."


def validar(pedido: Pedido) -> None:
    try:
        prolog.validar(pedido.fase, pedido.estado)
    except prolog.FaseDesconhecida:
        raise HTTPException(status_code=404, detail=FASE_DESCONHECIDA) from None
    except prolog.EstadoInvalido:
        raise HTTPException(status_code=422, detail=ESTADO_INVALIDO) from None


def consulta(pedido: Padrao | Casa | Sentido) -> list:
    match pedido:
        case Casa(linha=linha, coluna=coluna):
            return ["casa", linha, coluna]
        case Sentido(direcao=direcao):
            return ["direcao", direcao]
    return ["padrao"]


@app.get("/api/fases")
def listar_fases() -> list[dict]:
    return prolog.fases()


@app.get("/api/fases/{ident}")
def obter_fase(ident: str) -> dict:
    try:
        return prolog.fase(ident)
    except prolog.FaseDesconhecida:
        raise HTTPException(status_code=404, detail=FASE_DESCONHECIDA) from None


@app.post("/api/jogada")
def jogada(pedido: PedidoJogada) -> dict:
    validar(pedido)
    return prolog.jogada(pedido.fase, pedido.estado, pedido.direcao)


@app.post("/api/situacao")
def situacao(pedido: Pedido) -> dict:
    validar(pedido)
    return {"situacao": prolog.situacao(pedido.fase, pedido.estado)}


@app.post("/api/dica")
def dica(pedido: Pedido) -> dict:
    validar(pedido)
    return prolog.dica(pedido.fase, pedido.estado)


@app.post("/api/diagnostico")
def diagnostico(pedido: PedidoDiagnostico) -> dict:
    validar(pedido)
    try:
        return prolog.diagnostico(pedido.fase, pedido.estado, consulta(pedido.consulta))
    except prolog.SemDiagnostico:
        raise HTTPException(status_code=404, detail=SEM_DIAGNOSTICO) from None
