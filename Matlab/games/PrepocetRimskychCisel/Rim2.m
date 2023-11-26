
function [v] = Rim2(x)
 if x<1
   v = 'cislo musi byt od 1 do 20'
 elseif x > 20
   v = 'cislo musi byt od 1 do 20'
   
   else
y = {'I' 'II' 'III' 'IV' 'V' 'VI' 'VII' 'VIII' 'IX' 'X' 'XI' 'XII' 'XIII' 'XIV' 'XV' 'XVI' 'XVII' 'XVIII' 'XIX' 'XX'};
v = y{x};
end



endfunction
