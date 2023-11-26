function [finalSudoku] = deleteLastPossib(sudokuWNonSpecPossib)
rows = [];
cols = [];
cellOfVec = {};
matOfCombs = [];
    for i = 1:(length(sudokuWNonSpecPossib))^2
        if length(sudokuWNonSpecPossib{i})>1
            row = rem(i, length(sudokuWNonSpecPossib));
            if row == 0
                row = length(sudokuWNonSpecPossib);
            end
            col = ceil(i/length(sudokuWNonSpecPossib));
            
            rows(end+1) = row;
            cols(end+1) = col;

           cellOfVec{end +1} = sudokuWNonSpecPossib{i};

        end


    end
   matOfCombs = combvec(cellOfVec{:});
   [r, c] = size(matOfCombs);
   
   decisionMaker = 0;
   
   n = 1;
   while decisionMaker == 0;
       for i = 1:r
           sudokuWNonSpecPossib{rows(i), cols(i)} = matOfCombs(i, n);
           
       end
       
       
       v = 1:9;
       for i = 1:length(sudokuWNonSpecPossib)
           oneOrZero = squareCheck(sudokuWNonSpecPossib);
           if any(ismember(v, cell2mat(sudokuWNonSpecPossib(i,:))) <1) || any(ismember(v, cell2mat(sudokuWNonSpecPossib(:, i))) <1) || oneOrZero ==0; 
               decisionMaker = 0;
               break;
           end
           if i == length(sudokuWNonSpecPossib)
               decisionMaker = 1;
           end
           
         
       end
       n = n+1;
   end
   
   finalSudoku = sudokuWNonSpecPossib;
   
   
   
   
end
   
   
   

