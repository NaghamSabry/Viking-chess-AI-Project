

board_size(9). 


throne(4, 4).      

corner(0, 0).
corner(0, 8).
corner(8, 0).
corner(8, 8).

%% consider to be a hositle place if(A D Corner) or (A Thrown D A) => the D will die 
hostile(R, C) :- throne(R, C).
hostile(R, C) :- corner(R, C).

%% instead of dealing with (R,C) deal with index
index_of(Row, Col, Size, Index) :-
    Index is Row * Size + Col.

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
    I > 0,
    I1 is I - 1,
    replace_nth0(I1, T, Elem, T2).

initial_board(Board) :-
    board_size(Size),
    TotalCells is Size * Size,
    length(EmptyBoard, TotalCells),
    maplist(=(e), EmptyBoard),          
    place_pieces(EmptyBoard, Board).

place_pieces(B0, Board) :-

   %% put king
    set_cell(B0,  4, 4, k, B1),

    %% put 12 defenders     
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

    %% put 24 attackers
     
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
    set_cell(B28, 4, 7, a, B29),
    set_cell(B29, 0, 4, a, B30),   
    
    Board = B29.     % use B29 (new board)


cell_symbol(e, ' . ').
cell_symbol(k, ' K ').
cell_symbol(d, ' D ').
cell_symbol(a, ' A ').


print_board(Board) :-
    board_size(Size),
    nl,
    print_col_header(Size),
    print_rows(Board, 0, Size),
    nl.


print_col_header(Size) :-
    write('     '),
    forall(between(0, Size, C),
           ( Disp is C, format('~w  ', [Disp]) )),
    nl,
    write('   +'),
    forall(between(0, Size, _), write('---')),
    write('+'), nl.

print_rows(_, Row, Size) :- Row >= Size, !.

print_rows(Board, Row, Size) :-
    format('~w  | ', [Row]),
    print_cols(Board, Row, 0, Size),
    write('|'), nl,
    Next is Row + 1,
    print_rows(Board, Next, Size).


print_cols(_, _, Col, Size) :- Col >= Size, !.

print_cols(Board, Row, Col, Size) :-
    get_cell(Board, Row, Col, Cell),
    cell_symbol(Cell, Sym),
    write(Sym),
    Next is Col + 1,
    print_cols(Board, Row, Next, Size).


update_board(Board, move(FR, FC, TR, TC), NewBoard) :-
    get_cell(Board, FR, FC, Piece),   
    Piece \= e,                        
    set_cell(Board,  FR, FC, e,     B1),   
    set_cell(B1,     TR, TC, Piece, B2),   
    apply_captures(B2, TR, TC, NewBoard).  


%apply_captures(Board, _MoverRow, _MoverCol, Board).





% ==========================================
%  RULES & MOVES ENGINE 
% ==========================================

% --- 1. Movement Logic (Rook Style) ---

% Checks if the horizontal or vertical path between two points is empty
is_path_clear(Board, R, C1, R, C2) :- 
    C1 \= C2,
    MinC is min(C1, C2) + 1,
    MaxC is max(C1, C2) - 1,
    forall(between(MinC, MaxC, C), (get_cell(Board, R, C, e))).

is_path_clear(Board, R1, C, R2, C) :- 
    R1 \= R2,
    MinR is min(R1, R2) + 1,
    MaxR is max(R1, R2) - 1,
    forall(between(MinR, MaxR, R), (get_cell(Board, R, C, e))).

% Main move validation
valid_move(Board, move(FR, FC, TR, TC), Piece) :-
    get_cell(Board, FR, FC, Piece),
    Piece \= e,
    get_cell(Board, TR, TC, e), 
    is_path_clear(Board, FR, FC, TR, TC),
    % Only the King can stop on Throne or Corners
    (Piece = k ; \+ hostile(TR, TC)).

move([Player, Board], [NextPlayer, NextBoard]) :-
    other_player(Player, NextPlayer),
    % Find any piece belonging to the current player
    nth0(Index, Board, Piece),
    belongs_to(Piece, Player),
    FR is Index // 9, FC is Index mod 9,
    % Find a valid destination
    between(0, 8, TR), between(0, 8, TC),
    valid_move(Board, move(FR, FC, TR, TC), Piece),
    update_board(Board, move(FR, FC, TR, TC), NextBoard).

other_player(a, d).
other_player(d, a).   

% --- 2. Capture Logic (Sandwich/Custodial) ---

% Defines opponents (Note: King is unarmed and doesnt initiate captures)
opponent_of(a, d). 
opponent_of(a, k). 
opponent_of(d, a). 

% Applies captures in all 4 directions after a move
apply_captures(Board, R, C, FinalBoard) :-
    get_cell(Board, R, C, Mover),
    opponent_of(Mover, Opponent),
    check_capture(Board, R, C, 0, 1, Opponent, Mover, B1), 
    check_capture(B1, R, C, 0, -1, Opponent, Mover, B2),   
    check_capture(B2, R, C, 1, 0, Opponent, Mover, B3),    
    check_capture(B3, R, C, -1, 0, Opponent, Mover, B4),   
    FinalBoard = B4.

% Core sandwich logic: Piece is captured if between Mover and (Friend or Hostile place)
check_capture(Board, R, C, DR, DC, Opponent, Mover, NewBoard) :-
    R_Opp is R + DR, C_Opp is C + DC,
    R_Next is R + 2*DR, C_Next is C + 2*DC,
    between(0, 8, R_Opp), between(0, 8, C_Opp),
    between(0, 8, R_Next), between(0, 8, C_Next),
    get_cell(Board, R_Opp, C_Opp, Opponent),
    get_cell(Board, R_Next, C_Next, NextPiece),
    (NextPiece = Mover ; hostile(R_Next, C_Next)),
    set_cell(Board, R_Opp, C_Opp, e, NewBoard), !.

check_capture(Board, _, _, _, _, _, _, Board).

% --- 3. Winning Conditions ---

% Defenders win if the King reaches any corner
is_winner(Board, d) :-
    corner(R, C),
    get_cell(Board, R, C, k), !.

% Attackers win if the King is captured (surrounded)
is_winner(Board, a) :-
    find_king(Board, R, C),
    is_king_captured(Board, R, C), !.

% Helper to locate the King
find_king(Board, R, C) :-
    board_size(Size),
    MaxIndex is Size * Size - 1,
    between(0, MaxIndex, Index),
    nth0(Index, Board, k),
    R is Index // Size,
    C is Index mod Size.

% King is captured if all 4 adjacent sides are blocked by (Attackers, Board Edge, or Throne)
is_king_captured(Board, R, C) :-
    check_king_side(Board, R, -1, C, 0), 
    check_king_side(Board, R, 1, C, 0),  
    check_king_side(Board, R, 0, C, -1), 
    check_king_side(Board, R, 0, C, 1).  

check_king_side(Board, R, DR, C, DC) :-
    NR is R + DR, NC is C + DC,
    ( \+ (between(0, 8, NR), between(0, 8, NC)) ; 
      get_cell(Board, NR, NC, a) ;                
      hostile(NR, NC)                             
    ).


belongs_to(a, a).
belongs_to(d, d).
belongs_to(k, d).


startGame :-
    write('--- HNEFATAFL: TABLUT VARIANT ---'), nl,
    write("Do you want d or a?"), nl,
    read(Human),
    write("Choose the Level (easy-medium-hard)-> "),
    read(Level),
    initial_board(Board),
    play(Level,[Human, Board],human).

play(_,[_, Board],_) :-
    is_winner(Board, Winner), !,
    print_board(Board),
    format('~n*** GAME OVER! Winner: ~w ***~n', [Winner]).

play(Level,[Computer, Board],computer) :-
    print_board(Board),
    format('~nComputer turn: ~w~n', [Computer]), nl,
    getLevel(Level, Depth), 
    alphabeta(Depth, [Computer, Board], -1000, 1000, [_, NextBoard], _),
    other_player(Computer,Human),
    play(Level,[Human, NextBoard],human).

play(Level,[Human, Board],human) :-
    print_board(Board),
    format('~nYour turn: ~w~n', [Human]), nl,
    write('Format: FR-FC-TR-TC. (e.g., 4-3-4-0.)'), nl,
    read(FR-FC-TR-TC),
    ( (valid_move(Board, move(FR, FC, TR, TC), Piece), belongs_to(Piece, Human)) ->
        update_board(Board, move(FR, FC, TR, TC), NextBoard),
        other_player(Human,Computer),
        play(Level,[Computer, NextBoard],computer)
    ; 
        write('Invalid move or not your piece! Try again.'), nl,
        play(Level,[Human, Board],human)
    ).
isMinPlayer([a,_]).

getLevel(easy,1).
getLevel(medium,3).
getLevel(hard,5).

alphabeta(0,[_,Board], _, _, _, Val):-
utility(Board,Val),!.

alphabeta(_,[_,Board], _, _, _, Val):-
is_winner(Board,_),!,
utility(Board,Val).


alphabeta(Depth,Pos, Alpha, Beta, BestNextPos, Val):-
Ndepth is Depth-1 ,
bagof(NextBoard, move(Pos,NextBoard), NewBoardList),
NewBoardList \= [], !,
best(Ndepth,NewBoardList, Alpha, Beta, BestNextPos, Val), !.

alphabeta(_, [_,Board], _, _, _, Val) :-
    utility(Board, Val).

best(Depth,[Pos], Alpha, Beta, Pos, Val):-
alphabeta(Depth,Pos, Alpha, Beta, _, Val), !.

best(Depth,[Pos1 | Tail], Alpha, Beta, BestPos, BestVal) :-
alphabeta(Depth,Pos1, Alpha, Beta, _, Val1),
updateValues(Pos1, Val1, Alpha, Beta, NewAlpha, NewBeta),
best(Depth,Tail, NewAlpha, NewBeta, Pos2, Val2),
betterOf(Pos1, Val1, Pos2, Val2, BestPos, BestVal).

updateValues(Pos1, Value, Alpha, Beta, NewAlpha, Beta):-
isMinPlayer(Pos1), !,
(Value > Alpha -> (NewAlpha is Value, !)
; NewAlpha is Alpha

).
updateValues(_, Value, Alpha, Beta, Alpha, NewBeta):-
(Value < Beta -> (NewBeta is Value, !)
; NewBeta is Beta

).
betterOf(Pos1, Val1, Pos2, Val2, BestPos, BestVal) :-
isMinPlayer(Pos1),
(Val1 >= Val2 -> (BestPos = Pos1, BestVal is Val1, !)
; (BestPos = Pos2, BestVal is Val2)

), !.
betterOf(Pos1, Val1, Pos2, Val2, BestPos, BestVal) :-
(Val1 =< Val2 -> (BestPos = Pos1, BestVal is Val1, !)
; (BestPos = Pos2, BestVal is Val2)

), !.


utility(Board, Val) :-
    is_winner(Board, d), !,
    Val = 1000.
utility(Board, Val) :-
    is_winner(Board, a), !,
    Val = -1000. 
utility(Board, Val) :-
    findall(_, member(d, Board), Defs), length(Defs, Dnum),
    findall(_, member(a, Board), Atts), length(Atts, Anum),
    find_king(Board, KR, KC),
    king_safety_score(KR, KC, Safety),
    Val is (Dnum * 2) - (Anum) + Safety.

king_safety_score(R, C, Score) :-
    DistR is min(R, 8 - R),
    DistC is min(C, 8 - C),
    Score is 10 - (DistR + DistC).



    