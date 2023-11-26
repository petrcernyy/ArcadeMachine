
function [ans] = Rim3 (x)
a = 0
  if (1<=x) && (x<=9)
    a = 1
  end 

  if (10<=x) && (x<=19)
    a = 2
  end
  
  if (20<=x) && (x<=29)
    a = 3
  end
  
    if (30<=x) && (x<=39)
    a = 4
  end
  
    if (40<=x) && (x<=49)
    a = 5
  end
  
    if (50<=x) && (x<=59)
    a = 6
  end
  
    if (60<=x) && (x<=69)
    a = 7
  end
  
  if x > 69
    a = 100
    end   

  if x < 1
    a = 0
 end
 
 
 switch a
   
   case 0
     ans = 'Zaporne cislo'
     
   case 1 
     
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
        end
        ans = v 
   
   case 2
     y = x - 10
         if y == 0
            v = ''
         elseif y ==1
            v = 'I'
         elseif y==2
            v = 'II'
         elseif y ==3
            v = 'III'
         elseif y == 4
            v = 'IV'
         elseif y ==5
            v = 'V'
         elseif y == 6
            v = 'VI'
         elseif y == 7
            v = 'VII' 
         elseif y == 8
            v = 'VIII'
         elseif y == 9
            v = 'IX' 
        end
        %bohužel nevím, jak zaøídit, aby se výsledek psal za sebe, takhle
        % se píše aspoò pod sebe
        b = 'X'
        ans = {b,v}
                
        
   case 3
     
     y = x - 20 
         if y == 0
           v = ''
         elseif y == 0
            v = ''
         elseif y ==1
            v = 'I'
         elseif y==2
            v = 'II'
         elseif y ==3
            v = 'III'
         elseif y == 4
            v = 'IV'
         elseif y ==5
            v = 'V'
         elseif y == 6
            v = 'VI'
         elseif y == 7
            v = 'VII' 
         elseif y == 8
            v = 'VIII'
         elseif y == 9
            v = 'IX' 
        end  
       b = 'XX'
       ans = {b,v}
       
   case 4
     
     y = x - 30     
         if y == 0
            v = ''
         elseif y ==1
            v = 'I'
         elseif y==2
            v = 'II'
         elseif y ==3
            v = 'III'
         elseif y == 4
            v = 'IV'
         elseif y ==5
            v = 'V'
         elseif y == 6
            v = 'VI'
         elseif y == 7
            v = 'VII' 
         elseif y == 8
            v = 'VIII'
         elseif y == 9
            v = 'IX' 
        end  
       b = 'XXX'
       ans = {b,v}
       
   case 5
     
     y = x - 40   
         if y == 0
            v = ''
         elseif y ==1
            v = 'I'
         elseif y==2
            v = 'II'
         elseif y ==3
            v = 'III'
         elseif y == 4
            v = 'IV'
         elseif y ==5
            v = 'V'
         elseif y == 6
            v = 'VI'
         elseif y == 7
            v = 'VII' 
         elseif y == 8
            v = 'VIII'
         elseif y == 9
            v = 'IX' 
        end  
       b = 'XL'
       ans = {b,v}
  
  case 6
     y = x - 50   
         if y == 0
            v = ''
         elseif y ==1
            v = 'I'
         elseif y==2
            v = 'II'
         elseif y ==3
            v = 'III'
         elseif y == 4
            v = 'IV'
         elseif y ==5
            v = 'V'
         elseif y == 6
            v = 'VI'
         elseif y == 7
            v = 'VII' 
         elseif y == 8
            v = 'VIII'
         elseif y == 9
            v = 'IX' 
        end  
       b = 'L'
       ans = {b,v}
     
      
      
      
     
    
    case 100
    ans = 'cislo je prilis vysoke'
    
 end



end
