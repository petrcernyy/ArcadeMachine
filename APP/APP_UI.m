classdef APP_UI < handle

    properties (SetAccess = public)
        Axes                        %For ploting game, pass this to game object
        AxesPanelSize
    end

    methods (Access = public)

        % Function for saving score. The input parameter is score. Check a
        % game folder for file score.txt if there is none creates one and
        % in it keeps a ranking for the game. The file is read-only, only
        % writable by this function
        function saveScore(this, Score)

            this.APP_Database.mySaveScore(Score);
    
        end

        % Call this function to handle return back to main menu. Deletes
        % the isntance of current game, stops the soundtrack.
        function backToMainMenu(this)

            this.myBackToMainMenu();

        end

        % Function for setting the stepping frequency of timer. Input is
        % timer frequency[s], min 0.01
        function setTimerFreq(this, timerFreq)

            this.APP_Timers.SteppingTimer_Freq = timerFreq;
            this.APP_Timers.stopMyTimer(Enums.SteppingTimerE);
            set(this.APP_Timers.SteppingTimer, 'Period', this.APP_Timers.SteppingTimer_Freq);

        end

        % Defines which buttons you want to use, This function takes array 1x6 representing [Up Down
        % Left Right Enter Exit]. Array consist of either 0 or 1. 0 equals
        % no use 1 equals use. If there is interrupt enabled a
        % user must define appropriate function eg. [1 0 1 0 0 0], I have
        % to define two function BtnUpPressed(), BtnLeftPressed().
        function enableButtonsIRQ(this, enableArr)

            this.ControlsIRQ = enableArr;

        end


        function sendJoystickValue(this)

            this.joyValues = 1;

        end

        % Not intended for user
        function receiveSerialData(this, data)

            this.serialNewData(data);

        end

        function dabataseData(this, data)

            if (~this.GameFlag)
                this.APP_Database.DatabaseNewData(data);
            else
                sendEventToHTMLSource(this.Html, "ConsoleMessage", "Cannot change user during game.");
            end

        end

    end

    properties (Access = {?APP_Games, ?APP_Timers, ?APP_WatchDog, ?APP_Database})

        Game                    %Property for holding game object
        APP_SerialReader            %Property for serial port communication object
        APP_Games                 %Property for APP_Games object
        APP_Keyboard         %Property for APP_Keyboard object
        APP_Timers                  %Property for APP_Timers object
        APP_WatchDog                %Property for APP_WatchDog object
        APP_Database                %Property for APP_Database object

        Player                  %Current player name
        ID                      %Current player ID

        Fig_Main                %Main figure

        GamesPath               %Path to folder containging games

        % Main menu window
        Panel_Main                  %Window for main menu
        Loading                     %Loading window
        Html                        %Main menu
        Image                       %Logo of game currently selected
        QR                          %QR code for github of current game
        GameNames_arr = []          %Names of directories in {PROJECT}/games
        musicVolume = 30            
        SoundtrackPlayer

        % Creating new user window
        newUserWindow               %Window that creates new user in APP_Database           
        newUserWindowName           %Text box for writing name
        Panel_NewUser               %Panel for holding virtual keyboard
        

        % Game window
        Panel_Game                  %Window for playing game
        Panel_Axis                  %Panel for holding axis for plotting game
        LeaderBoard                 %Leadebord object


        RepeatCounterX = 0          %Repeat counters for joystick controller 
        RepeatCounterY = 0


        Sound                       %Hold sound

        joyValues = 0               %If set to 1 the game object receives data raw data from joystick

        JoyControls = [0 0 0 0 0 0]
        ControlsIRQ = [0 0 0 0 0 0]
        

        % Counters and flags
        GameIDX = 1                 %Index for higlighting chosen game
        ColumnIDX = 0               %Index for choosing buttons
        GameChosen = 0              %Indicates whether in main menu a game has been chosen
        ButtonPressed = 0           %Indicates a pressed button for html
        GameFlag = 0                %Is any game running flag
        NoGamesFlag = 0

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
            this = APP_UI();
        end
    end

    methods (Access = {?APP_Games, ?APP_Timers, ?APP_WatchDog, ?APP_Database})
        %  ------------Methods for UI--------------------------------------

        function this = APP_UI()

            this.GamesPath = fullfile(pwd, "hry");
            % this.GamesPath = "D:\hry";
            
            this.Fig_Main = uifigure('CloseRequestFcn', @this.closeFigureMouse, 'WindowKeyPressFcn', @this.keyPressed,...
                                    'Units','normalized', 'Position', [0 0 1 1], 'WindowState','fullscreen', 'Color', [0.53 0.81 0.92]);
            
            this.Panel_Main = uipanel(this.Fig_Main,'Units', 'normalized', 'OuterPosition', [0 0 1 1], 'HitTest', 'off', 'BackgroundColor', [0.53 0.81 0.92], 'Visible', 'off');
            sizePanel = getpixelposition(this.Panel_Main, true);
            this.width_Panel = sizePanel(3);
            this.height_Panel = sizePanel(4);
            this.Panel_Game = uipanel(this.Fig_Main,'Units', 'pixels', 'Position', [0 0 this.width_Panel this.height_Panel], 'Visible', 'off',...
                                        'BackgroundColor', [0.53 0.81 0.92]);
            this.Panel_Axis = uipanel(this.Panel_Game, 'Units','normalized',...
                                'Position', [0.025 0.1 0.6 0.8]);

            this.AxesPanelSize = getpixelposition(this.Panel_Axis);
            this.AxesPanelSize = this.AxesPanelSize([3,4]);

            this.Loading = uihtml(this.Fig_Main, "HTMLSource", 'html/loading.html', 'Position',...
                    [0 0 this.width_Panel this.height_Panel], 'HTMLEventReceivedFcn', @this.htmldatareceived);

            
            set(this.Image, 'Position', this.Pos_Image);
            set(this.QR, 'Position', this.Pos_QR);      
            set(this.Image, 'Visible', 'on');
            set(this.QR, 'Visible', 'on'); 
      
            this.Html = uihtml(this.Panel_Main, "HTMLSource", 'html/index.html', "Position",....
                            [0 0 this.width_Panel this.height_Panel],...
                            'HTMLEventReceivedFcn', @this.htmldatareceived);

            this.APP_Timers = APP_Timers(this);

            this.APP_Games = APP_Games(this);

            this.APP_Timers.startMyTimer(Enums.GamesTimerE);

            this.sendJoystickDatatoHtml();

            try
                this.APP_SerialReader = APP_SerialReader(this);
            catch e
                ErrorMessage = jsonencode(e.message);
                sendEventToHTMLSource(this.Html, "ConsoleMessage", ErrorMessage);
            end 

            this.APP_Database = APP_Database(this);
           
            this.APP_WatchDog = APP_WatchDog(this);
            this.APP_Timers.startMyTimer(Enums.WatchDogTimerE);

            this.Panel_NewUser = uipanel(this.Panel_Main,'Units', 'normalized', 'Position', [0 0 1 1], 'Visible', 'off');
            this.newUserWindow = uihtml(this.Panel_NewUser, 'HTMLSource', 'html/usernamewindow.html',...
                'Position', [0 0 this.width_Panel this.height_Panel]);
            this.newUserWindowName = uicontrol(this.Panel_NewUser,'Style','edit', 'Position', [(this.width_Panel/2)-130 (this.height_Panel/2)-50 250 50], 'FontSize', 30);
            this.APP_Keyboard = APP_Keyboard(this.Panel_NewUser);

            pause(4);

            set(this.Panel_Main, "Visible", "on");

            sendEventToHTMLSource(this.Html, "ConsoleMessage", "For navigating in menu use joystick UP/DOWN.");
            sendEventToHTMLSource(this.Html, "ConsoleMessage", "For selecting game press purple button.");
            sendEventToHTMLSource(this.Html, "ConsoleMessage", "For exiting game press blue button.");
            sendEventToHTMLSource(this.Html, "ConsoleMessage", "Score is saved only if an account is available.");
            sendEventToHTMLSource(this.Html, "ConsoleMessage", "Use your ISIC card for creating a profile.");
            
        end

        function htmldatareceived(this, ~, event)
            name = event.HTMLEventName;
            if strcmp(name,'ButtonStartClicked')
                this.startGame();
            elseif strcmp(name, 'ButtonExitClicked')
                this.closeFig();
            elseif strcmp(name, 'ListBoxValueChanged')
                this.APP_Games.logoChange(event.HTMLEventData);
            elseif strcmp(name, 'PosOfPicture')
                data = jsondecode(event.HTMLEventData);
                this.Pos_Image = [data.left+10 data.bottom data.width-15 data.height];
                this.Pos_QR = [data.leftQR+10 data.bottomQR data.widthQR-15 data.heightQR];
            elseif strcmp(name, 'LoadingComplete')
                this.Loading.Visible = 'off';
            elseif strcmp(name, 'UserName')
                this.Player = event.HTMLEventData;
                sendEventToHTMLSource(this.Html, "ConsoleMessage", this.Player);
            end
        end
        % -----------------------------------------------------------------
        %  ------------Game functions--------------------------------------
        function startGame(this)

            addpath(fullfile(this.GamesPath, this.GameNames_arr(this.GameIDX)));
            try
                
                this.Loading.Visible = 'on';
               
                this.Axes = uiaxes(this.Panel_Axis, "XLim", [0 100], "YLim", [0 100], 'Units','normalized',...
                                'Position', [0 0 1 1], 'XTick', [], 'YTick', []);
                disableDefaultInteractivity(this.Axes);

                this.Game = feval(this.GameNames_arr(this.GameIDX), this);

                this.LeaderBoard = uihtml(this.Panel_Game, "HTMLSource", 'html/leaderboard.html',...
                    'Position', [this.width_Panel-400 300 400 this.height_Panel-50], 'Visible','off');
                try
                    scoreboard = readtable(fullfile(this.GamesPath, this.GameNames_arr(this.GameIDX), 'score.txt'));
                    sendEventToHTMLSource(this.LeaderBoard, "newData", jsonencode(scoreboard));
                    pause(1);
                    sendEventToHTMLSource(this.LeaderBoard, "newData", jsonencode(scoreboard));
                    set(this.LeaderBoard, 'Visible', 'on');
                catch e
                    ErrorMessage = jsonencode(e.message);
                    sendEventToHTMLSource(this.Html, "ConsoleMessage", ErrorMessage);
                end

                this.Loading.Visible = 'off';
                this.Panel_Game.Visible = 'on';

                this.APP_Timers.startMyTimer(Enums.SteppingTimerE);
                this.APP_Timers.stopMyTimer(Enums.GamesTimerE);
    
                this.GameFlag = 1;
            catch e
                ErrorMessage = jsonencode(e.message);
                sendEventToHTMLSource(this.Html, "ConsoleMessage", ErrorMessage);
                this.Loading.Visible = 'off';
                this.backToMainMenu();
            end
                
        end

        function stepGame(this)
            try
                this.Game.runFrame();
            catch e
                ErrorMessage = jsonencode(e.message);
                sendEventToHTMLSource(this.Html, "ConsoleMessage", ErrorMessage);
                this.backToMainMenu();
            end

        end

        % -----------------------------------------------------------------
        %  ------------Controls--------------------------------------

        function keyPressed(this, ~, event)

            switch(event.Key)
                case 'uparrow'
                    if (~this.GameFlag)
                        this.BtnUpPressed();
                    elseif (this.ControlsIRQ(Enums.Up))
                        if (this.GameFlag)
                            this.Game.BtnUpPressed();
                        end
                    end
                case 'downarrow'
                    if (~this.GameFlag)
                        this.BtnDownPressed();
                    elseif (this.ControlsIRQ(Enums.Down))
                        if (this.GameFlag)
                            this.Game.BtnDownPressed();
                        end
                    end
                case 'rightarrow'
                    if (~this.GameFlag)
                        this.BtnRightPressed();
                    elseif (this.ControlsIRQ(Enums.Right))
                        if (this.GameFlag)
                            this.Game.BtnRightPressed();
                        end
                    end
                case 'leftarrow'
                    if (~this.GameFlag)
                        this.BtnLeftPressed();
                    elseif (this.ControlsIRQ(Enums.Left))
                        if (this.GameFlag)
                         this.Game.BtnLeftPressed();
                        end
                    end
                case 'space'
                    if (~this.GameFlag)
                        this.BtnEnterPressed();
                    elseif (this.ControlsIRQ(Enums.BtnEnter))
                        if (this.GameFlag)
                            this.Game.BtnEnterPressed();
                        end
                    end
                case 'q'
                    if (~this.GameFlag)
                        this.BtnExitPressed();
                    elseif (this.ControlsIRQ(Enums.BtnExit))
                        if (this.GameFlag)
                            this.Game.BtnExitPressed();
                        end
                    end

                case 'g'
                    this.APP_Database.databaseNewData('123456789');
                    
            end
        end

        function serialNewData(this, data)

            X = str2double(data([2,3,4]));
            Y = str2double(data([7,8,9]));
            btn1 = str2double(data(12));
            btn2 = str2double(data(15));

            if (btn1)
                if (~this.GameFlag)
                    this.BtnEnterPressed();
                elseif(this.ControlsIRQ(Enums.BtnEnter))
                    this.Game.BtnEnterPressed();
                end
            end

            if (btn2)
                if (~this.GameFlag)
                    this.BtnExitPressed();
                elseif (this.ControlsIRQ(Enums.BtnExit))
                    this.Game.BtnExitPressed();
                end
            end
            
            if (~this.joyValues)
                if (Y > 30 && Y < 70)
                    this.JoyControls([Enums.Up, Enums.Down]) = 0;
                    this.RepeatCounterY = 0;
                    this.APP_Timers.stopMyTimer(Enums.RepeatTimerYE);
                end
                if (Y < 30)
                    this.RepeatCounterY = this.RepeatCounterY + 1;
                    this.APP_Timers.stopMyTimer(Enums.RepeatTimerYE);
                    if(this.RepeatCounterY > 10)
                        set(this.APP_Timers.RepeatTimerY, 'Period', 0.1);
                        this.APP_Timers.startMyTimer(Enums.RepeatTimerYE);
                    elseif(this.RepeatCounterY > 2)
                        set(this.APP_Timers.RepeatTimerY, 'Period', 0.5);
                        this.APP_Timers.startMyTimer(Enums.RepeatTimerYE);
                    elseif(this.RepeatCounterY == 1)
                        if (~this.GameFlag)
                            this.BtnUpPressed();
                        elseif (this.ControlsIRQ(Enums.Up))
                            this.Game.BtnUpPressed();
                        end
                    end
                    this.JoyControls(Enums.Up) = 1;
                elseif (Y > 80)
                    this.RepeatCounterY = this.RepeatCounterY + 1;
                    this.APP_Timers.stopMyTimer(Enums.RepeatTimerYE);
                    if(this.RepeatCounterY > 10)
                        this.APP_Timers.stopMyTimer(Enums.RepeatTimerYE);
                        set(this.APP_Timers.RepeatTimerY, 'Period', 0.1);
                        this.APP_Timers.startMyTimer(Enums.RepeatTimerYE);
                    elseif(this.RepeatCounterY > 2)
                        set(this.APP_Timers.RepeatTimerY, 'Period', 0.5);
                        this.APP_Timers.startMyTimer(Enums.RepeatTimerYE);
                    elseif(this.RepeatCounterY == 1)
                        if (~this.GameFlag)
                            this.BtnDownPressed();
                        elseif (this.ControlsIRQ(Enums.Down))
                            this.Game.BtnDownPressed();
                        end
                    end
                    this.JoyControls(Enums.Down) = 1;
                end
    
                if (X > 30 && X < 70)
                    this.JoyControls([Enums.Left, Enums.Right]) = 0;
                    this.RepeatCounterX = 0;
                    this.APP_Timers.stopMyTimer(Enums.RepeatTimerXE);
                end
                if (X < 30)
                    this.RepeatCounterX = this.RepeatCounterX + 1;
                    this.APP_Timers.stopMyTimer(Enums.RepeatTimerXE);
                    if(this.RepeatCounterX > 10)
                        set(this.APP_Timers.RepeatTimerX, 'Period', 0.1);
                        this.APP_Timers.startMyTimer(Enums.RepeatTimerXE);
                    elseif(this.RepeatCounterX > 2)
                        set(this.APP_Timers.RepeatTimerX, 'Period', 0.5);
                        this.APP_Timers.startMyTimer(Enums.RepeatTimerXE);
                    elseif(this.RepeatCounterX == 1)
                        if (~this.GameFlag)
                            this.BtnLeftPressed();
                        elseif (this.ControlsIRQ(Enums.Left))
                            this.Game.BtnLeftPressed();
                        end
                    end
                    this.JoyControls(Enums.Left) = 1;
                elseif (X > 80)
                    this.RepeatCounterX = this.RepeatCounterX + 1;
                    this.APP_Timers.stopMyTimer(Enums.RepeatTimerXE);
                    if(this.RepeatCounterX > 10)
                        set(this.APP_Timers.RepeatTimerX, 'Period', 0.1);
                        this.APP_Timers.startMyTimer(Enums.RepeatTimerXE);
                    elseif(this.RepeatCounterX > 2)
                        set(this.APP_Timers.RepeatTimerX, 'Period', 0.5);
                        this.APP_Timers.startMyTimer(Enums.RepeatTimerXE);
                    elseif(this.RepeatCounterX == 1)
                        if (~this.GameFlag)
                            this.BtnRightPressed();
                        elseif (this.ControlsIRQ(Enums.Right))
                            this.Game.BtnRightPressed();
                        end
                    end
                    this.JoyControls(Enums.Right) = 1;
                end
            else
                this.Game.JoyValues(X,Y);
            end
        end

        function joystickRepeatX(this)

            if (this.JoyControls(Enums.Right))
                if (~this.GameFlag)
                    this.BtnRightPressed();
                elseif (this.ControlsIRQ(Enums.Right))
                    this.Game.BtnRightPressed();
                end
            elseif (this.JoyControls(Enums.Left))
                if (~this.GameFlag)
                    this.BtnLeftPressed();
                elseif (this.ControlsIRQ(Enums.Left))
                    this.Game.BtnLeftPressed();
                end
            end

        end

        function joystickRepeatY(this)

            if (this.JoyControls(Enums.Up))
                if (~this.GameFlag)
                    this.BtnUpPressed();
                elseif (this.ControlsIRQ(Enums.Up))
                    this.Game.BtnUpPressed();
                end
            elseif (this.JoyControls(Enums.Down))
                if (~this.GameFlag)
                    this.BtnDownPressed();
                elseif (this.ControlsIRQ(Enums.Down))
                    this.Game.BtnDownPressed();
                end
            end

        end

        function BtnUpPressed(this)
             if (this.NoGamesFlag && ~this.APP_Database.CreatingUser)
                if (this.ColumnIDX == 0)
                    this.GameIDX = this.GameIDX - 1;
                    if this.GameIDX <= 1
                        this.GameIDX = 1;
                    end
                    this.sendJoystickDatatoHtml();
                end
            else
                this.APP_Keyboard.BtnUpPressed();
             end
        end

        function BtnDownPressed(this)
            if (this.NoGamesFlag && ~this.APP_Database.CreatingUser)
                if (this.ColumnIDX == 0)
                    this.GameIDX = this.GameIDX + 1;
                    if this.GameIDX >= length(this.GameNames_arr)
                        this.GameIDX = length(this.GameNames_arr);
                    end
                    this.sendJoystickDatatoHtml();
                end
            else
                this.APP_Keyboard.BtnDownPressed();
            end
        end

        function BtnLeftPressed(this)
            if (~this.APP_Database.CreatingUser)
                if (this.GameChosen)
                    this.ColumnIDX = this.ColumnIDX - 1;
                    if this.ColumnIDX <= 1
                        this.ColumnIDX = 1;
                    end
                    this.sendJoystickDatatoHtml();
                end
            else
                this.APP_Keyboard.BtnLeftPressed();
            end
        end

        function BtnRightPressed(this)
            if (~this.APP_Database.CreatingUser)
                if (this.GameChosen)
                    this.ColumnIDX = this.ColumnIDX + 1;
                    if this.ColumnIDX >= 2
                        this.ColumnIDX = 2;
                    end
                    this.sendJoystickDatatoHtml();
                end
            else
                this.APP_Keyboard.BtnRightPressed();
            end
        end

        function BtnEnterPressed(this)
            if (~this.APP_Database.CreatingUser)
                if (this.GameChosen == 0)
                    this.GameChosen = 1;
                    this.sendJoystickDatatoHtml();
                    this.ColumnIDX = 1;
                else
                    this.ButtonPressed = 1;
                end
                this.sendJoystickDatatoHtml();
                this.ButtonPressed = 0;
            else
                Key = this.APP_Keyboard.BtnEnterPressed();
                if (strcmp(Key, 'Save') == 1)
                    this.Player = this.newUserWindowName.String;
                    this.APP_Database.saveNewUserName();
                    set(this.Panel_NewUser, 'Visible', 'off');
                    sendEventToHTMLSource(this.Html, "ConsoleMessage", "Welcome " + this.Player);
                    set(this.QR, 'Visible', 'on');
                    this.APP_Database.CreatingUser = 0;
                    focus(this.Fig_Main);
                elseif (strcmp(Key, 'Delete') == 1)
                    this.newUserWindowName.String = this.newUserWindowName.String(1:end-1);
                else
                    this.newUserWindowName.String = [this.newUserWindowName.String Key];
                end
            end
        end

        function BtnExitPressed(this)
            if (~this.APP_Database.CreatingUser)
                if this.GameChosen == 1
                    this.GameChosen = 0;
                    this.ColumnIDX = 0;
                    this.sendJoystickDatatoHtml();
                end
            else
                set(this.Panel_NewUser, 'Visible', 'off');
                this.APP_Database.CreatingUser = 0;
            end
        end

        function sendJoystickDatatoHtml(this)

            dataToSend = [this.GameIDX, this.ColumnIDX, this.GameChosen, this.ButtonPressed];
            dataToSend = jsonencode(dataToSend);
            sendEventToHTMLSource(this.Html, "JoystickData", dataToSend);

        end

        % -----------------------------------------------------------------
        % ------------Addition functions-----------------------------------

        function myBackToMainMenu(this)

            this.APP_Timers.stopMyTimer(Enums.SteppingTimerE);
            this.APP_Timers.startMyTimer(Enums.GamesTimerE);

            this.Game = [];
            delete(this.Axes);
            this.ControlsIRQ = [0 0 0 0 0 0];
            this.joyValues = 0;
            this.Panel_Game.Visible = 'off';
            
            this.GameIDX = 1;
            this.ColumnIDX = 0;
            this.GameChosen = 0; 
            this.sendJoystickDatatoHtml();
            this.GameFlag = 0;

            sendEventToHTMLSource(this.Html, "ConsoleMessage", "For navigating in menu use joystick UP/DOWN.");
            sendEventToHTMLSource(this.Html, "ConsoleMessage", "For selecting game press purple button.");
            sendEventToHTMLSource(this.Html, "ConsoleMessage", "For exiting game press blue button.");
            sendEventToHTMLSource(this.Html, "ConsoleMessage", "Score is saved only if an account is available.");
            sendEventToHTMLSource(this.Html, "ConsoleMessage", "Use your ISIC card for creating a profile.");

        end

        function closeFig(this)
            
            this.APP_SerialReader.device = [];
            this.APP_Timers.stopMyTimer(Enums.SteppingTimerE);
            this.APP_Timers.stopMyTimer(Enums.GamesTimerE);
            this.APP_Timers.stopMyTimer(Enums.WatchDogTimerE);
            cancel(this.APP_WatchDog.future);
            delete(gcp('nocreate'))
            delete(this.Fig_Main);

        end

        function closeFigureMouse(this, ~, ~)

            this.closeFig();

        end

        % -----------------------------------------------------------------
    end
end