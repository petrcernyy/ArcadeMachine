% Funkce kontrolujici, zda zadany stav do metody novaHra tridy HraciPole
% je bud "prubeh" nebo "konec"

function musiBytStav(stav)
    if stav == "prubeh" || stav == "konec"
        
    else
        error("Zadany stav musi byt bud prubeh nebo konec")
    end   
end