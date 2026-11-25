:- use_module('../motor').
:- use_module(fila).
:- use_module(library(plunit)).

:- begin_tests(fila).

corretas([[0, 0, 3, 0], [0, 0, 1, 2], [0, 0, 0, 0], [0, 0, 2, 0]]).

inicial(Fase, Estado) :-
    fase(Fase),
    inicio(Fase, Estado).

depois(Fase, Estado, Texto, Final) :-
    percurso(Texto, Direcoes),
    executar(Fase, Estado, Direcoes, Final).

coincide(Fase, Estado, Direcao) :-
    jogar(Fase, Estado, Direcao, _, Resultado),
    ( bloqueio(Fase, Estado, Direcao, _) -> Resultado == bloqueado
    ; Resultado \== bloqueado
    ).

test(fila_bloqueada, true(Motivo == fila(2, 4))) :-
    inicial(Fase, Estado),
    bloqueio(Fase, Estado, direita, Motivo),
    jogar(Fase, Estado, direita, Proximo, bloqueado),
    Proximo == Estado.

test(esquerda_parede, true(Motivo == parede)) :-
    inicial(Fase, Estado),
    bloqueio(Fase, Estado, esquerda, Motivo).

test(cima_sem_bloqueio, fail) :-
    inicial(Fase, Estado),
    bloqueio(Fase, Estado, cima, _).

test(caixa_na_parede, true(Motivo == caixa_na_parede(2))) :-
    inicial(Fase, Estado),
    depois(Fase, Estado, "CDBB", Final),
    bloqueio(Fase, Final, baixo, Motivo).

test(rota_de_sete_passos_vence) :-
    fase(Fase),
    corretas(Corretas),
    inicio(Fase, estado(J, Cs, _)),
    depois(Fase, estado(J, Cs, Corretas), "CDBDCDB", Final),
    vitoria(Fase, Final).

test(rota_minima, true(Passos == 7)) :-
    fase(Fase),
    corretas(Corretas),
    inicio(Fase, estado(J, Cs, _)),
    rota_vencedora(Fase, estado(J, Cs, Corretas), Caminho),
    length(Caminho, Passos).

test(bloqueio_coincide_com_motor) :-
    inicial(Fase, Estado),
    forall(member(Texto, ["", "C", "CDB", "CDBB", "CDBDC"]),
           ( depois(Fase, Estado, Texto, Atual),
             forall(direcao(Direcao), coincide(Fase, Atual, Direcao)) )).

test(diagnostico_fila, true(Destaques-Dados == Esperados-[motivo-fila, caixas-Caixas])) :-
    Esperados = [armazem(2-2, alerta), armazem(2-3, alerta)],
    Caixas = [[2, 2, 2], [4, 2, 3]],
    inicial(Fase, Estado),
    diagnostico(Fase, Estado, direcao(direita), ajuda(_, Destaques, Dados)).

test(diagnostico_parede, true(Destaques-Dados == []-[motivo-parede, caixas-[]])) :-
    inicial(Fase, Estado),
    diagnostico(Fase, Estado, direcao(esquerda), ajuda(_, Destaques, Dados)).

test(diagnostico_livre, true(Texto-Dados == "Movimento livre."-[motivo-livre, caixas-[]])) :-
    inicial(Fase, Estado),
    diagnostico(Fase, Estado, direcao(cima), ajuda(Texto, _, Dados)).

test(diagnostico_caixa_na_parede,
     true(Destaques-Dados ==
          [armazem(4-2, alerta)]-[motivo-caixa_na_parede, caixas-[[2, 4, 2]]])) :-
    inicial(Fase, Estado),
    depois(Fase, Estado, "CDBB", Final),
    diagnostico(Fase, Final, direcao(baixo), ajuda(_, Destaques, Dados)).

test(sem_diagnostico_padrao, fail) :-
    inicial(Fase, Estado),
    diagnostico(Fase, Estado, padrao, _).

:- end_tests(fila).
