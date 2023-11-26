function [v] = Rim (x)
  
 if x ==1
   v = 'I'
 elseif x==2
   v = 'II'
 elseif x ==3
   v = 'III'
 elseif x == 4
   v = 'IV'
 elseif x ==5
  v = 'V'
 elseif x == 6
  v = 'VI'
elseif x == 7
  v = 'VII'
elseif x == 8
  v = 'VIII'
elseif x == 9
  v = 'IX'
elseif x == 10
  v = 'X'
elseif x > 10
  v = 'cislo od 1 do 10'
elseif x< 1
  v = 'cislo od 1 do 10'
   end
  
endfunction
