function [sudokuWLastPossib] = lookForFullBoxes(sudokuWPossib)
change = 1;
i = 0;
changeCounter = 0;
while change == 1
    i = i+1;
    if length(sudokuWPossib{i}) > 1
       numInBox = deleteOtherPossib(sudokuWPossib, i);
       if length(sudokuWPossib{i}) ~= length(numInBox) || any(sudokuWPossib{i} ~= numInBox)
            sudokuWPossib{i} = numInBox;
            changeCounter = 1;
       end
       
       

    end
        
    
    if i >= (length(sudokuWPossib))^2
       i = 0;
       if changeCounter == 0
          change = 0;
       else 
           changeCounter = 0;  
           change = 1;
       end
       
    
    end
    sudokuWLastPossib = sudokuWPossib;
    
end


end

