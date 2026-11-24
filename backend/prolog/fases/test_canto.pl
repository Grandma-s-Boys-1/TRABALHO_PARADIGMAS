:- use_module(canto).
:- use_module('../motor').
:- use_module(library(plunit)).

:- begin_tests(canto).

vazias([[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]).

preso(Fase, Preso) :-
    canto:fase(Fase),
    inicio(Fase, Estado),
    percurso("CDCE", Direcoes),
    executar(Fase, Estado, Direcoes, Preso).

teste(Alvo, Fase) :-
    vazias(Vazias),
    Fase = fase("Teste", armazem(3, 3, [], [a-Alvo]), classica, estado(3-3, [2-(1-1)], Vazias)).

test(impasse_no_canto, true(Presas == [2-(1-1)])) :-
    preso(Fase, Preso),
    presas_no_canto(Fase, Preso, Presas),
    \+ rota_vencedora(Fase, Preso, _),
    dica(Fase, Preso, ajuda(_, _, Dados)),
    memberchk(situacao-impasse, Dados).

test(canto_que_e_alvo, true(Presas == [])) :-
    teste(1-1, Fase),
    inicio(Fase, Estado),
    presas_no_canto(Fase, Estado, Presas).

test(canto_fora_do_alvo, true(Presas == [2-(1-1)])) :-
    teste(3-1, Fase),
    inicio(Fase, Estado),
    presas_no_canto(Fase, Estado, Presas).

test(rota_inicial, true(Passos == 9)) :-
    canto:fase(Fase),
    inicio(Fase, Estado),
    rota_vencedora(Fase, Estado, Caminho),
    length(Caminho, Passos).

test(inicio_sem_presas, true(Dados == [presas-[]])) :-
    canto:fase(Fase),
    inicio(Fase, Estado),
    diagnostico(Fase, Estado, padrao, ajuda("Nenhuma caixa presa em canto.", [], Dados)).

test(diagnostico_do_impasse, true(Destaques-Dados == Esperado)) :-
    Esperado = [armazem(1-1, alerta)]-[presas-[[2, 1, 1]]],
    preso(Fase, Preso),
    diagnostico(Fase, Preso, padrao, ajuda(_, Destaques, Dados)).

test(outra_consulta, fail) :-
    canto:fase(Fase),
    inicio(Fase, Estado),
    diagnostico(Fase, Estado, direcao(cima), _).

:- end_tests(canto).
