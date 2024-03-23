classdef Timers

    properties
        UI

        SteppingTimer               %Main timer for controlling the frames of game
        SteppingTimer_Freq = 0.8      %Frequency of stepping timer, this can be later set from settings [s]
        
        RepeatTimerX
        RepeatTimerY
        
        FoldersTimer
        
        WatchDogTimer

    end

    methods
        function this = Timers(UI)
            this.UI = UI;

            this.SteppingTimer = timer('ExecutionMode', 'fixedRate', 'Period',this.SteppingTimer_Freq, ...
                                 'TimerFcn', @(~,~) this.UI.stepGame);
            this.RepeatTimerX = timer('ExecutionMode', 'fixedRate', 'Period',0.1, ...
                                 'TimerFcn', @(~,~) this.UI.joystickRepeatX);
            this.RepeatTimerY = timer('ExecutionMode', 'fixedRate', 'Period',0.1, ...
                                 'TimerFcn', @(~,~) this.UI.joystickRepeatY);
            this.WatchDogTimer = timer('ExecutionMode', 'fixedRate', 'Period', 2, ...
                                'TimerFcn', @(~,~) this.UI.WatchDog.WatchDogUpdate);
            this.FoldersTimer = timer('ExecutionMode', 'fixedRate', 'Period', 1, ...
                    'TimerFcn', @(~,~) this.UI.Folders.checkForNewFolder);
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