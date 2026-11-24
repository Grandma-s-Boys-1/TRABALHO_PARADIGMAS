:- use_module(api).
:- use_module(library(plunit)).

:- begin_tests(api).

test(consulta_de_casa_com_texto, true(Consulta == casa(1, 3))) :-
    api:consulta(["casa", 1, 3], Consulta).

test(consulta_de_casa_com_atomo, true(Consulta == casa(1, 3))) :-
    api:consulta([casa, 1, 3], Consulta).

test(consulta_de_direcao, true(Consulta == direcao(cima))) :-
    api:consulta([direcao, "cima"], Consulta).

test(consulta_padrao, true(Consulta == padrao)) :-
    api:consulta([padrao], Consulta).

test(direcao_invalida, fail) :-
    api:consulta(["direcao", "diagonal"], _).

test(saida_valida, true(Lista-Dados == [[armazem, 1, 2, passo]]-[passos-[cima, 2-3]])) :-
    api:saida(ajuda("Texto", [armazem(1-2, passo)], [passos-[cima, 2-3]]), _, Lista, Dados).

test(dado_composto_recusado, fail) :-
    api:saida(ajuda("Texto", [], [passos-f(1)]), _, _, _).

test(destaque_invalido_recusado, fail) :-
    api:saida(ajuda("Texto", [mesa(1-2, passo)], []), _, _, _).

:- end_tests(api).
