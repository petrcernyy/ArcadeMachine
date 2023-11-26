function [sudoku] = lookForEmptyBoxes(sudoku)


for n = 1:(length(sudoku))^2
    if isempty(sudoku{n})
        
       vecOfPossib = enterPossib(sudoku, n);
       sudoku{n} = vecOfPossib;
       clear vecOfPossib;
       
        
    end
    
end

end

