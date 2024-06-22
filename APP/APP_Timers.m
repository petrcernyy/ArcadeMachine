classdef APP_Timers

    properties
        APP_UI

        SteppingTimer               %Main timer for controlling the frames of game
        SteppingTimer_Freq = 0.8      %Frequency of stepping timer, this can be later set from settings [s]
        
        RepeatTimerX
        RepeatTimerY
        
        GamesTimer
        
        WatchDogTimer

    end

    methods
        function this = APP_Timers(APP_UI)
            this.APP_UI = APP_UI;

            this.SteppingTimer = timer('ExecutionMode', 'fixedRate', 'Period',this.SteppingTimer_Freq, ...
                                 'TimerFcn', @(~,~) this.APP_UI.stepGame);
            this.RepeatTimerX = timer('ExecutionMode', 'fixedRate', 'Period',0.1, ...
                                 'TimerFcn', @(~,~) this.APP_UI.joystickRepeatX);
            this.RepeatTimerY = timer('ExecutionMode', 'fixedRate', 'Period',0.1, ...
                                 'TimerFcn', @(~,~) this.APP_UI.joystickRepeatY);
            this.WatchDogTimer = timer('ExecutionMode', 'fixedRate', 'Period', 2, ...
                                'TimerFcn', @(~,~) this.APP_UI.APP_WatchDog.WatchDogUpdate);
            this.GamesTimer = timer('ExecutionMode', 'fixedRate', 'Period', 1, ...
                    'TimerFcn', @(~,~) this.APP_UI.APP_Games.checkForNewFolder);
        end

        function startMyTimer(this, index)
            switch(index)
                case Enums.GamesTimerE
                    if(strcmp(this.GamesTimer.Running, 'off'))
                        start(this.GamesTimer);
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
                case Enums.GamesTimerE
                    if(strcmp(this.GamesTimer.Running, 'on'))
                        stop(this.GamesTimer);
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