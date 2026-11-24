from fastapi.testclient import TestClient

from app.main import app

cliente = TestClient(app)


def diagnosticar(estado):
    pedido = {"fase": "dica", "estado": estado, "consulta": {"tipo": "padrao"}}
    return cliente.post("/api/diagnostico", json=pedido)


def test_primeiro_empurrao_no_inicio():
    estado = cliente.get("/api/fases/dica").json()["inicio"]
    resposta = diagnosticar(estado)
    assert resposta.status_code == 200
    ajuda = resposta.json()
    assert ajuda["texto"] == "Caminhe C, C, D e empurre a caixa 4 para baixo."
    assert ajuda["dados"] == {
        "caminhada": ["cima", "cima", "direita"],
        "caixa": 4,
        "empurrao": "baixo",
        "total": 8,
    }
    marcas = [(d["linha"], d["coluna"], d["marca"]) for d in ajuda["destaques"]]
    assert marcas == [
        (2, 4, "caixa"),
        (3, 4, "destino"),
        (2, 3, "passo"),
        (1, 3, "passo"),
        (1, 4, "passo"),
    ]


def test_sem_empurrao_com_alvos_prontos():
    estado = cliente.get("/api/fases/dica").json()["inicio"]
    estado["jogador"] = {"linha": 2, "coluna": 2}
    estado["caixas"] = [
        {"numero": 2, "linha": 3, "coluna": 2},
        {"numero": 4, "linha": 3, "coluna": 4},
    ]
    ajuda = diagnosticar(estado).json()
    assert ajuda["dados"] == {}
    assert ajuda["destaques"] == []
