% Instance tridy radic zprostredkovava komunikaci mezi tridami Uzivatel
% (GUI) a HraciPole.

classdef Radic < handle

%===PROPERTIES=============================================================

    properties (Access = private)
        % Tvar, ktery chceme umistit na dane pole
        ikona;
        
        %Puvodni ikona pole, kam chce hrac umistit tvar
        puvodniIkona;
        
        % Vodorovna slozka policka, kam chceme umistit dany tvar
        xPos;
        
        % Svisla slozka policka, kam chceme umistit dany tvar
        yPos;
        
        % Cislo reprezentujici dany tvar
        % (s timto cislem je pracovano ve tride HP)
        cislo;
        
        % Informace, zda-li se muze umistit tvar na zadane policko,
        % ci nikoliv
        stav;
        
        % Odkaz na instanci tridy SpravceHry
        SH;
    end %prop1
    
    properties (Constant, Access = private)
        % Odkaz na jedinou instanci vytvorenou tridou Radic
        R = Radic;
    end %prop2
    
    % Konstruktor 
    methods (Access = private)        
        %% Vytvori novou instanci.
        function this = Radic()
            this.SH = SpravceHry;
            this.vynulujInfo();
        end %fc
    end %methods
    
    % Staticka metoda predavajici odkaz na jedinou vytvorenou instanci
    % tridy
    methods (Static, Access = public)
        %% Vrati odkaz na jedinou existujici instanci
        function I = getInstance() 
            I = Radic.R;
        end %fc
    end %methods
    
%===PRISTUPOVE METODY======================================================
    methods (Access = public)
        
 %-----------UKLADANE INFORMACE--------------------------------------------
 
        %% Ulozi informaci o tvaru, na ktery bylo kliknuto a cislu
        % reprezentujici tento tvar pro praci ve tride HP.
        % ikona - obrazek, ktery na dane pole pokladam
        % cislo - cislo prirazene k danemu obrazku, s nimz je pracovano
        % ve tride SP
        function ulozTvar(this, ikona, cislo)
            this.ikona = ikona;
            this.cislo = cislo;
        end %fc
        
        
        %% Po kliknuti na volne tlacitko v Uzivateli ulozi informace o 
        % poloze tlacitka a odesle tuto informaci spolu s ulozenym cislem
        % tirde HP.
        % x - vodorovna souradnice umisteni policka, kam ukladam tvar
        % y - svisla souradnice umisteni policka, kam ukladam tvar
        function ulozPozici(this, ikona, x, y)
            this.puvodniIkona = ikona;
            
            if this.cislo == 0
                this.ikona = this.puvodniIkona;
            end %if
            
            this.xPos = x;
            this.yPos = y;
            this.SH.polozCisloNa(this.cislo, this.xPos, this.yPos);
            this.vynulujInfo();
        end %fc
        
%-----------VRACEJICI INFORMACE--------------------------------------------
        
        %% Vrati informaci uzivateli, zda-li muze umistit tvar na prislusne
        % pole
        function out = getStav(this)
            out = this.SH.oznamInfo();
        end %fc
        
        
        %% Vrati ulozenou ikonu (tvar)
        function out = getIkona(this)
            out = this.ikona;
        end %fc
        
        
        %% Vrati puvodni ikonu policka 
        function out = vratPuvodniIkonu(this)
            out = this.puvodniIkona;
        end %fc
        
        
        %% Vrati indexy, na ktere lze umistit zadany prvek
        function out = vratVolnaPole(this)
            out = this.SH.vratVolneIndexy(this.cislo);
        end %fc
        
        
        %% Vrati indexy, na ktere lze umistit zadany prvek, podle zadaneho
        % cisla
        % cislo - cislo, pro ktere se hledaji volne indexy
        function out = vratVolnaPoleCislo(this, cislo)
            out = this.SH.vratVolneIndexy(cislo);
        end %fc
        
        
        %% Vrati informaci o prubehu hry (prubeh/konec)
        function out = vratPrubehHry(this)
            out = this.SH.oznamStav();
        end %fc
        
        
        %% Vrati informaci, zda je dany hrac skutecne na tahu
        function out = jeNaTahuHrac(this)
            out = this.SH.zkontrolujHrace(this.cislo);
        end %fc
        
        
        %% Vrati aktualni hraci pole
        function out = vratAktHraciPole(this)
            out = this.SH.vratPole();
        end %fc
        
        
%----------OSTATNI---------------------------------------------------------

        %% Zacne novou hru, ve tride SH vynuluje vsehcny prvky matice
        % a ulozi si informaci o "prazdne" ikone
        % ikona - prazdna ikona
        function startKonec(this, slovo)
            this.SH.startKonecHry(slovo);
        end %fc
        
        
        %% Ukonci hru, ve tride SH vynujuje vsechny prvky matice
    end %methods
    
%===SOUKROME METODY========================================================
        
    methods (Access = private)
        
        % Vynuluje ulozene informace o cisle a pozici
        function vynulujInfo(this)
            this.cislo = 0;
            this.xPos  = 0;
            this.yPos  = 0;
        end %fc
    end %methods
end %classdef