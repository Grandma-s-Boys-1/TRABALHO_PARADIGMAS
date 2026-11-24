.PHONY: install dev backend frontend test test-prolog test-backend test-frontend
.PHONY: formato build validar ascii

TESTES_PROLOG = $(wildcard backend/prolog/test_*.pl backend/prolog/fases/test_*.pl)

ARQUIVOS = $(wildcard Makefile scripts/verificar_ascii.py backend/pyproject.toml \
	backend/app/*.py backend/tests/*.py backend/prolog/*.pl backend/prolog/fases/*.pl \
	frontend/index.html frontend/package.json frontend/elm.json frontend/vite.config.js \
	frontend/src/*.js frontend/src/*.css frontend/src/*.elm frontend/src/Fases/*.elm \
	frontend/tests/*.elm frontend/tests/Fases/*.elm)

install:
	cd backend && uv sync
	cd frontend && npm install

dev:
	$(MAKE) -j2 backend frontend

backend:
	cd backend && uv run fastapi dev app/main.py

frontend:
	cd frontend && npm run dev

test: test-prolog test-backend test-frontend

test-prolog:
	@falhas=0; \
	for arquivo in $(TESTES_PROLOG); do \
		echo "== $$arquivo"; \
		swipl -g run_tests -t halt $$arquivo || falhas=1; \
	done; \
	exit $$falhas

test-backend:
	cd backend && uv run pytest

test-frontend:
	cd frontend && npx elm-test

formato:
	cd frontend && npx elm-format --validate src tests

build:
	cd frontend && npm run build

validar:
	uv run scripts/validar_entrega.py

ascii:
	uv run scripts/verificar_ascii.py $(ARQUIVOS)
