classdef UI < handle

    properties (SetAccess = public)
        Axes                        %For ploting game, pass this to game object
        SteppingTimer_Freq = 0.8      %Frequency of stepping timer, this can be later set from settings [s]

    end

    methods (Access = public)

        % Function for saving score. The input parameter is score. Check a
        % game folder for file score.txt if there is none creates one and
        % in it keeps a ranking for the game. The file is read-only, only
        % writable by this function
        function saveScore(this, Score)

            GamePath = fullfile(this.GamesPath, this.GameNames_arr(this.GameIDX));
            scoreFile = dir(fullfile(GamePath, 'score.txt'));

            if (~isempty(scoreFile))
                
                fileattrib(fullfile(GamePath, 'score.txt'), '+w');
                scoreboard = readtable(fullfile(GamePath, 'score.txt'));
                idx = find(strcmp(this.Player, scoreboard.Name));
                if (~isempty(idx))
                    if (Score > scoreboard.Score(idx))
                        scoreboard(idx,:) = table({this.Player}, Score);
                    end
                else
                    scoreboard(height(scoreboard)+1,:) = table({this.Player}, Score);
                end
                
                scoreboard = sortrows(scoreboard, 2, 'descend');
                scoreboard(10:end,:) = [];
                sendEventToHTMLSource(this.LeaderBoard, "newData", jsonencode(scoreboard));
                writetable(scoreboard, fullfile(GamePath, 'score.txt'));
                fileattrib(fullfile(GamePath, 'score.txt'), '-w');

            else
                
                Name = {this.Player};
                scoreboard = table(Name, Score);
                sendEventToHTMLSource(this.LeaderBoard, "newData", jsonencode(scoreboard));
                writetable(table(Name, Score), fullfile(GamePath, 'score.txt'));
                fileattrib(fullfile(GamePath, 'score.txt'), '-w');

            end
        end

        % Call this function to handle return back to main menu. Deletes
        % the isntance of current game, stops the soundtrack.
        function backToMainMenu(this)

            this.stopMyTimer(Enums.SteppingTimerE);
            this.startMyTimer(Enums.FoldersTimerE);

            this.stopSoundtrack();

            this.Game = [];
            delete(this.Axes);
            this.ControlsIRQ = [0 0 0 0 0 0];
            this.MultiplayerFlag = 0;
            this.Panel_Game.Visible = 'off';
            
            this.GameIDX = 1;
            this.ColumnIDX = 0;
            this.GameChosen = 0; 
            this.sendJoystickDatatoHtml();
            this.startMyTimer(Enums.FoldersTimerE);
            this.playSoundtrack('menu_music.mp3');
            this.GameFlag = 0;

        end

        % Function for setting the stepping frequency of timer. Input is
        % timer frequency[s], min 0.01
        function setTimerFreq(this, timerFreq)

            this.SteppingTimer_Freq = timerFreq;
            set(this.SteppingTimer, 'Period', this.SteppingTimer_Freq);

        end

        % Interrupts for buttons, This function takes array 1x6 representing [Up Down
        % Left Right Enter Exit]. Array consist of either 0 or 1. 0 equals
        % no interrupt 1 equals interrupt. If there is interrupt enabled a
        % user must define appropriate function eg. [1 0 1 0 0 0], I have
        % to define two function BtnUpPressed(), BtnLeftPressed().
        function enableButtonsIRQ(this, enableArr)

            this.ControlsIRQ = enableArr;

        end

        % Plays soundtrack troughout the game
        function playSoundtrack(this, fileName)

            [Audio, Rate] = audioread(fileName);
            this.SoundtrackPlayer = audioplayer(Audio*(this.musicVolume/100), Rate);
            play(this.SoundtrackPlayer);

        end

        % Stops soundtrack
        function stopSoundtrack(this)

            if(~isempty(this.SoundtrackPlayer))
                if(strcmp(this.SoundtrackPlayer.Running, 'on'))
                    stop(this.SoundtrackPlayer)
                end
            end

        end

        % Plays sound once
        function playSound(this, fileName)

            [Audio, Rate] = audioread(fileName);
            this.Sound = audioplayer(Audio*(this.musicVolume/100), Rate);
            play(this.Sound);

        end
        
        % Enables multiplayer mode, meaning data from joystick and keys
        % will not be united and there are going to be addition function
        % JoyUpPressed(), JoyLeftPressed(),...
        function setMultiplayer(this)

            this.MultiplayerFlag = 1;

        end

        % Ends multiplayer mode
        function stopMultiplayer(this)

            this.MultiplayerFlag = 0;

        end

        % Not intended for user
        function receiveSerialData(this, data)

            this.serialNewData(data);

        end
    end

    properties (SetAccess = private)

        Game                    %Property for holding game object
        SerialReader            %Property for serial port communication object

        Player = 'Petr'

        Fig_Main

        FoldersTimer

        GamesPath

        % Main menu window
        Panel_Main                  %Window for main menu
        Loading
        Loaded = 0
        Html
        GamesList                   %Lists all game directories in {PROJECT}/games
        Image                       %Logo of game currently selected
        QR
        GameNames_arr = []          %Names of directories in {PROJECT}/games
        musicVolume = 30;
        SoundtrackPlayer

        % Game window
        Panel_Game                  %Window for playing game
        Panel_Axis
        SteppingTimer               %Main timer for controlling the frames of game
        WatchDogTimer               %Timer for checking stuck in loop
        RepeatTimerX
        RepeatTimerY
        RepeatCounterX = 0
        RepeatCounterY = 0
        Sound
        LeaderBoard
        MultiplayerFlag = 0

        KeyControls = [0 0 0 0 0 0]    %Up, Down, Left, Right, BtnEnter, BtnExit
        JoyControls = [0 0 0 0 0 0]
        ControlsIRQ = [0 0 0 0 0 0]
        

        % Counters and flags
        GameIDX = 1                 %Index for higlighting chosen game
        ColumnIDX = 0;              %Index for choosing buttons
        GameChosen = 0;             %Indicates whether in main menu a game has been chosen
        ButtonPressed = 0;          %Indicates a pressed button for html
        GameFlag = 0                %Is any game running flag
        JoystickX_flag = 0          %Used for restricting joystick to only move once when moved
        JoystickY_flag = 0          %Used for restricting joystick to only move once when moved
        KeyOk = 0;

        Pos_Image = [0 0 0 0]    
        Pos_QR = [0 0 0 0]
    end

    properties (SetAccess = immutable)
        width_Panel
        height_Panel
    end

    methods (Static)
        % Function for creating class instance
        function this = createUIClassInstance()
            this = UI();
        end
    end

    methods (Access = private)
        function this = UI()

            this.GamesPath = fullfile(pwd, "hry");
            
            this.Fig_Main = uifigure('CloseRequestFcn', @this.closeFigureMouse, 'WindowKeyPressFcn', @this.keyPressed,...
                                    'Units','normalized', 'Position', [0.1 0.1 0.8 0.8]);
            
            this.Panel_Main = uipanel(this.Fig_Main,'Units', 'normalized', 'Position', [0 0 1 1], 'HitTest', 'off');
            this.Panel_Game = uipanel(this.Fig_Main,'Units', 'normalized', 'Position', [0 0 1 1], 'Visible', 'off',...
                                        'BackgroundColor', [0.53 0.81 0.92]);
            this.Panel_Axis = uipanel(this.Panel_Game, 'Units','normalized',...
                                'Position', [0.025 0.1 0.6 0.8]);

            sizePanel = getpixelposition(this.Panel_Main, true);
            this.width_Panel = sizePanel(3);
            this.height_Panel = sizePanel(4);

            this.Html = uihtml(this.Panel_Main, "HTMLSource", 'html/index.html', "Position",....
                            [0 0 this.width_Panel this.height_Panel],...
                            'HTMLEventReceivedFcn', @this.htmldatareceived);
            this.Loading = uihtml(this.Panel_Main, "HTMLSource", 'html/loading.html', 'Position',...
                    [0 0 this.width_Panel this.height_Panel], 'HTMLEventReceivedFcn', @this.htmldatareceived);
            this.playSoundtrack('menu_music.mp3');
            this.initFolders();
            this.sendJoystickDatatoHtml();
            try
                this.SerialReader = SerialReader(this);
            catch e
                ErrorMessage = jsonencode(e.message);
                sendEventToHTMLSource(this.Html, "ConsoleMessage", ErrorMessage);
            end 

            this.FoldersTimer = timer('ExecutionMode', 'fixedRate', 'Period', 1, ...
                                'TimerFcn', @(~,~) this.checkForNewFolder);

            this.SteppingTimer = timer('ExecutionMode', 'fixedRate', 'Period',this.SteppingTimer_Freq, ...
                                 'TimerFcn', @(~,~) this.stepGame);
            this.RepeatTimerX = timer('ExecutionMode', 'fixedRate', 'Period',0.1, ...
                                 'TimerFcn', @(~,~) this.joystickRepeatX);
            this.RepeatTimerY = timer('ExecutionMode', 'fixedRate', 'Period',0.1, ...
                                 'TimerFcn', @(~,~) this.joystickRepeatY);
           
            waitfor(this.Loading);
            set(this.Image, 'Position', this.Pos_Image);
            set(this.QR, 'Position', this.Pos_QR);
            this.startMyTimer(Enums.FoldersTimerE);
            this.Loaded = 1;
            set(this.Image, 'Visible', 'on');
            set(this.QR, 'Visible', 'on');
            
    
        end

        function checkForNewFolder(this)

            folders = dir(this.GamesPath);
            folders = folders([folders.isdir]);

            oldLenght = length(this.GameNames_arr);
            this.GameNames_arr = [];

            for i = 1:length(folders)
                folderName = folders(i).name;
                if ~strcmp(folderName, '.') && ~strcmp(folderName, '..')
                    this.GameNames_arr = [this.GameNames_arr; convertCharsToStrings(folderName)];
                end
            end

            this.GameNames_arr = unique(this.GameNames_arr);
            
            if oldLenght ~= length(this.GameNames_arr)
                dataToSend = [length(this.GameNames_arr); this.GameNames_arr];
                dataToSend = jsonencode(dataToSend);
                sendEventToHTMLSource(this.Html, "ValueChanged", dataToSend);
            end


        end

        function initFolders(this)

            this.GameNames_arr = [];

            folders = dir(this.GamesPath);
            folders = folders([folders.isdir]);

            for i = 1:length(folders)
                folderName = folders(i).name;
                if ~strcmp(folderName, '.') && ~strcmp(folderName, '..')
                    this.GameNames_arr = [this.GameNames_arr; convertCharsToStrings(folderName)];
                end
            end

            LogoFolder = fullfile(this.GamesPath, this.GameNames_arr(1), "logo");
            imageFiles = dir(fullfile(LogoFolder, '*.jpg'));
            imageFiles = [imageFiles; dir(fullfile(LogoFolder, '*.png'))];

            if ~isempty(imageFiles)
                firstImageFile = fullfile(imageFiles(1).folder, imageFiles(1).name);
                this.Image = uiimage(this.Panel_Main, "ImageSource", firstImageFile, 'Position', this.Pos_Image, 'Visible', 'off');
            else
                this.Image = uilabel(this.Panel_Main, "Text", "  No logo found", 'Position', this.Pos_Image, 'Visible', 'off');
            end

            dataToSend = [length(this.GameNames_arr); this.GameNames_arr];
            dataToSend = jsonencode(dataToSend);
            sendEventToHTMLSource(this.Html, "ValueChanged", dataToSend);


        end

        function logoChange(this, name)

            if(~(isempty(this.Image)))
                delete(this.Image);
            end
            if(~(isempty(this.QR)))
                delete(this.QR)
            end

            LogoFolder = fullfile(this.GamesPath, name, "logo");
            imageFiles = dir(fullfile(LogoFolder, '*.jpg'));
            imageFiles = [imageFiles; dir(fullfile(LogoFolder, '*.png'))];

            if ~isempty(imageFiles)
                firstImageFile = fullfile(imageFiles(1).folder, imageFiles(1).name);
                this.Image = uiimage(this.Panel_Main, "ImageSource", firstImageFile, 'Position', this.Pos_Image);
            else
                this.Image = uilabel(this.Panel_Main, "Text", "   No logo found",'Position',...
                                    this.Pos_Image, 'FontSize', 40);
            end

            QrFolder = fullfile(this.GamesPath, name, "qrcode");
            QrimageFiles = dir(fullfile(QrFolder, '*.jpg'));
            QrimageFiles = [QrimageFiles; dir(fullfile(QrFolder, '*.png'))];

            if ~isempty(QrimageFiles)
                firstQRFile = fullfile(QrimageFiles(1).folder, QrimageFiles(1).name);
                this.QR = uiimage(this.Panel_Main, "ImageSource", firstQRFile, 'Position', this.Pos_QR);
            else
                this.QR = uilabel(this.Panel_Main, "Text", "   No QR Code",'Position',...
                                    this.Pos_QR, 'FontSize', 20);
            end
    
            try
                nameOpen = fopen(fullfile(QrFolder, 'author.txt'));
                name = fgetl(nameOpen);
                sendEventToHTMLSource(this.Html, "AuthorChanged", name);
                fclose(nameOpen);
            catch
                sendEventToHTMLSource(this.Html, "AuthorChanged", '-');
            end

        end

        function htmldatareceived(this, ~, event)
            name = event.HTMLEventName;
            if strcmp(name,'ButtonStartClicked')
                this.startGame();
            elseif strcmp(name, 'ButtonExitClicked')
                this.closeFig();
            elseif strcmp(name, 'ListBoxValueChanged')
                if (this.Loaded)
                    this.logoChange(event.HTMLEventData);
                end
            elseif strcmp(name, 'PosOfPicture')
                data = jsondecode(event.HTMLEventData);
                this.Pos_Image = [data.left+10 data.bottom data.width-15 data.height];
                this.Pos_QR = [data.leftQR+10 data.bottomQR data.widthQR-15 data.heightQR];
            elseif strcmp(name, 'LoadingComplete')
                delete(this.Loading);
            end
        end

        function startGame(this)

            addpath(fullfile(this.GamesPath, this.GameNames_arr(this.GameIDX)));
            try
                this.Panel_Game.Visible = 'on';

                this.Axes = uiaxes(this.Panel_Axis, "XLim", [0 100], "YLim", [0 100], 'Units','normalized',...
                                'Position', [0 0 1 1], 'XTick', [], 'YTick', []);
                disableDefaultInteractivity(this.Axes);

                this.Game = feval(this.GameNames_arr(this.GameIDX), this);

                this.LeaderBoard = uihtml(this.Panel_Game, "HTMLSource", 'html/leaderboard.html',...
                    'Position', [this.width_Panel-400 60 400 this.height_Panel-50]);
                try
                    scoreboard = readtable(fullfile(this.GamesPath, this.GameNames_arr(this.GameIDX), 'score.txt'));
                    sendEventToHTMLSource(this.LeaderBoard, "newData", jsonencode(scoreboard));
                catch
                end
                set(this.SteppingTimer, 'Period', this.SteppingTimer_Freq);

                this.startMyTimer(Enums.SteppingTimerE);
                this.stopMyTimer(Enums.FoldersTimerE);
    
                this.GameFlag = 1;
            catch e
                ErrorMessage = jsonencode(e.message);
                sendEventToHTMLSource(this.Html, "ConsoleMessage", ErrorMessage);
                this.backToMainMenu();
            end
                
        end

        function stepGame(this)
            try
                % fun = @(varargin) this.Game.runFrame(varargin{:});
                % fut = parfeval(backgroundPool, fun, 0, this.Game);
                % wait(fut,'finished', 10);

                this.Game.runFrame();
            catch e
                ErrorMessage = jsonencode(e.message);
                sendEventToHTMLSource(this.Html, "ConsoleMessage", ErrorMessage);
                this.backToMainMenu();
            end

        end

        function keyPressed(this, ~, event)

            this.KeyControls = [0 0 0 0 0 0];

            switch(event.Key)
                case 'uparrow'
                    if (~this.GameFlag)
                        this.BtnUpPressed();
                    elseif (this.ControlsIRQ(Enums.Up))
                        if (this.GameFlag)
                            this.Game.BtnUpPressed();
                        end
                    % else
                    %     this.KeyControls(Enums.Up) = 1;
                    %     this.KeyOk = 1;
                    % end
                    end
                case 'downarrow'
                    if (~this.GameFlag)
                        this.BtnDownPressed();
                    elseif (this.ControlsIRQ(Enums.Down))
                        if (this.GameFlag)
                            this.Game.BtnDownPressed();
                        end
                    % else
                    %     this.KeyControls(Enums.Down) = 1;
                    %     this.KeyOk = 1;
                    end
                case 'rightarrow'
                    if (~this.GameFlag)
                        this.BtnRightPressed();
                    elseif (this.ControlsIRQ(Enums.Right))
                        if (this.GameFlag)
                            this.Game.BtnRightPressed();
                        end
                    % else
                    %     this.KeyControls(Enums.Right) = 1;
                    %     this.KeyOk = 1;
                    end
                case 'leftarrow'
                    if (~this.GameFlag)
                        this.BtnLeftPressed();
                    elseif (this.ControlsIRQ(Enums.Left))
                        if (this.GameFlag)
                         this.Game.BtnLeftPressed();
                        end
                    % else
                    %     this.KeyControls(Enums.Left) = 1;
                    %     this.KeyOk = 1;
                    end
                case 'space'
                    if (~this.GameFlag)
                        this.BtnEnterPressed();
                    elseif (this.ControlsIRQ(Enums.BtnEnter))
                        if (this.GameFlag)
                            this.Game.BtnEnterPressed();
                        end
                    % else
                    %     this.KeyControls(Enums.BtnEnter) = 1;
                    %     this.KeyOk = 1;
                    end
                case 'escape'
                    if (~this.GameFlag)
                        this.BtnExitPressed();
                    elseif (this.ControlsIRQ(Enums.BtnExit))
                        if (this.GameFlag)
                            this.Game.BtnExitPressed();
                        end
                    % else
                    %     this.KeyControls(Enums.BtnExit) = 1;
                    %     this.KeyOk = 1;
                    end
            end

            % if this.KeyOk
            % 
            %     if (~this.GameFlag)
            %         this.newControls(this.KeyControls);
            %         this.KeyOk = 0;
            %     end
            % 
            % end
        end

        function serialNewData(this, data)

            X = str2double(data([3,4,5]));
            Y = str2double(data([9,10,11]));
            btn1 = str2double(data(13));
            btn2 = str2double(data(15));

            if (btn1)
                if (~this.GameFlag)
                    this.BtnEnterPressed();
                elseif(this.ControlsIRQ(Enums.BtnEnter))
                    if (this.MultiplayerFlag)
                        this.Game.JoyEnterPressed();
                    else
                        this.Game.BtnEnterPressed();
                    end
                end
            % else
            %     this.JoyControls(Enums.BtnEnter) = btn1;
            end

            if (btn2)
                if (~this.GameFlag)
                    this.BtnExitPressed();
                elseif (this.ControlsIRQ(Enums.BtnExit))
                    if (this.MultiplayerFlag)
                        this.Game.JoyExitPressed();
                    else
                        this.Game.BtnExitPressed();
                    end
                end
            % else
            %     this.JoyControls(Enums.BtnExit) = btn2;
            end

            if (Y > 30 && Y < 70)
                this.JoyControls([Enums.Up, Enums.Down]) = 0;
                this.RepeatCounterY = 0;
                this.stopMyTimer(Enums.RepeatTimerYE);
            end
            if (Y > 80)
                % if (this.ControlsIRQ(Enums.Up))
                    this.RepeatCounterY = this.RepeatCounterY + 1;
                    this.stopMyTimer(Enums.RepeatTimerYE);
                    if(this.RepeatCounterY > 5)
                        set(this.RepeatTimerY, 'Period', 0.05);
                    else
                        set(this.RepeatTimerY, 'Period', 0.5);
                    end
                    this.startMyTimer(Enums.RepeatTimerYE);
                    this.JoyControls(Enums.Up) = 1;
                % else
                %     this.JoyControls(Enums.Up) = 1;
                % end
            elseif (Y < 20)
                % if (this.ControlsIRQ(Enums.Down))
                    this.RepeatCounterY = this.RepeatCounterY + 1;
                    this.stopMyTimer(Enums.RepeatTimerYE);
                    if(this.RepeatCounterY > 5)
                        set(this.RepeatTimerY, 'Period', 0.05);
                    else
                        set(this.RepeatTimerY, 'Period', 0.5);
                    end
                    this.startMyTimer(Enums.RepeatTimerYE);
                    this.JoyControls(Enums.Down) = 1;
                % else
                %     this.JoyControls(Enums.Down) = 1;
                % end
            end

            if (X > 30 && X < 70)
                this.JoyControls([Enums.Left, Enums.Right]) = 0;
                this.RepeatCounterX = 0;
                this.stopMyTimer(Enums.RepeatTimerXE);
            end
            if (X < 20)
                % if (this.ControlsIRQ(Enums.Right))
                    this.RepeatCounterX = this.RepeatCounterX + 1;
                    this.stopMyTimer(Enums.RepeatTimerXE);
                    if(this.RepeatCounterX > 5)
                        set(this.RepeatTimerX, 'Period', 0.05);
                    else
                        set(this.RepeatTimerX, 'Period', 0.5);
                    end
                    this.startMyTimer(Enums.RepeatTimerXE);
                    this.JoyControls(Enums.Right) = 1;
                % else
                %     this.JoyControls(Enums.Right) = 1;
                % end
            elseif (X > 80)
                % if (this.ControlsIRQ(Enums.Left))
                    this.RepeatCounterX = this.RepeatCounterX + 1;
                    this.stopMyTimer(Enums.RepeatTimerXE);
                    if(this.RepeatCounterX > 5)
                        set(this.RepeatTimerX, 'Period', 0.05);
                    else
                        set(this.RepeatTimerX, 'Period', 0.5);
                    end
                    this.startMyTimer(Enums.RepeatTimerXE);
                    this.JoyControls(Enums.Left) = 1;
                % else
                %     this.JoyControls(Enums.Left) = 1;
                % end
            end

            % if (~this.GameFlag)
            %     this.newControls(this.JoyControls)
            % end

        end

        function joystickRepeatX(this)

            if (this.JoyControls(Enums.Right))
                if (~this.GameFlag)
                    this.BtnRightPressed();
                elseif (this.ControlsIRQ(Enums.Right))
                    if (this.MultiplayerFlag)
                        this.Game.JoyRightPressed();
                    else
                        this.Game.BtnRightPressed();
                    end
                end
            elseif (this.JoyControls(Enums.Left))
                if (~this.GameFlag)
                    this.BtnLeftPressed();
                elseif (this.ControlsIRQ(Enums.Left))
                    if (this.MultiplayerFlag)
                        this.Game.JoyLeftPressed();
                    else
                        this.Game.BtnLeftPressed();
                    end
                end
            end

        end

        function joystickRepeatY(this)

            if (this.JoyControls(Enums.Up))
                if (~this.GameFlag)
                    this.BtnUpPressed();
                elseif (this.ControlsIRQ(Enums.Up))
                    if (this.MultiplayerFlag)
                        this.Game.JoyUpPressed();
                    else
                        this.Game.BtnUpPressed();
                    end
                end
            elseif (this.JoyControls(Enums.Down))
                if (~this.GameFlag)
                    this.BtnDownPressed();
                elseif (this.ControlsIRQ(Enums.Down))
                    if (this.MultiplayerFlag)
                        this.Game.JoyDownPressed();
                    else
                        this.Game.BtnDownPressed();
                    end
                end
            end

        end

        function BtnUpPressed(this)
            if (this.ColumnIDX == 0)
                this.GameIDX = this.GameIDX - 1;
                if this.GameIDX <= 1
                    this.GameIDX = 1;
                end
                this.sendJoystickDatatoHtml();
            end
        end

        function BtnDownPressed(this)
            if (this.ColumnIDX == 0)
                this.GameIDX = this.GameIDX + 1;
                if this.GameIDX >= length(this.GameNames_arr)
                    this.GameIDX = length(this.GameNames_arr);
                end
                this.sendJoystickDatatoHtml();
            end
        end

        function BtnLeftPressed(this)
            if (this.GameChosen)
                this.ColumnIDX = this.ColumnIDX - 1;
                if this.ColumnIDX <= 1
                    this.ColumnIDX = 1;
                end
                this.sendJoystickDatatoHtml();
            end
        end

        function BtnRightPressed(this)
            if (this.GameChosen)
                this.ColumnIDX = this.ColumnIDX + 1;
                if this.ColumnIDX >= 2
                    this.ColumnIDX = 2;
                end
                this.sendJoystickDatatoHtml();
            end
        end

        function BtnEnterPressed(this)
            if (this.GameChosen == 0)
                this.GameChosen = 1;
                this.sendJoystickDatatoHtml();
                this.ColumnIDX = 1;
            else
                this.ButtonPressed = 1;
            end
            this.sendJoystickDatatoHtml();
            this.ButtonPressed = 0;
        end

        function BtnExitPressed(this)
            if this.GameChosen == 1
                this.GameChosen = 0;
                this.ColumnIDX = 0;
                this.sendJoystickDatatoHtml();
            end
        end
        
        % function newControls(this, data)
        % 
        %     if data(Enums.BtnEnter)
        %         if (this.GameChosen == 0)
        %             this.GameChosen = 1;
        %             this.sendJoystickDatatoHtml();
        %             this.ColumnIDX = 1;
        %         else
        %             this.ButtonPressed = 1;
        %         end
        %     end
        % 
        %     if data(Enums.BtnExit)
        %         if this.GameChosen == 1
        %             this.GameChosen = 0;
        %             this.ColumnIDX = 0;
        %         end
        %     end
        % 
        %     if (this.ColumnIDX == 0)
        %         if data(Enums.Up)
        %             this.GameIDX = this.GameIDX - 1;
        %             if this.GameIDX <= 1
        %                 this.GameIDX = 1;
        %             end
        %         elseif data(Enums.Down)
        %             this.GameIDX = this.GameIDX + 1;
        %             if this.GameIDX >= length(this.GameNames_arr)
        %                 this.GameIDX = length(this.GameNames_arr);
        %             end
        %         end
        %     end
        % 
        %     if (this.GameChosen)
        %         if data(Enums.Right)
        %             this.ColumnIDX = this.ColumnIDX + 1;
        %             if this.ColumnIDX >= 2
        %                 this.ColumnIDX = 2;
        %             end
        %         elseif data(Enums.Left)
        %             this.ColumnIDX = this.ColumnIDX - 1;
        %             if this.ColumnIDX <= 1
        %                 this.ColumnIDX = 1;
        %             end
        %         end
        %     end
        % 
        %     this.sendJoystickDatatoHtml();
        %     this.ButtonPressed = 0;
        % 
        % end

        function sendJoystickDatatoHtml(this)

            dataToSend = [this.GameIDX, this.ColumnIDX, this.GameChosen, this.ButtonPressed];
            dataToSend = jsonencode(dataToSend);
            sendEventToHTMLSource(this.Html, "JoystickData", dataToSend);

        end

        function closeFig(this)
            
            this.SerialReader.device = [];
            this.stopMyTimer(Enums.SteppingTimerE);
            this.stopMyTimer(Enums.FoldersTimerE);
            this.stopSoundtrack();
            delete(this.Fig_Main);

        end

        function closeFigureMouse(this, ~, ~)

            this.closeFig();

        end

        function startMyTimer(this, index)
            switch(index)
                case Enums.FoldersTimerE
                    if(strcmp(this.FoldersTimer.Running, 'off'))
                        start(this.FoldersTimer);
                    end
                case Enums.SteppingTimerE
                    if(strcmp(this.SteppingTimer.Running, 'off'))
                        start(this.SteppingTimer);
                    end
                case Enums.RepeatTimerXE
                    if(strcmp(this.RepeatTimerX.Running, 'off'))
                        start(this.RepeatTimerX);
                    end
                case Enums.RepeatTimerYE
                    if(strcmp(this.RepeatTimerY.Running, 'off'))
                        start(this.RepeatTimerY);
                    end
                case Enums.WatchDogTimerE
                    if(strcmp(this.WatchDogTimer.Running, 'off'))
                        start(this.WatchDogTimer);
                    end
            end
        end

        function stopMyTimer(this, index)
            switch(index)
                case Enums.FoldersTimerE
                    if(strcmp(this.FoldersTimer.Running, 'on'))
                        stop(this.FoldersTimer);
                    end
                case Enums.SteppingTimerE
                    if(strcmp(this.SteppingTimer.Running, 'on'))
                        stop(this.SteppingTimer);
                    end
                case Enums.RepeatTimerXE
                    if(strcmp(this.RepeatTimerX.Running, 'on'))
                        stop(this.RepeatTimerX);
                    end
                case Enums.RepeatTimerYE
                    if(strcmp(this.RepeatTimerY.Running, 'on'))
                        stop(this.RepeatTimerY);
                    end
                case Enums.WatchDogTimerE
                    if(strcmp(this.WatchDogTimer.Running, 'on'))
                        stop(this.WatchDogTimer);
                    end
            end
        end

    end
end