function [numInBox] = deleteOtherPossib(sudoku,i)

row = rem(i, length(sudoku));
if row == 0
    row = length(sudoku);
end
col = ceil(i/length(sudoku));

numInBox = sudoku{row, col};

%prohleda sloupec
for i = 1:length(sudoku)
    if length(sudoku{i,col}) == 1
        idx = find(numInBox == cell2mat(sudoku(i, col)));
        numInBox(idx) = [];
        
        
    end
end
    
%prohleda radek
for i = 1:length(sudoku)
     if length(sudoku{row, i}) == 1
        idx = find(numInBox == cell2mat(sudoku(row, i)));
        numInBox(idx) = [];

    end
end
    
%prohleda ctverec 3x3

rowL = (ceil(row/3))*3 -2; % dolni hranice radku
rowH = (ceil(row/3))*3 ;     %horni hranice radku

colL = (ceil(col/3))*3-2;
colH = (ceil(col/3))*3;
    
square = sudoku([rowL:rowH] , [colL:colH]);

for i = 1:(length(square))^2
    if  length(square{i}) == 1
        idx = find(numInBox == cell2mat(square(i)));
        numInBox(idx) = [];
        
        
    end
    
end

end

