function [sudokuWNonSpecPossib] = deleteLastSpecPossib(sudokuWLastPossib)
change = 1;
i = 0;
changeCounter = 0;
while change == 1;
    i = i+1;
    
    if length(sudokuWLastPossib{i}) > 1
        
      
            row = rem(i, length(sudokuWLastPossib));
            if row == 0
                row = length(sudokuWLastPossib);
            end
            col = ceil(i/length(sudokuWLastPossib));
            
            cell = cell2mat(sudokuWLastPossib(row,col));
            
            
            sudokuWLastPossib{row,col} = 0;
            rowVec = cell2mat(sudokuWLastPossib(row,:));
            colVec = cell2mat(rot90(sudokuWLastPossib(: , col)));
            
            
            
            rowL = (ceil(row/3))*3 -2; % dolni hranice radku
            rowH = (ceil(row/3))*3 ;     %horni hranice radku

            colL = (ceil(col/3))*3-2;
            colH = (ceil(col/3))*3;

            square = sudokuWLastPossib([rowL:rowH] , [colL:colH]);
            sqVec = [cell2mat(square(1,:)),cell2mat(square(2,:)),cell2mat(square(3,:)) ];
            
            
            if any(ismember(cell,rowVec)<1)
               idx = find(ismember(cell,rowVec)<1);
               sudokuWLastPossib{row,col} = cell(idx);
               changeCounter = 1;
               
            elseif any(ismember(cell,colVec)<1)
                idx = find(ismember(cell,colVec)<1);
                sudokuWLastPossib{row,col} = cell(idx);
                changeCounter = 1;
                
            elseif any(ismember(cell,sqVec)<1)
                idx = find(ismember(cell,sqVec)<1);
                sudokuWLastPossib{row,col} = cell(idx);
                changeCounter = 1;
            else
                
                sudokuWLastPossib{row,col} = cell;
                changeCounter = 0;

            end
            
           
            
    end
     
    
        if i >= (length(sudokuWLastPossib))^2
           i = 0;
           if changeCounter == 0
              change = 0;
           else 
               changeCounter = 0;  
               change = 1;
               sudokuWLastPossib = lookForFullBoxes(sudokuWLastPossib);
           end


        end


end

sudokuWNonSpecPossib = sudokuWLastPossib;
end
