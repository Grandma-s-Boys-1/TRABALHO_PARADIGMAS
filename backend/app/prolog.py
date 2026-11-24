from pathlib import Path

import janus_swi as janus

janus.consult(str(Path(__file__).parent.parent / "prolog" / "api.pl"))


class FaseDesconhecida(Exception):
    pass


class EstadoInvalido(Exception):
    pass


class SemDiagnostico(Exception):
    pass


def posicao(par):
    linha, coluna = par
    return {"linha": linha, "coluna": coluna}


def caixa(par):
    numero, (linha, coluna) = par
    return {"numero": numero, "linha": linha, "coluna": coluna}


def letra(par):
    nome, (linha, coluna) = par
    return {"letra": nome, "linha": linha, "coluna": coluna}


def estado_json(jogador, caixas, entradas):
    return {
        "jogador": posicao(jogador),
        "caixas": [caixa(c) for c in caixas],
        "entradas": entradas,
    }


def sudoku_json(sudoku):
    if not sudoku:
        return None
    pistas, ligacoes = sudoku
    return {"pistas": pistas, "ligacoes": [letra(l) for l in ligacoes]}


def ajuda_json(resultado):
    return {
        "texto": resultado["Mensagem"],
        "destaques": [
            {"tabuleiro": t, "linha": l, "coluna": c, "marca": m}
            for t, l, c, m in resultado["Destaques"]
        ],
        "dados": dict(resultado["Dados"]),
    }


def entrada(fase, estado):
    return {
        "Fase": fase,
        "J": (estado.jogador.linha, estado.jogador.coluna),
        "Cs": [(c.numero, (c.linha, c.coluna)) for c in estado.caixas],
        "E": estado.entradas,
    }


def fases():
    resultado = janus.query_once("api:listar(Lista)")
    return [
        {"id": ident, "nome": nome, "regra": regra}
        for ident, nome, regra in resultado["Lista"]
    ]


def fase(ident):
    resultado = janus.query_once(
        "api:dados(Fase, Nome, Dimensoes, Paredes, Alvos, Sudoku, Inicio)",
        {"Fase": ident},
    )
    if not resultado["truth"]:
        raise FaseDesconhecida
    linhas, colunas = resultado["Dimensoes"]
    return {
        "id": ident,
        "nome": resultado["Nome"],
        "armazem": {
            "linhas": linhas,
            "colunas": colunas,
            "paredes": [posicao(p) for p in resultado["Paredes"]],
            "alvos": [letra(a) for a in resultado["Alvos"]],
        },
        "sudoku": sudoku_json(resultado["Sudoku"]),
        "inicio": estado_json(*resultado["Inicio"]),
    }


def validar(fase, estado):
    if not janus.query_once("api:existe(Fase)", {"Fase": fase})["truth"]:
        raise FaseDesconhecida
    if not janus.query_once("api:aceitar(Fase, J, Cs, E)", entrada(fase, estado))["truth"]:
        raise EstadoInvalido


def jogada(fase, estado, direcao):
    resultado = janus.query_once(
        "api:mover(Fase, J, Cs, E, Sentido, J1, Cs1, Movimento, Situacao)",
        entrada(fase, estado) | {"Sentido": direcao},
    )
    return {
        "estado": estado_json(resultado["J1"], resultado["Cs1"], estado.entradas),
        "movimento": resultado["Movimento"],
        "situacao": resultado["Situacao"],
    }


def situacao(fase, estado):
    resultado = janus.query_once("api:avaliar(Fase, J, Cs, E, Situacao)", entrada(fase, estado))
    return resultado["Situacao"]


def dica(fase, estado):
    resultado = janus.query_once(
        "api:pedir_dica(Fase, J, Cs, E, Mensagem, Destaques, Dados)",
        entrada(fase, estado),
    )
    return ajuda_json(resultado)


def diagnostico(fase, estado, consulta):
    resultado = janus.query_once(
        "api:pedir_diagnostico(Fase, J, Cs, E, Consulta, Mensagem, Destaques, Dados)",
        entrada(fase, estado) | {"Consulta": consulta},
    )
    if not resultado["truth"]:
        raise SemDiagnostico
    return ajuda_json(resultado)
