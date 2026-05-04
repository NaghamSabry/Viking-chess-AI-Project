:- use_module(library(random)).
:- dynamic history/1.
:- dynamic last_moves/1.

% ==========================================
%  BOARD SETUP & HELPERS
% ==========================================
board_size(9).
throne(4, 4).
corner(0, 0). corner(0, 8). corner(8, 0). corner(8, 8).

hostile(R, C) :- throne(R, C).
hostile(R, C) :- corner(R, C).

index_of(Row, Col, Size, Index) :- Index is Row * Size + Col.

get_cell(Board, Row, Col, Cell) :-
    board_size(Size),
    index_of(Row, Col, Size, Index),
    nth0(Index, Board, Cell).

set_cell(Board, Row, Col, NewCell, NewBoard) :-
    board_size(Size),
    index_of(Row, Col, Size, Index),
    replace_nth0(Index, Board, NewCell, NewBoard).

replace_nth0(0, [_|T], Elem, [Elem|T]).
replace_nth0(I, [H|T], Elem, [H|T2]) :-
    I > 0, I1 is I - 1,
    replace_nth0(I1, T, Elem, T2).

initial_board(Board) :-
    board_size(Size),
    TotalCells is Size * Size,
    length(EmptyBoard, TotalCells),
    maplist(=(e), EmptyBoard),
    place_pieces(EmptyBoard, Board).

place_pieces(B0, Board) :-
    set_cell(B0, 4, 4, k, B1),
    set_cell(B1,  2, 4, d, B2),
    set_cell(B2,  3, 3, d, B3),
    set_cell(B3,  3, 4, d, B4),
    set_cell(B4,  3, 5, d, B5),
    set_cell(B5,  4, 2, d, B6),
    set_cell(B6,  4, 3, d, B7),
    set_cell(B7,  4, 5, d, B8),
    set_cell(B8,  4, 6, d, B9),
    set_cell(B9,  5, 3, d, B10),
    set_cell(B10, 5, 4, d, B11),
    set_cell(B11, 5, 5, d, B12),
    set_cell(B12, 6, 4, d, B13),
    set_cell(B13, 0, 3, a, B14),
    set_cell(B14, 0, 4, a, B15),
    set_cell(B15, 0, 5, a, B16),
    set_cell(B16, 1, 4, a, B17),
    set_cell(B17, 8, 3, a, B18),
    set_cell(B18, 8, 4, a, B19),
    set_cell(B19, 8, 5, a, B20),
    set_cell(B20, 7, 4, a, B21),
    set_cell(B21, 3, 0, a, B22),
    set_cell(B22, 4, 0, a, B23),
    set_cell(B23, 5, 0, a, B24),
    set_cell(B24, 4, 1, a, B25),
    set_cell(B25, 3, 8, a, B26),
    set_cell(B26, 4, 8, a, B27),
    set_cell(B27, 5, 8, a, B28),
    set_cell(B28, 4, 7, a, Board).

cell_symbol(e, ' . ').
cell_symbol(k, ' K ').
cell_symbol(d, ' D ').
cell_symbol(a, ' A ').

print_board(Board) :-
    board_size(Size), nl, print_col_header(Size),
    print_rows(Board, 0, Size), nl.

print_col_header(_Size) :-
    write('     '), forall(between(0, 8, C), (format('~w  ', [C]))), nl,
    write('   +'), forall(between(0, 8, _), write('---')), write('+'), nl.

print_rows(_, Row, Size) :- Row >= Size, !.
print_rows(Board, Row, Size) :-
    format('~w | ', [Row]), print_cols(Board, Row, 0, Size),
    write('|'), nl, Next is Row + 1, print_rows(Board, Next, Size).

print_cols(_, _, Col, Size) :- Col >= Size, !.
print_cols(Board, Row, Col, Size) :-
    get_cell(Board, Row, Col, Cell), cell_symbol(Cell, Sym),
    write(Sym), Next is Col + 1, print_cols(Board, Row, Next, Size).

% ==========================================
%  MOVES ENGINE
% ==========================================
is_path_clear(Board, R, C1, R, C2) :-
    C1 \= C2, MinC is min(C1, C2) + 1, MaxC is max(C1, C2) - 1,
    forall(between(MinC, MaxC, C), get_cell(Board, R, C, e)).

is_path_clear(Board, R1, C, R2, C) :-
    R1 \= R2, MinR is min(R1, R2) + 1, MaxR is max(R1, R2) - 1,
    forall(between(MinR, MaxR, R), get_cell(Board, R, C, e)).

is_accessible(k, _, _) :- !.
is_accessible(_, R, C) :- \+ corner(R, C), \+ throne(R, C).

valid_move(Board, move(FR, FC, TR, TC), Piece) :-
    get_cell(Board, FR, FC, Piece), Piece \= e,
    get_cell(Board, TR, TC, e),
    is_path_clear(Board, FR, FC, TR, TC),
    is_accessible(Piece, TR, TC).

% move/4: returns move term + resulting state
move([Player, Board], move(FR,FC,TR,TC), [NextPlayer, NextBoard]) :-
    other_player(Player, NextPlayer),
    nth0(Index, Board, Piece),
    belongs_to(Piece, Player),
    FR is Index // 9, FC is Index mod 9,
    member((DR, DC), [(0,1),(0,-1),(1,0),(-1,0)]),
    slide_piece(Board, Piece, FR, FC, DR, DC, TR, TC),
    update_board(Board, move(FR, FC, TR, TC), NextBoard).

slide_piece(Board, Piece, R, C, DR, DC, TR, TC) :-
    NR is R + DR, NC is C + DC,
    between(0, 8, NR), between(0, 8, NC),
    get_cell(Board, NR, NC, e),
    is_accessible(Piece, NR, NC),
    ( (TR = NR, TC = NC) ; slide_piece(Board, Piece, NR, NC, DR, DC, TR, TC) ).

other_player(a, d). other_player(d, a).
belongs_to(a, a).   belongs_to(d, d). belongs_to(k, d).
opponent_of(a, d).  opponent_of(a, k).
opponent_of(d, a).  opponent_of(k, a).

update_board(Board, move(FR, FC, TR, TC), NewBoard) :-
    get_cell(Board, FR, FC, Piece),
    set_cell(Board, FR, FC, e, B1),
    set_cell(B1, TR, TC, Piece, B2),
    apply_captures(B2, TR, TC, NewBoard).

apply_captures(Board, R, C, FinalBoard) :-
    get_cell(Board, R, C, Mover),
    opponent_of(Mover, Opponent),
    check_capture(Board, R, C,  0,  1, Opponent, Mover, B1),
    check_capture(B1,   R, C,  0, -1, Opponent, Mover, B2),
    check_capture(B2,   R, C,  1,  0, Opponent, Mover, B3),
    check_capture(B3,   R, C, -1,  0, Opponent, Mover, B4),
    FinalBoard = B4.

check_capture(Board, R, C, DR, DC, Opponent, Mover, NewBoard) :-
    R_Opp  is R + DR,   C_Opp  is C + DC,
    R_Next is R + 2*DR, C_Next is C + 2*DC,
    between(0, 8, R_Opp),  between(0, 8, C_Opp),
    between(0, 8, R_Next), between(0, 8, C_Next),
    get_cell(Board, R_Opp,  C_Opp,  Opponent),
    get_cell(Board, R_Next, C_Next, NextPiece),
    ( (belongs_to(NextPiece, MT), belongs_to(Mover, MT)) ; hostile(R_Next, C_Next) ),
    set_cell(Board, R_Opp, C_Opp, e, NewBoard), !.
check_capture(Board, _, _, _, _, _, _, Board).

% ==========================================
%  WIN CONDITIONS
% ==========================================
is_winner(Board, d) :- 
findall(_, member(a, Board), As), 
length(As, Anum),
(Anum = 0);
(corner(R, C), 
get_cell(Board, R, C, k)), !.

is_winner(Board, a) :-
findall(_, member(a, Board), As), length(As, Anum),
findall(_, member(d, Board), Ds), length(Ds, Dnum),
(Dnum = 0 , Anum >= 4);
(find_king(Board, R, C), is_king_captured(Board, R, C)), !.

find_king(Board, R, C) :-
    nth0(Index, Board, k), R is Index // 9, C is Index mod 9.

is_king_captured(Board, R, C) :-
    check_king_side(Board, R, -1, C,  0),
    check_king_side(Board, R,  1, C,  0),
    check_king_side(Board, R,  0, C, -1),
    check_king_side(Board, R,  0, C,  1).

check_king_side(Board, R, DR, C, DC) :-
    NR is R + DR, NC is C + DC,
    ( \+ (between(0, 8, NR), between(0, 8, NC))
    ; get_cell(Board, NR, NC, a)
    ; hostile(NR, NC) ).

% ==========================================
%  HISTORY
% ==========================================
clear_history :-
    retractall(history(_)),
    retractall(last_moves(_)),
    assertz(last_moves([])).

add_board(Board)   :- assertz(history(Board)).
visited(Board)     :- history(Board).

record_move(FR-FC-TR-TC) :-
    retract(last_moves(Old)),
    append(Old, [FR-FC-TR-TC], New),
    ( length(New, L), L > 8 -> New = [_|Trimmed] ; Trimmed = New ),
    assertz(last_moves(Trimmed)).

repeated_move(FR-FC-TR-TC) :-
    last_moves(Moves),
    include(=(FR-FC-TR-TC), Moves, Hits),
    length(Hits, N), N >= 2.

fresh(move(FR,FC,TR,TC)-[_,Board]) :-
    \+ visited(Board),
    \+ repeated_move(FR-FC-TR-TC).

% ==========================================
%  UTILITY — improved heuristic
% ==========================================
utility([_, Board], Val) :-
    ( is_winner(Board, d) -> Val = 100000
    ; is_winner(Board, a) -> Val = -100000
    ;
        % 1. Piece counts
        findall(_, member(d, Board), Ds), length(Ds, Dnum),
        findall(_, member(a, Board), As), length(As, Anum),
        PieceScore is (Anum - Dnum) * 50,

        % 2. King distance to nearest corner (defenders want small, attackers want large)
        find_king(Board, KR, KC),
        D1 is abs(KR-0) + abs(KC-0),
        D2 is abs(KR-0) + abs(KC-8),
        D3 is abs(KR-8) + abs(KC-0),
        D4 is abs(KR-8) + abs(KC-8),
        min_list([D1,D2,D3,D4], MinDist),
        KingDistScore is (16 - MinDist) * 150,

        % 3. How surrounded is the king? (attackers want high)
        count_king_threats(Board, KR, KC, Threats),
        ThreatScore is Threats * 200,

        % 4. Attacker proximity to king (attackers want close)
        attacker_proximity_score(Board, KR, KC, ProxScore),

        % 5. Small random noise to break ties between equal moves
        random_between(0, 9, Noise),

        Val is PieceScore + KingDistScore + ThreatScore + ProxScore + Noise
    ).

% Count how many sides of the king are occupied by attackers or hostile squares
count_king_threats(Board, R, C, N) :-
    Sides = [(-1,0),(1,0),(0,-1),(0,1)],
    include([DR-DC]>>(
        NR is R+DR, NC is C+DC,
        ( \+(between(0,8,NR)) ; \+(between(0,8,NC))
        ; get_cell(Board,NR,NC,a)
        ; hostile(NR,NC) )
    ), Sides, Threatened),
    length(Threatened, N).

% Sum of (14 - manhattan_dist) for each attacker toward king
attacker_proximity_score(Board, KR, KC, Score) :-
    findall(S, (
        nth0(Idx, Board, a),
        AR is Idx // 9, AC is Idx mod 9,
        Dist is abs(AR - KR) + abs(AC - KC),
        S is max(0, 14 - Dist)
    ), Scores),
    sumlist(Scores, Score).

% ==========================================
%  AI: ALPHA-BETA
% ==========================================
getLevel(easy,   1).
getLevel(medium, 2).
getLevel(hard,   3).

alphabeta(D, [_,Board], _, _, none, Val) :-
    (D =< 0 ; is_winner(Board, _)), !,
    utility([nil, Board], Val).

alphabeta(Depth, [Player, Board], Alpha, Beta, Best, Val) :-
    Depth > 0,
    findall(M-S, move([Player, Board], M, S), All),
    ( All = [] ->
        utility([Player, Board], Val), Best = none
    ;
        % Shuffle to randomize move order → different choices on equal scores
        random_permutation(All, Shuffled),
        include(fresh, Shuffled, Fresh),
        ( Fresh \= [] -> Candidates = Fresh ; Candidates = Shuffled ),
        limit_list(Candidates, 15, Capped),
        NewDepth is Depth - 1,
        ( Player = d ->
            eval_max(NewDepth, Capped, Alpha, Beta, none, -1000001, Best, Val)
        ;
            eval_min(NewDepth, Capped, Alpha, Beta, none,  1000001, Best, Val)
        )
    ).

eval_max(_, [], _, _, BM, BV, BM, BV) :- !.
eval_max(D, [M-S|Rest], Alpha, Beta, CurrM, CurrV, FinalM, FinalV) :-
    alphabeta(D, S, Alpha, Beta, _, Val),
    ( Val > CurrV -> NextM = M, NextV = Val ; NextM = CurrM, NextV = CurrV ),
    NewAlpha is max(Alpha, NextV),
    ( NewAlpha >= Beta ->
        FinalM = NextM, FinalV = NextV, !
    ;
        eval_max(D, Rest, NewAlpha, Beta, NextM, NextV, FinalM, FinalV)
    ).

eval_min(_, [], _, _, BM, BV, BM, BV) :- !.
eval_min(D, [M-S|Rest], Alpha, Beta, CurrM, CurrV, FinalM, FinalV) :-
    alphabeta(D, S, Alpha, Beta, _, Val),
    ( Val < CurrV -> NextM = M, NextV = Val ; NextM = CurrM, NextV = CurrV ),
    NewBeta is min(Beta, NextV),
    ( Alpha >= NewBeta ->
        FinalM = NextM, FinalV = NextV, !
    ;
        eval_min(D, Rest, Alpha, NewBeta, NextM, NextV, FinalM, FinalV)
    ).

limit_list(List, N, Limited) :-
    length(List, L),
    ( L > N -> length(Limited, N), append(Limited, _, List) ; Limited = List ).

% ==========================================
%  GAME LOOP
% ==========================================
startGame :-
    clear_history,
    write('--- HNEFATAFL: TABLUT ---'), nl,
    write("Do you want d (defenders) or a (attackers)? "), read(Human),
    write("Level (easy/medium/hard)? "), read(Level),
    initial_board(Board),
    add_board(Board),
    other_player(Human, Computer),
    ( Human = a ->
        play(Level, [Human, Board], human)
    ;
        play(Level, [Computer, Board], computer)
    ).

play(_, [_, Board], _) :-
    is_winner(Board, Winner), !,
    print_board(Board),
    format('~n*** Game Over! Winner: ~w ***~n', [Winner]).

play(Level, [Comp, Board], computer) :-
    print_board(Board),
    format('Computer (~w) is thinking...~n', [Comp]),
    getLevel(Level, Depth),
    alphabeta(Depth, [Comp, Board], -1000000, 1000000, BestMove, _),
    ( BestMove = none ->
        format('Computer (~w) has no valid moves. Draw!~n', [Comp])
    ;
        BestMove = move(FR, FC, TR, TC),
        record_move(FR-FC-TR-TC),
        update_board(Board, move(FR,FC,TR,TC), NextBoard),
        add_board(NextBoard),
        other_player(Comp, Human),
        play(Level, [Human, NextBoard], human)
    ).

play(Level, [Human, Board], human) :-
    print_board(Board),
    format("Your turn (~w). Enter move as FR-FC-TR-TC: ", [Human]), nl,
    read(FR-FC-TR-TC),
    ( (valid_move(Board, move(FR, FC, TR, TC), P), belongs_to(P, Human)) ->
        update_board(Board, move(FR, FC, TR, TC), NB),
        add_board(NB),
        other_player(Human, Comp),
        play(Level, [Comp, NB], computer)
    ;
        write('Invalid move! Try again.'), nl,
        play(Level, [Human, Board], human)
    ).
