% Funkce kontrolujici, zda-li je obdrzene cislo v rozsahu 1 az 4
function musiBytZRozsahu(cislo)
    if cislo < 1 || cislo > 4
        error("Cislo neni v rozsahu 1 az 4")
    end
end