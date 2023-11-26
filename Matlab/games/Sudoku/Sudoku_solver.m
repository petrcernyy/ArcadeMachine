%>>> SUDOKU SOLVER 3000 <<<

sudokuWPossib = lookForEmptyBoxes(sudoku); %najde prazdna mista a doplni vsechny moznosti
sudokuWLastPossib = lookForFullBoxes(sudokuWPossib); %odstrani jasne moznosti
sudokuWNonSpecPossib = deleteLastSpecPossib(sudokuWLastPossib); % zjisti jestli se ve zbylych moznostech nachazi samotne cislo
finalSudoku = deleteLastPossib(sudokuWNonSpecPossib) %vysledek
