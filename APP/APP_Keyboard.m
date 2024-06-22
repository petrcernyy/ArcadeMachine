classdef APP_Keyboard < handle
    properties
        PanelUI
        Panel;
        KeyButtons = [];
        CurrentButtonIndex = 1;
        widthPanel;
        heightPanel;
    end
    
    methods
        function this = APP_Keyboard(Panel)
            this.PanelUI = Panel;

            size = getpixelposition(this.PanelUI);

            this.widthPanel = size(3);
            this.heightPanel = size(4);
            this.createPanel();
            this.createKeyboard();
            this.highlightButton();
        end
        
        function createPanel(this)
            this.Panel = uipanel(this.PanelUI, 'BorderWidth', 5, 'BorderColor', 'k', 'BackgroundColor', 'w',...
                                'Position', [this.widthPanel/2 - this.widthPanel/4, this.heightPanel/20, this.widthPanel/2, this.heightPanel/3]);
        end
        
        function createKeyboard(this)
            numCols = 9;
            keyWidth = 60;
            keyHeight = 60;
            spacing = 10;
            startX = 100;
            startY = this.heightPanel/3 - 150;
            
            alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
            for i = 1:length(alphabet)
                row = floor((i-1) / numCols);
                col = mod(i-1, numCols);
                xPos = startX + col * (keyWidth + spacing);
                yPos = startY - row * (keyHeight + spacing);
                
                button = uibutton(this.Panel, ...
                                  'Position', [xPos, yPos, keyWidth, keyHeight], ...
                                  'Text', alphabet(i), 'BackgroundColor', [0.6406, 0.4648, 0.5430]);
                this.KeyButtons = [this.KeyButtons, button];
            end
            row = floor((27-1) / numCols);
            col = mod(27-1, numCols);
            xPos = startX + col * (keyWidth + spacing);
            yPos = startY - row * (keyHeight + spacing);
            
            button = uibutton(this.Panel, ...
                              'Position', [xPos, yPos, keyWidth, keyHeight], ...
                              'Text', 'Save', 'BackgroundColor', [0.6406, 0.4648, 0.5430]);
            this.KeyButtons = [this.KeyButtons, button];

            button = uibutton(this.Panel, ...
                              'Position', [xPos - 5*keyWidth - 5*spacing, yPos - keyHeight - spacing, 3*keyWidth + 2*spacing, keyHeight], ...
                              'Text', 'Delete', 'BackgroundColor', [0.6406, 0.4648, 0.5430]);
            this.KeyButtons = [this.KeyButtons, button];

        end
        
        function highlightButton(this)
            for i = 1:length(this.KeyButtons)
                this.KeyButtons(i).BackgroundColor = [0.6406, 0.4648, 0.5430];
            end
            this.KeyButtons(this.CurrentButtonIndex).BackgroundColor = [0.5, 0.4258, 0.25];
        end
        
        function BtnLeftPressed(this)
            if this.CurrentButtonIndex > 1
                this.CurrentButtonIndex = this.CurrentButtonIndex - 1;
                this.highlightButton();
            end
        end
        
        function BtnRightPressed(this)
            if this.CurrentButtonIndex < length(this.KeyButtons)
                this.CurrentButtonIndex = this.CurrentButtonIndex + 1;
                this.highlightButton();
            end
        end
        
        function BtnUpPressed(this)
            if this.CurrentButtonIndex > 9
                this.CurrentButtonIndex = this.CurrentButtonIndex - 9;
                this.highlightButton();
            elseif this.CurrentButtonIndex == length(this.KeyButtons)
                this.CurrentButtonIndex = 19;
                this.highlightButton();
            end
        end
        
        function BtnDownPressed(this)
            if this.CurrentButtonIndex <= (length(this.KeyButtons) - 9)
                this.CurrentButtonIndex = this.CurrentButtonIndex + 9;
                this.highlightButton();
            elseif this.CurrentButtonIndex >= 19 
                this.CurrentButtonIndex = length(this.KeyButtons);
                this.highlightButton();
            end
        end
        
        function key = BtnEnterPressed(this)
            key = this.KeyButtons(this.CurrentButtonIndex).Text;
        end
    end
end