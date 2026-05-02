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

% --- 2. Capture Logic (Sandwich/Custodial) ---

% Defines opponents (Note: King is unarmed and doesn't initiate captures)
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