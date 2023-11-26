% Instance tridy SpravceHry vytvori hraci pole 
% reprezentovane matici 4x4, kde vsechny prvky budou 0. 
% Do tohoto pole budou hraci umistovat cisla predstavujici tvary
% metodou polozCisloNa(cislo, x, y), a pole
% bude kontrolovat, zda nebyla porusena pravidla a zda doslo ke splneni
% podminky ukoncujici hru.
% Po ukonceni hry bude vypsan vyhravajici hrac a do hraciho pole uz dale 
% nebude mozne umistovat dalsi cisla.
% Hrac A bude mit k dispozici cisla (1; 2; 3; 4).
% Hrac B bude mit k dispozici cisla (11; 22; 33; 44).
% Ekvivalentni cisla 1=11, 2=22, 3=33, 4=44.

classdef SpravceHry < handle
    
%===PROPERTIES=============================================================

%-----------KONSTANTNI-----------------------------------------------------
    properties (Constant, Access = private)        
        % Cisla, ktere muze pouzivat pouze hrac A
        hracA    = [1, 2, 3, 4];
        
        % Cisla, ktere muze pouzivat pouze hrac B
        hracB    = [11, 22, 33, 44];
        
        % Indexy prvniho bloku hraciho pole
        indBlokA = [1, 2, 5, 6];
        
        % Indexy druheho bloku hraciho pole
        indBlokB = [9, 10, 13, 14];
        
        % Indexy tretiho bloku hraciho pole
        indBlokC = [3, 4, 7, 8];
        
        % Indexy ctvrteho bloku hraciho pole
        indBlokD = [11, 12, 15, 16];
    end %prop1
    
%----------PROMENE---------------------------------------------------------
    properties (Access = private)
        % Matice reprezentujici hraci pole
        hraciPole;
        
        % Cislo, ktere se chystam ulozit do matice na vybranou pozici
        ukladaneCislo;
        
        % Posledni pouzite nenulove cislo
        predchoziCislo;
        
        % Vodorovná souřadnice ukládaného čísla
        xPos;
        
        % Svislá souřadnice ukládaného čísla
        yPos;
        
        % Uklada si stav hry - prubeh/konec
        stav;
        
        % Uklada si informaci o tom, zda-li muze radic pokracovat ci
        % nikoliv
        info;
        
        % Umoznuje vytvorit pouze jedno vyskakovaci okno
        % Pamatuje si, zda jiz nevyskocilo jedno okno
        okno;
    end %prop2

%===PRISTUPOVE METODY======================================================

    methods (Access = public)
        
        %% Vytvori nove hraci pole (nulovou matici 4x4)
        function this = SpravceHry()
            this.ukladaneCislo  = 100;
            this.predchoziCislo = 100;    
            this.hraciPole      = zeros(4);
            this.stav           = "konec";
            this.info           = "nemuzes";
            this.okno           = "existuje";
        end %fc
        
        
        %% Ulozi cislo na vybranou pozici dle pravidel hry
        % cislo - umistovane cislo
        % ind   - index hraciho pole, kam bude cislo umisteno
        function polozCisloNaInd(this, cislo, ind)
            pozice = this.vratPozici(ind);
            x      = pozice(1);
            y      = pozice(2);
            this.polozCisloNa(cislo, x, y);
        end %fc
        
        
        %% Ulozi cislo na vybranou pozici dle pravidel hry
        % cislo - umistovane cislo
        % x     - vodorovna souradnice umistovaneho cisla
        % y     - svisla souradnice umistovaneho cisla
        function polozCisloNa(this, cislo, x, y)
            
            arguments
                this
                cislo (1, 1) {mustBeInteger}
                x     (1, 1) {mustBeInteger, musiBytZRozsahu(x)}
                y     (1, 1) {mustBeInteger, musiBytZRozsahu(y)}
            end %arg
            
            this.okno = "neexistuje";
            
            if this.stav == "konec"
                this.okno = "existuje";
                this.ulozInfo(this.stav);
                return                  %==========>
            elseif this.stav == "prubeh"
                this.ulozInfo("nemuzes");
          
                out1 = this.zkontrolujPole    (x,  y, cislo);
                out2 = this.kontrolaPoctuCisel(cislo);
                out3 = this.zkontrolujHrace   (cislo);
                out4 = this.kontroly          (); % Zkontroluje umisteni cisla
                
                if out1 == "stop" || out2 == "stop" ||...
                   out3 == "stop" || out4 == "stop"
               
                    return              %==========>
                else
                    
                    if this.ukladaneCislo ~= 0
                        this.predchoziCislo = this.ukladaneCislo;
                        this.hraciPole(this.yPos, this.xPos) = this.predchoziCislo;
                    end %if3

                    [~] = this.kontroly(); % Zkontroluje, zda nedoslo k ukonceni hry
                    this.ulozInfo("pokracuj");
                    this.okno = "existuje";
                end %if2
            end % if1
        end %fc
                
        
        %% Pripravi novou hru nebo ukonci hru
        % prepne stav ze stavu "konec" do stavu "prubeh" nebo "konec"
        % a vynuluje vsechny prvky v hracim poli
        % stav - stav hry, muze byt bud "prubeh" nebo "konec"
        function startKonecHry(this, stav)     
            arguments
                this
                stav string {musiBytStav(stav)}
            end %arg
            this.stav = stav;
            this.vynulujPole();
        end %fc        
        
        %% Oznami informaci, zda-li muze radic pokracovat dale co nikoliv
        function out = oznamInfo(this)
            out = this.info;
        end %fc
        
        
        %% Oznami radici stav hry (prubeh/konec)
        function out = oznamStav(this)
            out = this.stav;
        end %fc
        
        
        %% Vrati volne indexy matice, kam lze umistit zadane cislo
        % cislo - cislo, pro ktere mi metoda vrati indexy, kam ho lze
        % umistit
        function out = vratVolneIndexy(this, cislo)
            
            arguments
                this
                cislo (1, 1) {mustBeInteger}
            end %arg
            
            % Prevede zadany tvar na souperuv tvar, podle ktereho
            % budou hledany indexy (napr. 1->11, 33->3)
            if numel(num2str(cislo)) == 1
                 prevedene = str2double(string(cislo) + string(cislo));
            else
                 p = num2str(cislo);
                 prevedene = str2double(p(1));
            end %if
            
            ind          = find(this.hraciPole == prevedene);
            vektorIndexu = 1:16;
            
            for k = 1:numel(ind)
                ind1 = ind(k);
                
                sloupec = this.vratSloupec(ind1);
                radek   = this.vratRadek  (ind1);
                blok    = this.vratBlok   (ind1);
                
                for l = sloupec
                    vektorIndexu(l) = 0;
                end %for 2
                
                for l = radek
                    vektorIndexu(l) = 0;
                end %for2
                
                for l = blok
                    vektorIndexu(l) = 0;
                end %for3

            end %for1
            
            vektorIndexu(vektorIndexu == 0) = [];
            volneIndexy = this.hraciPole(vektorIndexu) == 0;         
            pocet = this.vratPocetCisel(cislo);
            
            if pocet < 2
                out = vektorIndexu(volneIndexy);
            else
                out = [];
            end %if
            
        end %fc
        
        
        %% Zkontroluje, zda hrac pouziva sva cisla
        % cislo - umistovane cislo
        function out = zkontrolujHrace(this, cislo)          
            if this.predchoziCislo <= 4 
                out = this.pomSpravnyHrac(cislo, this.hracB);
            elseif this.predchoziCislo > 4
                out = this.pomSpravnyHrac(cislo, this.hracA);
            end %if          
        end %fc
        
        
        %% Vrati matici reprezentujici hraci pole
        function out = vratPole(this)
            out = this.hraciPole;
        end %fc
        
        
        %% Pokracuje ve hre s hracim polem s danym zaplnenim
        % pole - vkladane hraci pole (matice)
        function hrajNa(this, pole)
            this.hraciPole = pole;
        end %fc
        
        
        %% Ulozi zadane cislo na zadanou pozici, bez kontrol.
        % Tato metoda slouzi pouze k prohledavani do hloubky, ne ke hrani!
        % cislo - ukladane cislo
        % ind   - index pozice v matici, kam se ma cislo ulozit
        function [hp, vyhra] = polozNa(this, cislo, ind)
            arguments
                this
                cislo (1, 1) {mustBeInteger}
                ind   (1, 1) {mustBeInteger}
            end %arg
            this.hraciPole(ind) = cislo;
            this.predchoziCislo = cislo;
            pozice              = this.vratPozici(ind);
            this.xPos           = pozice(1);
            this.yPos           = pozice(2);
            [~, vyhra]          = this.kontroly();
            hp                  = this.vratPole();
        end %fc
        
    end %methods
    
    
%===SOUKROME METODY========================================================

    methods (Access = private)
        
        %% Vynuluje vsechna pole v matici
        function vynulujPole(this)
            for k = 1:numel(this.hraciPole)
                this.hraciPole(k)   = 0;
                this.predchoziCislo = 100;
                this.ukladaneCislo  = 0;
            end %for
        end %fc
        
        
        %% Ulozi informaci radici o tom, zda muze pokracovat
        % stav - informace, zda-li muze radic pokracovat
        %        muze byt bud "muzes" nebo "nemuzes"
        function ulozInfo(this, stav)
            this.info = stav;
        end %fc
        
        
        %% Zkontroluje, zda zadane pole neni obsazene
        % x     - vodorovna souradnice umistovaneho cisla
        % y     - svisla souradnice umistovaneho cisla
        % cislo - umistovane cislo na danou pozici
        function out = zkontrolujPole(this, x, y, cislo)
            
            ulozeneCislo = this.hraciPole(y, x);
            
            if ulozeneCislo == 0 || cislo == 0
                this.xPos = x;
                this.yPos = y;
                out = "dobry";
            else
                out = "stop";
                if this.okno == "neexistuje"
                    this.okno = "existuje";
                    msgbox("Toto pole je jiz obsazene. Vyberte volne pole.",...
                           "Chyba", "error");
                end %if2
            end %if1
        end %fc
        

        %% Zkontroluje, zda pocet stejnych cisel je nejvice 2
        % cislo - umistovane cislo
        function out = kontrolaPoctuCisel(this, cislo)
            pocet = this.vratPocetCisel(cislo);
            
            if pocet >= 2 && cislo ~= 0
                out = "stop";
                if this.okno == "neexistuje"
                    this.okno = "existuje";
                    msgbox("Tvar, ktery chcete pouzit jste jiz pouzil"...
                           + " 2x a dale ho jiz nemuzete pouzivat."...
                           ,"Chyba", "error");
                end %if2
            else
                out = "dobry";
            end %if1
        end %fc
             
        
        %% Zkontroluje, zda nedoslo ke splneni pominek ukonceni hry
        function [out, vyhra] = kontroly(this)
            [out1, vyhra1] = this.kontrolaRadku  ();
            [out2, vyhra2] = this.kontrolaSloupce();
            [out3, vyhra3] = this.kontrolaBloku  ();
            if out1 == "stop" || out2 == "stop" || out3 == "stop"
                out = "stop";    
            else
                out = "dobry";
            end %if1
            
            if vyhra1 == 1 || vyhra2 == 1 || vyhra3 == 1
                vyhra = 1;
            elseif vyhra1 == 2 || vyhra2 == 2 || vyhra3 == 2
                vyhra = 2;
            elseif vyhra1 == 3 || vyhra2 == 3 || vyhra3 == 3
                vyhra = 3;
            else
                vyhra = 0;
            end %if2
        end %fc
        
        
        %% Zkontroluje sloupec dle pravidel hry
        function [out, vyhra] = kontrolaSloupce(this)
            [out, vyhra] = this.pomKontrola("sloupec");
        end %fc
        
        
        %% Zkontroluje radek dle pravidel hry
        function [out, vyhra] = kontrolaRadku(this)
            [out, vyhra] = this.pomKontrola("radek");
        end %fc
        
        
        %% Zkontroluje blok dle pravidel hry
        function [out, vyhra] = kontrolaBloku(this)
            vektor = [this.xPos, this.yPos];
            switch num2str(vektor)
                case '1  1'
                    [out, vyhra] = this.pomKontrola("blok A");
                case '2  1'
                    [out, vyhra] = this.pomKontrola("blok A");
                case '1  2'
                    [out, vyhra] = this.pomKontrola("blok A");
                case '2  2'
                    [out, vyhra] = this.pomKontrola("blok A");
                case '3  1'
                    [out, vyhra] = this.pomKontrola("blok B");
                case '4  1'
                    [out, vyhra] = this.pomKontrola("blok B");
                case '3  2'
                    [out, vyhra] = this.pomKontrola("blok B");
                case '4  2'
                    [out, vyhra] = this.pomKontrola("blok B");
                case '1  3'
                    [out, vyhra] = this.pomKontrola("blok C");
                case '2  3'
                    [out, vyhra] = this.pomKontrola("blok C");
                case '1  4'
                    [out, vyhra] = this.pomKontrola("blok C");
                case '2  4'
                    [out, vyhra] = this.pomKontrola("blok C");
                case '3  3'
                    [out, vyhra] = this.pomKontrola("blok D");
                case '4  3'
                    [out, vyhra] = this.pomKontrola("blok D");
                case '3  4'
                    [out, vyhra] = this.pomKontrola("blok D");
                case '4  4'
                    [out, vyhra] = this.pomKontrola("blok D");
            end %switch
        end %fc
                
%-----------POMOCNE METODY-------------------------------------------------

        %% Pomocna metoda pro kontrolu spravneho hrace
        % cislo - umistovane cislo
        % hrac  - vektor cisel, ktere muze dany hrac pouzivat
        function out = pomSpravnyHrac(this, cislo, hrac)
             
            if sum(hrac == cislo) == 1 || cislo == 0
                this.ukladaneCislo = cislo;
                out = "dobry";
            else
                out = "stop";
                if this.okno == "neexistuje"
                    this.okno = "existuje";
                    slovo = this.vratOpacHrace();
                    msgbox("Na tahu je " + slovo + " hrac."...
                           , "Chyba", "error");
                end %if2
            end %if1
            
        end %fc
        
        
        %% Pomocna metoda pro kontrolu radku a sloupce
        % slovo - slovo, pomoci ktereho se pozna, zda ma metoda
        % zkontrolovat radek, sloupec nebo blok
        % Slova, ktere lze pouzit - "radek", "sloupec", "blok A", 
        % "blok B", "blok C", "blok D"
        function [out, vyhra] = pomKontrola(this, slovo)
            out   = "dobry";
            vyhra = 0;
            switch slovo
                case "radek"
                    vektor = this.hraciPole(this.yPos, :);
                case "sloupec"
                    vektor = this.hraciPole(:, this.xPos);
                case "blok A"
                    vektor = this.hraciPole(this.indBlokA);
                case "blok B"
                    vektor = this.hraciPole(this.indBlokB);
                case "blok C"
                    vektor = this.hraciPole(this.indBlokC);
                case "blok D"
                    vektor = this.hraciPole(this.indBlokD);
            end %switch
            
            if slovo == "blok A" || slovo == "blok B" ...
               || slovo == "blok C" || slovo == "blok D"
           
               slovo = "blok";
            end %if1
            
            prvniCislo = num2str(this.ukladaneCislo);
            
            for k = 1:numel(vektor)
                ulozeneCislo = num2str(vektor(k));
 
                if numel(ulozeneCislo) ~= numel(prvniCislo)
                    if string(ulozeneCislo(1)) == string(prvniCislo(1))
                        out = "stop";
                        
                        if this.okno == "neexistuje"
                            this.okno = "existuje";
                            msgbox("Na tento " + slovo + " nelze umistit zadany tvar,"...
                                   + " protoze vas souper jiz stejny tvar na"...
                                   + " tento " + slovo + " umistil." ...
                                     , "Chyba", "error");
                        end %if3
                        
                          break                 %---------->
                    end %if2
                end %if1
            end %for
            
            if numel(unique(vektor)) == 4 && ...
               sum(vektor == 0) == 0
               this.stav = "konec";
               if this.okno == "neexistuje"
                   this.okno = "existuje";
                   msgbox("Konec hry." + newline + "Vyhrava " ...
                           + this.vratHrace() + " hrac."...
                           +  newline + "Pro novou hru stisknete"...
                           + " tlacitko START, pro ukonceni stisknete" ...
                           + " tlacitko KONEC.", "Vyhra!!!");
               end %if1
                      
               hrac = this.vratHrace();
               switch hrac
                   case "MODRY"
                       vyhra = 1;
                   case "CERVENY"
                       vyhra = 2;
               end %switch
            end %if1
                
            if sum(this.hracA == this.predchoziCislo) == 1
                h = this.hracB;
            else
                h = this.hracA;
            end %if
            
            ind = zeros(1,4);
            for i = 1:numel(h)
                m = this.vratVolneIndexy(h(i));
                if numel(m) ~= 0
                    ind(i) = 1;
                end
            end %for
                
            if sum(ind) == 0
                this.stav = "konec";
                if this.okno == "neexistuje"
                    this.okno = "existuje";
                    msgbox("Konec hry."...
                            + newline + "Doslo k remize."...
                            + newline + "Pro novou hru stisknete tlacitko"...
                            + " START, pro ukonceni hry stisknete tlacitko"...
                            + " KONEC.", "Remiza")
                    vyhra = 3;
                end %if2
            end %if1
        end %fc
    
        
        %% Pomocna metoda vracejici vyhravajiciho hrace
        function hrac = vratHrace(this)
            if numel(num2str(this.predchoziCislo)) == 1
                hrac = "MODRY";
            else
                hrac = "CERVENY";
            end %if
        end %fc
        
        
        %% Vrati opacneho hrace, nez metoda vratHrace()
        function hrac = vratOpacHrace(this)
            h = this.vratHrace();
            if h == "MODRY"
                hrac = "CERVENY";
            else
                hrac = "MODRY";
            end %if
        end %fc
        
        
        %% Vrati sloupec, na kterem lezi zadany index
        % ind - index matice (hraciho pole), podle ktereho ma metoda
        %       vyhledat sloupec, na nemz se index nachazi
        function out = vratSloupec(this, ind)
            
            pozice  = this.vratPozici(ind);
            sloupec = pozice(1);
              
            switch sloupec
                case 1
                    out = [1 2 3 4];
                case 2
                    out = [5 6 7 8];
                case 3
                    out = [9 10 11 12];
                case 4
                    out = [13 14 15 16];
            end %switch
            
        end %fc
        
        
        %% Vrati radek, na kterem lezi zadany index
        % ind - index matice (hraciho pole), podle ktereho ma metoda
        %       vratit radek, na nemz se index nachazi
        function out = vratRadek(this, ind)
            
            pozice = this.vratPozici(ind);
            radek  = pozice(2);
            
            switch radek
                case 1
                    out = [1 5 9 13];
                case 2
                    out = [2 6 10 14];
                case 3
                    out = [3 7 11 15];
                case 4
                    out = [4 8 12 16];
            end %switch
            
        end %fc
        
        
        %% Vrati blok, na kterem lezi zadany index
        % ind - index matice (hraciho pole), podle ktereho ma metoda
        %       vyhledat blok, na nemz se index nachazi
        function out = vratBlok(this, ind)
            
            switch ind
                case 1
                    out = this.indBlokA;
                case 2
                    out = this.indBlokA;
                case 5
                    out = this.indBlokA;
                case 6
                    out = this.indBlokA;
                case 9
                    out = this.indBlokB;
                case 10
                    out = this.indBlokB;
                case 13
                    out = this.indBlokB;
                case 14
                    out = this.indBlokB;
                case 3
                    out = this.indBlokC;
                case 4
                    out = this.indBlokC;
                case 7
                    out = this.indBlokC;
                case 8
                    out = this.indBlokC;
                case 11
                    out = this.indBlokD;
                case 12
                    out = this.indBlokD;
                case 15
                    out = this.indBlokD;
                case 16
                    out = this.indBlokD;
            end %switch
        end %fc
        
        
        %% Vrati pozici (vodorovnou a svislou slozku) policka podle
        % zadaneho indexu
        % index - index matice (hraciho pole), ktery je preveden na 
        %         pozici udanou ve vodorovne (x-ove) slozce a svisle
        %         (y-ove) slozce
        function pozice = vratPozici(~, ind)
            podil  = floor(ind / 4);
            zbytek = rem  (ind,  4);
            
            if zbytek ~= 0
                sloupec = podil + 1;
                radek   = zbytek;
            else
                sloupec = podil;
                radek   = 4;
            end %if1
            
            pozice = [sloupec, radek];
        end %fc
        
        
        %% Secte pocet stejnych prvku v matici (hracim poli)
        % cislo - Cislo, jehoz pocet se hleda
        function pocet = vratPocetCisel(this, cislo)
            pocet = sum(sum(this.hraciPole == cislo));
        end %fc
        
        
    end %methods private
end %classdef