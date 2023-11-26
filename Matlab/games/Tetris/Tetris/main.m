clear;
clc;

% launch Tetris
% position [x, y], X size of window, Y size of window, X size of playing field, Y size of playing field (X and Y dimensions of playing field should be equal due to marker being a square tied to X dimensions of playing field and window), maximum update frequency, control keys[move down, drop down, move left, move right, rotate CW, rotate CCW]
TetrisClass([200, 200], 500, 500, 25, 25, 3, ["downarrow", "uparrow", "leftarrow", "rightarrow", "q", "e"]);