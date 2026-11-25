:- use_module(troca).
:- use_module('../motor').
:- use_module(library(plunit)).

:- begin_tests(troca).

inicial(Fase, Estado) :-
    fase(Fase),
    inicio(Fase, Estado).

corretas([[0, 0, 3, 0], [0, 0, 1, 2], [0, 0, 0, 0], [0, 0, 2, 0]]).

depois_de(Texto, Fase, Final) :-
    inicial(Fase, estado(Jogador, Caixas, _)),
    corretas(Entradas),
    percurso(Texto, Direcoes),
    executar(Fase, estado(Jogador, Caixas, Entradas), Direcoes, Final).

texto_trocadas(Texto) :-
    string_concat("Com A=4 e B=2 a grade se contradiz em linha 1, linha 3, ",
                  "coluna 2, coluna 3, bloco 1, bloco 4.", Texto).

test(caixas_trocadas,
     true(Nomes == [linha(1), linha(3), coluna(2), coluna(3), bloco(1), bloco(4)])) :-
    depois_de("EBCDDB", Fase, Final),
    alvos_ocupados(Fase, Final),
    \+ vitoria(Fase, Final),
    grade_atual(Fase, Final, Grade),
    unidades_em_conflito(Grade, Nomes).

test(rota_minima, true(Passos == 16)) :-
    inicial(Fase, Estado),
    rota_vencedora(Fase, Estado, Rota),
    length(Rota, Passos).

test(grade_inicial_sem_conflito, true(Nomes == [])) :-
    inicial(Fase, Estado),
    grade_atual(Fase, Estado, Grade),
    unidades_em_conflito(Grade, Nomes).

test(diagnostico_das_caixas_trocadas) :-
    depois_de("EBCDDB", Fase, Final),
    diagnostico(Fase, Final, padrao, ajuda(Texto, Destaques, Dados)),
    texto_trocadas(Esperado),
    assertion(Texto == Esperado),
    assertion(Destaques == [sudoku(1-2, conflito), sudoku(3-3, conflito)]),
    assertion(Dados == [linhas-[1, 3], colunas-[2, 3], blocos-[1, 4]]).

test(diagnostico_sem_alvos,
     true(Ajuda == ajuda("Ocupe os dois alvos para conferir.", [],
                         [linhas-[], colunas-[], blocos-[]]))) :-
    inicial(Fase, Estado),
    diagnostico(Fase, Estado, padrao, Ajuda).

test(rota_certa_vence,
     true(Ajuda == ajuda("Com A=2 e B=4 a grade nao se contradiz.", [],
                         [linhas-[], colunas-[], blocos-[]]))) :-
    depois_de("EBEBDDCCDDBEECEB", Fase, Final),
    vitoria(Fase, Final),
    diagnostico(Fase, Final, padrao, Ajuda).

test(outra_consulta_falha, fail) :-
    inicial(Fase, Estado),
    diagnostico(Fase, Estado, casa(1, 3), _).

:- end_tests(troca).
