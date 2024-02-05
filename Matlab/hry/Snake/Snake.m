classdef Snake < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        hUI
        ax
        xLimit = 50;
        yLimit = 50;
        
        % define size of the window (px)
        windowXLimit = 500;
        windowYLimit = 500;
        
        % maximum frequency at which the game is updated
        updateFrequency = 10; % Hz
        
        snakeStartLength = 3;

        snakeBody = 0;
        targetX = 0;
        targetY = 0;
        target;

        exitRoutine = 0;

        direction = 0;

        score = 0;

        gameOver = 0;
    end

    methods
        function this = Snake(hUI)

            this.hUI = hUI;
            this.ax = this.hUI.Axes;
            hUI.enableButtonsIRQ([1 1 1 1 1 1]);
            hUI.setTimerFreq(0.1);
            set(this.ax, "Units", "pixels", "Position", [0, 0, this.windowXLimit, this.windowYLimit],...
                "XLim", [0, this.xLimit], "YLim", [0, this.yLimit], "XTick", [],"YTick", []);
            this.targetX = 0;
            this.targetY = 0;
            this.target = line(this.ax, "XData", this.targetX, "YData", this.targetY, "Marker", "s", "MarkerSize", this.windowXLimit / this.xLimit, "MarkerFaceColor", "blue", "MarkerEdgeColor", "blue");
            this.exitRoutine = 0;
            while ~this.exitRoutine
                for i = 1 : this.snakeStartLength
                    this.snakeBody(i) = line(this.ax, "XData", ceil(this.xLimit / 2) + (ceil(this.snakeStartLength / 2) - i) * cos(this.direction * pi / 2), "YData", ceil(this.yLimit / 2) + (ceil(this.snakeStartLength / 2) - i) * sin(this.direction * pi / 2), "Marker", "s", "MarkerSize", this.windowXLimit / this.xLimit);
                    if i == 1
                        set(this.snakeBody(i), "MarkerFaceColor", "red", "MarkerEdgeColor", "red");
                    else
                        set(this.snakeBody(i), "MarkerFaceColor", "black", "MarkerEdgeColor", "black");
                    end
                end
                newTargetX = randi(this.xLimit);
                newTargetY = randi(this.yLimit);
                match = 0;
                
                % check if randomly generated target lies within the snake's body
                for i = 1 : length(this.snakeBody)
                    if newTargetX == get(this.snakeBody(i), "XData") && newTargetY == get(this.snakeBody(i), "YData")
                        match = 1;
                    end
                end
                
                if ~match
                    this.exitRoutine = 1;
                    this.targetX = newTargetX;
                    this.targetY = newTargetY;
                    set(this.target, "XData", this.targetX, "YData", this.targetY);
                end
            end
        end

        function runFrame(this)

            xHead = round(get(this.snakeBody(1), "XData") + cos(this.direction * pi / 2));
            yHead = round(get(this.snakeBody(1), "YData") + sin(this.direction * pi / 2));
            
            % check if head is outside of playng field boundaries, move it to the other side
            if xHead < 0
                xHead = this.xLimit;
            elseif xHead > this.xLimit
                xHead = 0;
            end
            
            if yHead < 0
                yHead = this.yLimit;
            elseif yHead > this.yLimit
                yHead = 0;
            end
    
            % check if head has reached target
            if xHead == this.targetX && yHead == this.targetY
                % update score
                this.hUI.toggleRedLED();
                this.score = this.score + 1;
                clc;
                disp("Score: " + this.score);
                % prolong the snake
                this.snakeBody(end + 1) = line(this.ax, "XData", 0, "YData", 0, "Marker", "s", "MarkerSize", this.windowXLimit / this.xLimit, "MarkerFaceColor", "black", "MarkerEdgeColor", "black");
                
                % generate new random target
                this.exitRoutine = 0;
                while ~this.exitRoutine
                    newTargetX = randi(this.xLimit);
                    newTargetY = randi(this.yLimit);
                    match = 0;
    
                    % check if randomly generated target lies within the snake's body
                    for i = 1 : length(this.snakeBody)
                        if newTargetX == get(this.snakeBody(i), "XData") && newTargetY == get(this.snakeBody(i), "YData")
                            match = 1;
                        end
                    end
    
                    if ~match
                        this.exitRoutine = 1;
                        this.targetX = newTargetX;
                        this.targetY = newTargetY;
                        set(this.target, "XData", this.targetX, "YData", this.targetY);
                    end
                end
            end
            
            % check if head is within the snake's body
            for i = 2 : length(this.snakeBody)
                if xHead == get(this.snakeBody(i), "XData") && yHead == get(this.snakeBody(i), "YData")
                    this.gameOver = 1;
                end
            end
    
            % update snake's body, skip if gameover
            if ~this.gameOver
                for i = length(this.snakeBody) : -1 : 2
                    set(this.snakeBody(i), "XData", get(this.snakeBody(i - 1), "XData"), "YData", get(this.snakeBody(i - 1), "YData"));
                end
                set(this.snakeBody(1), "XData", xHead, "YData", yHead);
            else
                this.hUI.saveScore(this.score);
            end
        end

        function BtnExitPressed(this)
            this.hUI.saveScore(this.score);
            this.hUI.backToMainMenu();
        end

        function BtnUpPressed(this)
            this.direction = 1;
        end

        function BtnDownPressed(this)
            this.direction = 3;
        end

        function BtnRightPressed(this)
            this.direction = 0;
        end

        function BtnLeftPressed(this)
            this.direction = 2;
        end
    end
end