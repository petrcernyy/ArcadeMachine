function [oneOrZero] = squareCheck(sudokuWNonSpecPossib)
v = 1:9;
sudokuWNonSpecPossib = mat2cell(sudokuWNonSpecPossib, [3 3 3], [3 3 3]); 
for i = 1:(length(sudokuWNonSpecPossib))^2
    if any(ismember(v,cell2mat(sudokuWNonSpecPossib{i})) <1)
       oneOrZero = 0;
       break;
    end
    if i == (length(sudokuWNonSpecPossib))^2
        oneOrZero = 1;
        break;
    end

    
    
end


end