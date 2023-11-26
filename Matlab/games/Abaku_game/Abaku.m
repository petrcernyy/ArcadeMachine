classdef Abaku < handle
    properties
        VelikostPole = 7;
        Pole
    end
    methods
        function this = Abaku()

            this.vytvoritPole();
            
        end
        function vytvoritPole(this)
            this.Pole = NaN(this.VelikostPole);
        end
        function nastavHodnotuNaPozici(this,radek,sloupec,hodnota)
            this.Pole(sloupec,radek) = hodnota;
            this.skontrolujVypocet();
        end
        function skontrolujVypocet(this)
            this
            
        end
    end
end