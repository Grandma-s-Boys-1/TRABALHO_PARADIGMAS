:- use_module(motor).
:- use_module(grade).
:- use_module(fases/tutorial, []).
:- use_module(fases/comum, []).
:- use_module(library(plunit)).

:- begin_tests(motor).

corretas([[0, 0, 3, 0], [0, 0, 1, 2], [0, 0, 0, 0], [0, 0, 2, 0]]).

comum(Fase, Estado) :-
    comum:fase(Fase),
    inicio(Fase, Estado).

com_entradas(Fase, Entradas, estado(J, Cs, Entradas)) :-
    inicio(Fase, estado(J, Cs, _)).

depois(Fase, Estado, Texto, Final) :-
    percurso(Texto, Direcoes),
    executar(Fase, Estado, Direcoes, Final).

test(caminhada, true(Tipo == caminhada)) :-
    comum(Fase, Estado),
    once(movimento(Fase, Estado, esquerda, Tipo, _)).

test(empurrao, true(Caixas == [2-(3-2), 4-(2-4)])) :-
    comum(Fase, Estado),
    depois(Fase, Estado, "EB", estado(_, Caixas, _)).

test(parede_bloqueia, true(Resultado-Proximo == bloqueado-Estado)) :-
    comum(Fase, Estado),
    jogar(Fase, Estado, cima, Proximo, Resultado).

test(nao_empurra_duas_caixas, fail) :-
    fase_combinada("Fila", [], 2-1, [2-(2-2), 4-(2-3)], Fase),
    inicio(Fase, Estado),
    passo(Fase, Estado, direita, _).

test(nao_puxa_caixa, true(Caixas == Iniciais)) :-
    comum(Fase, Estado),
    Estado = estado(_, Iniciais, _),
    depois(Fase, Estado, "EBC", estado(_, Caixas0, _)),
    depois(Fase, estado(1-2, Iniciais, []), "E", estado(_, Caixas, _)),
    Caixas0 \== Iniciais.

test(percurso_minimo_vence) :-
    comum:fase(Fase),
    corretas(Corretas),
    com_entradas(Fase, Corretas, Estado),
    depois(Fase, Estado, "EBCDDB", Final),
    vitoria(Fase, Final).

test(falta_uma_entrada) :-
    comum:fase(Fase),
    com_entradas(Fase, [[0, 0, 3, 0], [0, 0, 1, 2], [0, 0, 0, 0], [0, 0, 0, 0]], Estado),
    depois(Fase, Estado, "EBCDDB", Final),
    alvos_ocupados(Fase, Final),
    \+ vitoria(Fase, Final),
    situacao(Fase, Final, jogando).

test(caixas_trocadas, true(Grade == [[1, 4, 3, 4], [3, 4, 1, 2], [2, 1, 2, 3], [4, 3, 2, 1]])) :-
    comum:fase(Fase),
    tutorial:fase(Tutorial),
    corretas(Corretas),
    com_entradas(Fase, Corretas, Estado),
    depois(Fase, Estado, "EBEBDDCCDDBEECEB", Final),
    vitoria(Tutorial, Final),
    \+ vitoria(Fase, Final),
    grade_atual(Fase, Final, Grade).

test(chave_distingue_caixas) :-
    comum(Fase, Estado),
    depois(Fase, Estado, "EBCDDB", estado(J, Caixas, E)),
    depois(Fase, Estado, "EBEBDDCCDDBEECEB", estado(_, Trocadas, _)),
    Caixas \== Trocadas,
    pronto(Fase, estado(J, Caixas, E)),
    \+ pronto(Fase, estado(J, Trocadas, E)).

test(rota_minima_comum, true(Passos == 6)) :-
    comum(Fase, Estado),
    rota_vencedora(Fase, Estado, Caminho),
    length(Caminho, Passos).

test(rota_corrige_troca) :-
    comum(Fase, Estado),
    depois(Fase, Estado, "EBEBDDCCDDBEECEB", Trocado),
    rota_vencedora(Fase, Trocado, Caminho),
    executar(Fase, Trocado, Caminho, Final),
    pronto(Fase, Final).

test(sem_rota, fail) :-
    fase_combinada("Canto", [], 3-2, [2-(2-2), 4-(2-4)], Fase),
    inicio(Fase, Estado),
    depois(Fase, Estado, "CDCE", Preso),
    rota_vencedora(Fase, Preso, _).

test(dica_impasse, true(Situacao == impasse)) :-
    fase_combinada("Canto", [], 3-2, [2-(2-2), 4-(2-4)], Fase),
    inicio(Fase, Estado),
    depois(Fase, Estado, "CDCE", Preso),
    grade_atual(Fase, Preso, Grade),
    admite_conclusao(Grade),
    dica(Fase, Preso, ajuda(_, _, Dados)),
    memberchk(situacao-Situacao, Dados).

test(dica_revisar_entradas, true(Destaques == [sudoku(1-3, revisar)])) :-
    comum:fase(Fase),
    com_entradas(Fase, [[0, 0, 2, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]], Estado),
    dica(Fase, Estado, ajuda(_, Destaques, Dados)),
    memberchk(situacao-revisar, Dados).

test(dica_numero_depois_dos_alvos, true(Destaques == [sudoku(1-3, dica)])) :-
    comum(Fase, Estado),
    depois(Fase, Estado, "EBCDDB", Final),
    dica(Fase, Final, ajuda(_, Destaques, Dados)),
    memberchk(valor-3, Dados).

test(dica_nao_preenche_a_grade, true(Entradas == Antes)) :-
    comum(Fase, Estado),
    Estado = estado(_, _, Antes),
    dica(Fase, Estado, _),
    Estado = estado(_, _, Entradas).

seguir_dicas(Fase, Estado, Estado, 0) :-
    pronto(Fase, Estado),
    !.
seguir_dicas(Fase, Estado, Final, N) :-
    dica(Fase, Estado, ajuda(_, _, Dados)),
    memberchk(direcao-Direcao, Dados),
    executar(Fase, Estado, [Direcao], Proximo),
    seguir_dicas(Fase, Proximo, Final, N0),
    N is N0 + 1.

test(dicas_depois_de_sair_do_exemplo, true(Seguidos == Previstos)) :-
    comum(Fase, Estado),
    depois(Fase, Estado, "EEBB", Desvio),
    dica(Fase, Desvio, ajuda(_, _, Dados)),
    memberchk(passos-Previstos, Dados),
    seguir_dicas(Fase, Desvio, Final, Seguidos),
    alvos_ocupados(Fase, Final).

test(tipos_de_casa, true(Tipos == [pista(1), ligada(a), editavel])) :-
    comum:fase(Fase),
    maplist(tipo_casa(Fase), [1-1, 1-2, 1-3], Tipos).

test(valor_ligado_some_ao_sair, true(Valores == [2, 0])) :-
    comum(Fase, Estado),
    depois(Fase, Estado, "EB", NoAlvo),
    depois(Fase, Estado, "EBEBDDCCDDB", ForaDoAlvo),
    valor_ligado(Fase, NoAlvo, a, V1),
    valor_ligado(Fase, ForaDoAlvo, a, V2),
    Valores = [V1, V2].

test(estado_valido) :-
    comum(Fase, Estado),
    estado_valido(Fase, Estado).

test(jogador_sobre_caixa, fail) :-
    comum(Fase, estado(_, Caixas, Entradas)),
    estado_valido(Fase, estado(2-2, Caixas, Entradas)).

test(entrada_em_casa_ligada, fail) :-
    comum(Fase, estado(J, Caixas, _)),
    Entradas = [[0, 2, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]],
    estado_valido(Fase, estado(J, Caixas, Entradas)).

:- end_tests(motor).
