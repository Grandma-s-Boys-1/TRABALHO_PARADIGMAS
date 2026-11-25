:- use_module(candidatos).
:- use_module('../motor').
:- use_module(library(plunit)).

:- begin_tests(candidatos).

inicial(Fase, Estado) :-
    fase(Fase),
    inicio(Fase, Estado).

com_entradas(Entradas, Fase, estado(J, Caixas, Entradas)) :-
    inicial(Fase, estado(J, Caixas, _)).

test(inicio_l1c3, true(Valores == [3])) :-
    inicial(Fase, Estado),
    candidatos(Fase, Estado, 1-3, Valores).

test(corrige_entrada, true(Valores == [3])) :-
    com_entradas([[0, 0, 4, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]], Fase, Estado),
    candidatos(Fase, Estado, 1-3, Valores).

test(pista, true(Valores == [1])) :-
    inicial(Fase, Estado),
    candidatos(Fase, Estado, 1-1, Valores).

test(casa_ligada_sem_caixa, true(Valores == [2])) :-
    inicial(Fase, Estado),
    candidatos(Fase, Estado, 1-2, Valores).

test(rota_minima, true(Passos == 7)) :-
    inicial(Fase, Estado),
    rota_vencedora(Fase, Estado, Rota),
    length(Rota, Passos).

test(diagnostico_da_casa, true(Ajuda == ajuda("L1C3 admite: 3", [sudoku(1-3, consulta)],
                                              [candidatos-[3]]))) :-
    inicial(Fase, Estado),
    diagnostico(Fase, Estado, casa(1, 3), Ajuda).

test(outra_consulta_falha, fail) :-
    inicial(Fase, Estado),
    diagnostico(Fase, Estado, padrao, _).

:- end_tests(candidatos).
