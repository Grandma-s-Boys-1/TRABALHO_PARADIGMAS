from fastapi.testclient import TestClient

from app.main import app

cliente = TestClient(app)

CORRETAS = [[0, 0, 3, 0], [0, 0, 1, 2], [0, 0, 0, 0], [0, 0, 2, 0]]
LETRAS = {"C": "cima", "B": "baixo", "E": "esquerda", "D": "direita"}


def inicio(fase, entradas=None):
    estado = cliente.get(f"/api/fases/{fase}").json()["inicio"]
    if entradas is not None:
        estado["entradas"] = entradas
    return estado


def jogar(fase, estado, percurso):
    resposta = None
    for letra in percurso:
        pedido = {"fase": fase, "estado": estado, "direcao": LETRAS[letra]}
        resposta = cliente.post("/api/jogada", json=pedido).json()
        estado = resposta["estado"]
    return resposta


def test_lista_as_fases_da_base():
    resposta = cliente.get("/api/fases")
    assert resposta.status_code == 200
    ids = [fase["id"] for fase in resposta.json()]
    assert ids[:2] == ["tutorial", "comum"]


def test_fase_comum_tem_sudoku_e_ligacoes():
    fase = cliente.get("/api/fases/comum").json()
    assert fase["sudoku"]["pistas"][0] == [1, 0, 0, 4]
    assert {"letra": "A", "linha": 1, "coluna": 2} in fase["sudoku"]["ligacoes"]
    assert fase["inicio"]["jogador"] == {"linha": 1, "coluna": 3}


def test_tutorial_nao_tem_sudoku():
    assert cliente.get("/api/fases/tutorial").json()["sudoku"] is None


def test_caminhada_e_empurrao():
    estado = inicio("comum")
    andou = jogar("comum", estado, "E")
    assert andou["movimento"] == "caminhada"
    empurrou = jogar("comum", andou["estado"], "B")
    assert empurrou["movimento"] == "empurrao"
    assert {"numero": 2, "linha": 3, "coluna": 2} in empurrou["estado"]["caixas"]


def test_parede_mantem_o_estado():
    estado = inicio("comum")
    resposta = jogar("comum", estado, "C")
    assert resposta["movimento"] == "bloqueado"
    assert resposta["estado"] == estado


def test_vitoria_com_as_quatro_entradas():
    resposta = jogar("comum", inicio("comum", CORRETAS), "EBCDDB")
    assert resposta["situacao"] == "vitoria"


def test_sem_uma_entrada_a_partida_continua():
    entradas = [linha[:] for linha in CORRETAS]
    entradas[3][2] = 0
    assert jogar("comum", inicio("comum", entradas), "EBCDDB")["situacao"] == "jogando"


def test_caixas_trocadas_vencem_so_no_tutorial():
    trocado = "EBEBDDCCDDBEECEB"
    assert jogar("tutorial", inicio("tutorial"), trocado)["situacao"] == "vitoria"
    assert jogar("comum", inicio("comum", CORRETAS), trocado)["situacao"] == "jogando"


def test_situacao_depois_de_digitar():
    estado = jogar("comum", inicio("comum"), "EBCDDB")["estado"]
    estado["entradas"] = CORRETAS
    resposta = cliente.post("/api/situacao", json={"fase": "comum", "estado": estado})
    assert resposta.json() == {"situacao": "vitoria"}


def test_dica_inicial_aponta_um_passo():
    resposta = cliente.post("/api/dica", json={"fase": "comum", "estado": inicio("comum")})
    ajuda = resposta.json()
    assert ajuda["dados"]["situacao"] == "passo"
    assert ajuda["dados"]["passos"] == 6
    assert ajuda["destaques"][0]["tabuleiro"] == "armazem"


def test_dica_informa_impasse():
    estado = jogar("comum", inicio("comum"), "EEBBDCDCE")["estado"]
    assert {"numero": 2, "linha": 1, "coluna": 1} in estado["caixas"]
    ajuda = cliente.post("/api/dica", json={"fase": "comum", "estado": estado}).json()
    assert ajuda["dados"]["situacao"] == "impasse"


def test_dica_pede_revisao_de_entrada_contraditoria():
    estado = inicio("comum", [[0, 0, 2, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
    ajuda = cliente.post("/api/dica", json={"fase": "comum", "estado": estado}).json()
    assert ajuda["dados"]["situacao"] == "revisar"
    assert ajuda["destaques"] == [
        {"tabuleiro": "sudoku", "linha": 1, "coluna": 3, "marca": "revisar"}
    ]


def test_estado_invalido_e_recusado():
    estado = inicio("comum")
    estado["jogador"] = {"linha": 2, "coluna": 2}
    resposta = cliente.post("/api/situacao", json={"fase": "comum", "estado": estado})
    assert resposta.status_code == 422
    assert resposta.json()["detail"] == "Estado invalido para esta fase."


def test_entrada_em_pista_e_recusada():
    estado = inicio("comum", [[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
    resposta = cliente.post("/api/situacao", json={"fase": "comum", "estado": estado})
    assert resposta.status_code == 422


def test_fase_desconhecida():
    assert cliente.get("/api/fases/nenhuma").status_code == 404
    pedido = {"fase": "nenhuma", "estado": inicio("comum")}
    assert cliente.post("/api/situacao", json=pedido).status_code == 404


def test_pedido_malformado():
    pedido = {"fase": "comum", "estado": {"jogador": [1, 3]}}
    assert cliente.post("/api/situacao", json=pedido).status_code == 422


def test_fase_da_base_sem_diagnostico():
    pedido = {"fase": "comum", "estado": inicio("comum"), "consulta": {"tipo": "padrao"}}
    resposta = cliente.post("/api/diagnostico", json=pedido)
    assert resposta.status_code == 404
    assert resposta.json()["detail"] == "Esta fase nao tem diagnostico."
