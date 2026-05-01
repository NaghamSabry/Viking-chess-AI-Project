
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


apply_captures(Board, _MoverRow, _MoverCol, Board).

