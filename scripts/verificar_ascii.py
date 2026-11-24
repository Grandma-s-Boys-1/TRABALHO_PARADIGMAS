import sys
from pathlib import Path

if len(sys.argv) < 2:
    sys.exit("Informe os caminhos dos arquivos.")

for nome in sys.argv[1:]:
    if not (nome.isascii() and nome.isprintable()):
        sys.exit(f"Caminho invalido: {nome!a}")
    dados = Path(nome).read_bytes().replace(b"\r\n", b"\n")
    for numero, linha in enumerate(dados.split(b"\n"), 1):
        if any(valor != 9 and not 32 <= valor <= 126 for valor in linha):
            sys.exit(f"{nome}:{numero}: caractere invalido")

print("ASCII OK")
