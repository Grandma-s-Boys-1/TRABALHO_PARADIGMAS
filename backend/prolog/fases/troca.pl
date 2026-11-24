:- module(troca, [fase/1, diagnostico/4, unidades_em_conflito/2]).

:- use_module('../motor').
:- use_module('../grade').

fase(Fase) :-
    fase_combinada("Troca", [], 1-3, [2-(2-4), 4-(2-2)], Fase).

unidades_em_conflito(Grade, Nomes) :-
    unidades(Grade, Unidades),
    include(repetida, Unidades, Conflitos),
    pairs_keys(Conflitos, Nomes).

repetida(_-Valores) :-
    include(preenchida, Valores, Preenchidas),
    sort(Preenchidas, Distintas),
    length(Preenchidas, Total),
    length(Distintas, Unicas),
    Unicas < Total.

preenchida(Valor) :-
    Valor > 0.

diagnostico(Fase, Estado, padrao, ajuda(Texto, Destaques, Dados)) :-
    ( alvos_ocupados(Fase, Estado) ->
        grade_atual(Fase, Estado, Grade),
        unidades_em_conflito(Grade, Nomes),
        ligadas(Fase, Estado, Ligadas),
        texto(Nomes, Ligadas, Texto),
        destaques(Fase, Nomes, Destaques),
        dados(Nomes, Dados)
    ; Texto = "Ocupe os dois alvos para conferir.",
      Destaques = [],
      dados([], Dados)
    ).

ligadas(Fase, Estado, Texto) :-
    Fase = fase(_, _, combinada(_, Ligacoes), _),
    findall(Parte,
            ( member(Letra-_, Ligacoes),
              valor_ligado(Fase, Estado, Letra, Valor),
              upcase_atom(Letra, Maiuscula),
              format(string(Parte), "~w=~d", [Maiuscula, Valor]) ),
            Partes),
    atomic_list_concat(Partes, ' e ', Texto).

texto([], Ligadas, Texto) :-
    format(string(Texto), "Com ~w a grade nao se contradiz.", [Ligadas]).
texto([Nome|Nomes], Ligadas, Texto) :-
    maplist(nome_unidade, [Nome|Nomes], Partes),
    atomic_list_concat(Partes, ', ', Lista),
    format(string(Texto), "Com ~w a grade se contradiz em ~w.", [Ligadas, Lista]).

nome_unidade(Unidade, Nome) :-
    Unidade =.. [Tipo, Numero],
    format(string(Nome), "~w ~d", [Tipo, Numero]).

destaques(_, [], []).
destaques(Fase, [_|_], Destaques) :-
    Fase = fase(_, _, combinada(_, Ligacoes), _),
    findall(sudoku(Posicao, conflito), member(_-Posicao, Ligacoes), Destaques).

dados(Nomes, [linhas-Linhas, colunas-Colunas, blocos-Blocos]) :-
    findall(N, member(linha(N), Nomes), Linhas),
    findall(N, member(coluna(N), Nomes), Colunas),
    findall(N, member(bloco(N), Nomes), Blocos).
