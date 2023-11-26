classdef UI_uicontrol < handle

    properties

        Game                    %Property for holding game object
        SerialReader            %Property for serial port communication object

        Fig_Main

        % Main menu window
        Panel_Main                  %Window for main menu
        Background
        GamesList                   %Lists all game directories in {PROJECT}/games
        Image                       %Logo of game currently selected
        ImageBack                   %Container for holding logo
        Heading                     %Label for heading
        ButtonsMain_Arr = []        %Array holding all buttons on main screen
        GameNames_arr = []          %Names of directories in {PROJECT}/games

        % Game window
        Panel_Game                  %Window for playing game
        Axis                        %For ploting game, pass this to game object
        ButtonBack                  %Button for returning back to main menu
        SteppingTimer               %Main timer for controlling the frames of game
        SteppingTimer_Freq = 1      %Frequency of stepping timer, this can be later set from settings [s]

        % Counters and flags
        GameIDX = 1                 %Index for higlighting chosen game
        ColumnIDX = 0;              %Index for choosing buttons
        GameFlag = 0                %Is any game running flag
        JoystickX_flag = 0
        JoystickY_flag = 0          %Used for restricting joystick to only move once when moved
    end

    properties (SetAccess = private)
        width_Panel
        height_Panel
        width_PushButton
        height_PushButton
        width_Image
        height_Image
        width_GameList
        height_GameList

        btn_FontColor = [0.58, 0.47, 0.39]
        btn_BackColor = [0.38 0.19 0.25]
        btn_HBackColor = [0.34 0.32 0.57]

    end

    methods
        function this = UI_uicontrol()
            try
                this.SerialReader = SerialReader(this);
            catch
                disp("Error while inicilazing serial port");
            end
            
            this.Fig_Main = uifigure('CloseRequestFcn', @(src, event) this.closeFig(src, event),...
                                    'Units','normalized', 'Position', [0.1 0.1 0.8 0.8]);
            this.Panel_Main = uipanel(this.Fig_Main,'Units', 'normalized', 'Position', [0 0 1 1]);
            this.Panel_Game = uipanel(this.Fig_Main,'Units', 'normalized', 'Position', [0 0 1 1], 'Visible', 'off');

            sizePanel = getpixelposition(this.Panel_Main, true);
            this.width_Panel = sizePanel(3);
            this.height_Panel = sizePanel(4);
            this.width_PushButton = this.width_Panel/8;
            this.height_PushButton = this.height_Panel/15;
            this.width_Image = this.width_Panel/2.35;
            this.height_Image = this.height_Panel/2.3;
            this.width_GameList = this.width_Panel/6;
            this.height_GameList = this.height_Panel/1.7;

            this.Background = uiimage(this.Panel_Main, "ImageSource", 'a.gif', 'Position', [0 0 this.width_Panel+10 this.height_Panel+10], 'ScaleMethod', 'stretch');
            this.ImageBack = uipanel(this.Panel_Main, "BackgroundColor","white",...
                                    "Position", [this.width_Panel*8/20 this.height_Panel*1/4 this.width_Image this.height_Image]);
            ButtonStart = uibutton(this.Panel_Main, 'Text', 'Start',...
                                        'Position', [this.width_Panel*8/20 this.height_Panel*2/20 this.width_PushButton this.height_PushButton],...
                                            "ButtonPushedFcn", @this.startGame, 'Enable', 'on', 'BackgroundColor', this.btn_HBackColor, 'FontColor', this.btn_FontColor);
            ButtonSettings = uibutton(this.Panel_Main, 'Text', 'Settings',...
                                            'Position', [this.width_Panel*11/20 this.height_Panel*2/20 this.width_PushButton this.height_PushButton], 'Enable', 'on', 'BackgroundColor', this.btn_BackColor, 'FontColor', this.btn_FontColor);
            ButtonExit = uibutton(this.Panel_Main, 'Text', 'EXIT', 'Position',...
                                        [this.width_Panel*14/20 this.height_Panel*2/20 this.width_PushButton this.height_PushButton],...
                                        "ButtonPushedFcn", @this.closeFig, 'Enable', 'on', 'BackgroundColor', this.btn_BackColor, 'FontColor', this.btn_FontColor);
            this.GamesList = uilistbox(this.Panel_Main, "Position",...
                                        [this.width_Panel*4/20 this.height_Panel*2/20 this.width_GameList this.height_GameList], 'FontSize', 20, "ValueChangedFcn", @this.dropDownChange);
            this.ButtonsMain_Arr = [ButtonStart, ButtonSettings, ButtonExit];
            this.checkForNewFolder();
    
            this.SteppingTimer = timer('ExecutionMode', 'fixedRate', 'Period', this.SteppingTimer_Freq, ...
                                'TimerFcn', @(~,~) this.stepGame);
    
        end

        function checkForNewFolder(this)

            projectFolder = fullfile(pwd, "gamesky");
            folders = dir(projectFolder);
            folders = folders([folders.isdir]);

            for i = 1:length(folders)
                folderName = folders(i).name;
                if ~strcmp(folderName, '.') && ~strcmp(folderName, '..')
                    this.GameNames_arr = [this.GameNames_arr; convertCharsToStrings(folderName)];
                end
            end

            set(this.GamesList, "Items", this.GameNames_arr);
            
            LogoFolder = fullfile(pwd, "gamesky");
            LogoFolder = fullfile(LogoFolder, this.GameNames_arr(1), "logo");
            imageFiles = dir(fullfile(LogoFolder, '*.jpg'));
            imageFiles = [imageFiles; dir(fullfile(LogoFolder, '*.png'))];

            if ~isempty(imageFiles)
                firstImageFile = fullfile(imageFiles(1).folder, imageFiles(1).name);
                this.Image = uiimage(this.ImageBack, "ImageSource", firstImageFile, "Position", [0 0 this.width_Image this.height_Image]);
            else
                this.Image = uilabel(this.ImageBack, "Text", "No logo found", 'Position', [100 100 300 300]);
            end


        end

        function dropDownChange(this, eventdata, ~)

            if(~(isempty(this.Image)))
                delete(this.Image);
            end
            LogoFolder = fullfile(pwd, "gamesky");
            LogoFolder = fullfile(LogoFolder, eventdata.Value, "logo");

            imageFiles = dir(fullfile(LogoFolder, '*.jpg'));
            imageFiles = [imageFiles; dir(fullfile(LogoFolder, '*.png'))];

            if ~isempty(imageFiles)
                firstImageFile = fullfile(imageFiles(1).folder, imageFiles(1).name);
                this.Image = uiimage(this.ImageBack, "ImageSource", firstImageFile, "Position", [0 0 this.width_Image this.height_Image]);
            else
                this.Image = uilabel(this.ImageBack, "Text", "No logo found",'Position', [100 100 300 300]);
            end

        end

        function startGame(this, ~, ~)

            this.Panel_Main.Visible = 'off';
            this.Panel_Game.Visible = 'on';
            
            this.Axis = uiaxes(this.Panel_Game, "XLim", [0 100], "YLim", [0 100], 'Units','normalized', 'Position', [0 0 0.7 0.9], 'XTick', [], 'YTick', []);
            
            this.ButtonBack = uibutton(this.Panel_Game, 'Text', 'Back', 'Position', [this.width_Panel*(9/10) this.height_Panel*(1/10) 100 20],...
                                            "ButtonPushedFcn", @this.backToMainMenu);

            addpath(fullfile(pwd, "gamesky", this.GamesList.Value));
            this.Game = feval(this.GamesList.Value, this.Axis);

            start(this.SteppingTimer);

            this.GameFlag = 1;
                
        end

        function backToMainMenu(this, ~, ~)

            stop(this.SteppingTimer);
       
            this.Game = [];
            this.GameFlag = 0;

            this.Panel_Main.Visible = 'on';
            this.Panel_Game.Visible = 'off';

        end

        function stepGame(this)
            try
                this.Game.runFrame();
            catch
                errordlg("Error");
                this.backToMainMenu();
            end

        end

        function serialNewData(this, data)
            if(this.GameFlag)
                try
                    this.Game.newData(data);
                catch
                    errordlg("Error");
                    this.backToMainMenu();
                end

            else
                X = str2double(data([3,4,5]));
                Y = str2double(data([9,10,11]));
                btn1 = str2double(data(13));
                if (Y > 30 && Y < 70)
                    this.JoystickY_flag = 1;
                elseif (Y > 80 && this.JoystickY_flag == 1)
                    this.JoystickY_flag = 0;
                    if this.ColumnIDX == 0
                        this.GameIDX = this.GameIDX - 1;
                        if this.GameIDX <= 1
                            this.GameIDX = 1;
                        end
                        set(this.ButtonsMain_Arr(:), 'BackgroundColor', [0.9 0.9 0.9]);
                        this.highlightGame();
                    end
                elseif (Y < 20 && this.JoystickY_flag == 1)
                    this.JoystickY_flag = 0;
                    if this.ColumnIDX == 0
                        this.GameIDX = this.GameIDX + 1;
                        if this.GameIDX >= length(this.GameNames_arr)
                            this.GameIDX = length(this.GameNames_arr);
                        end
                        set(this.ButtonsMain_Arr(:), 'BackgroundColor', [0.9 0.9 0.9]);
                        this.highlightGame();
                    end
                end

                if (X > 30 && X < 70)
                    this.JoystickX_flag = 1;
                elseif (X < 20 && this.JoystickX_flag == 1)
                    this.JoystickX_flag = 0;
                    this.ColumnIDX = this.ColumnIDX + 1;
                    if this.ColumnIDX >= length(this.ButtonsMain_Arr)
                        this.ColumnIDX = length(this.ButtonsMain_Arr);
                    end
                    if this.ColumnIDX > 0
                        this.highlightButton();
                    end
                elseif (X > 80 && this.JoystickX_flag == 1)
                    this.JoystickX_flag = 0;
                    this.ColumnIDX = this.ColumnIDX - 1;
                    if this.ColumnIDX <= 0
                        set(this.ButtonsMain_Arr(:), 'BackgroundColor', [0.9 0.9 0.9]);
                        this.ColumnIDX = 0;
                        this.highlightGame();
                    end
                    if this.ColumnIDX > 0
                        this.highlightButton();
                    end
                end

                if btn1
                    try
                        btnCallback = this.ButtonsMain_Arr(this.ColumnIDX).ButtonPushedFcn;
                        btnCallback(this.ButtonsMain_Arr(this.ColumnIDX));
                    catch
                    end
                end
            end
            
        end

        function closeFig(this, ~, ~)
            
            this.SerialReader.device = [];
            if(strcmp(this.SteppingTimer.Running, 'on'))
                stop(this.SteppingTimer)
            end
            delete(this.Fig_Main);

        end

        function highlightGame(this)
            set(this.GamesList, 'Value', this.GameNames_arr(this.GameIDX));
            btnCallback = this.GamesList.ValueChangedFcn;
            btnCallback(this.GamesList);
        end

        function highlightButton(this)
            set(this.GamesList, 'Value', {});
            set(this.ButtonsMain_Arr(:), 'BackgroundColor', [0.9 0.9 0.9]);
            set(this.ButtonsMain_Arr(this.ColumnIDX), 'BackgroundColor', [0.67 0.8 0.9]);
            
        end

    end
end