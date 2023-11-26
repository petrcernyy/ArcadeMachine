function [vecOfPossib] = enterPossib(sudoku, n)
row = rem(n, length(sudoku));
if row == 0
    row = length(sudoku);
end
col = ceil(n/length(sudoku));
vecOfPossib = 1:9 ;

%prohleda sloupec
for i = 1:length(sudoku)
    if ~isempty(sudoku{i, col}) && length(sudoku{i,col}) == 1
        idx = find(vecOfPossib == cell2mat(sudoku(i, col)));
        vecOfPossib(idx) = [];
    end
end
    
%prohleda radek
for i = 1:length(sudoku)
    if ~isempty(sudoku{row, i}) && length(sudoku{row, i}) == 1
        idx = find(vecOfPossib == cell2mat(sudoku(row, i)));
        vecOfPossib(idx) = [];
    end
end
    
%prohleda ctverec 3x3

rowL = (ceil(row/3))*3 -2; % dolni hranice radku
rowH = (ceil(row/3))*3 ;     %horni hranice radku

colL = (ceil(col/3))*3-2;
colH = (ceil(col/3))*3;
    
square = sudoku([rowL:rowH] , [colL:colH]);

for i = 1:(length(square))^2
    if  ~isempty(square{i}) && length(square{i}) == 1
        idx = find(vecOfPossib == cell2mat(square(i)));
        vecOfPossib(idx) = [];
        
        
    end
    
end
    
end
