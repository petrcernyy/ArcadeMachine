clear;
clc;

% size of playing field
xLimit = 50;
yLimit = 50;

% size of window
windowXLimit = 500;
windowYLimit = 500;

% game config
updateFrequency = 10; % Hz, how frequently is the game updated, i.e. how fast the snake goes
extensionAmount = 1; % how much is the snake extended when target was hit
startLength = 3; % initial length of snake including head
startDirection = 0; % initial snake direction, 0 - right, 1 - up, 2 - left, 3 - down

% figure setup
fig = figure(...
"MenuBar", "none",...
"Name", "Snake",...
"NumberTitle", "off",...
"Units", "pixels",...
"Position", [200, 200, windowXLimit, windowYLimit],...
"KeyPressFcn", @KeyPressFcnCallback...
);

ax = axes(...
fig,...
"Units", "pixels",...
"Position", [0, 0, windowXLimit, windowYLimit],...
"XLim", [0, xLimit],...
"YLim", [0, yLimit],...
"XTick", [],...
"YTick", []...
);
ax.XAxis.Color = "none";
ax.YAxis.Color = "none";

% timer setup
t = timer(...
"TimerFcn", @TimerFcnCallback,...
"period", 1 / updateFrequency,...
"ExecutionMode", "fixedRate"...
);
t.UserData.fig = fig;

% setup snake
fig.UserData.snake = SnakeClass(ax, windowXLimit / xLimit, xLimit, yLimit, startLength, startDirection);
fig.UserData.snake.UpdateGraphics();

% setup target
fig.UserData.target = TargetClass(ax, windowXLimit / xLimit, xLimit, yLimit);
fig.UserData.target.GenerateNew(fig.UserData.snake.GetCoordinates);

% setup work variables
fig.UserData.extensionAmount = extensionAmount;
fig.UserData.score = 0;
fig.UserData.overloadProtectionEnabled = 0; % protects from setting direction multiple times between updates

% start timer
start(t);

% timer function, main function, handles the whole snake
function TimerFcnCallback(this, eventArgs)
    % get object references for shorter names
    snake = this.UserData.fig.UserData.snake;
    target = this.UserData.fig.UserData.target;

    % calculate new position to work with
    snake.CalculateNewPosition();
    
    % check whether head has hit target
    if snake.CheckHead(target.GetCoordinates())
        % increase and display score
        this.UserData.fig.UserData.score = this.UserData.fig.UserData.score + this.UserData.fig.UserData.extensionAmount;
        clc;
        disp("Score: " + this.UserData.fig.UserData.score);
        
        % extend snake
        snake.Extend(this.UserData.fig.UserData.extensionAmount);

        % generate new target
        target.GenerateNew(snake.GetCoordinates());
    end

    % check whether head has hit body
    if snake.CheckHeadInBody()
        % display total score
        clc;
        disp("Total score: " + this.UserData.fig.UserData.score);
        
        % stop and delete timer
        stop(this);
        delete(this);
    else
        % update snake
        snake.UpdateGraphics();
        drawnow();

        % disable overload protection
        this.UserData.fig.UserData.overloadProtectionEnabled = 0;
    end
end

% function to handle direction changes
function KeyPressFcnCallback(this, eventArgs)
    % change direction only if overload protection is disabled
    if ~this.UserData.overloadProtectionEnabled
        if strcmp(eventArgs.Key, 'rightarrow') && this.UserData.snake.direction ~= 2
            this.UserData.snake.direction = 0;
        elseif strcmp(eventArgs.Key, 'uparrow') && this.UserData.snake.direction ~= 3
            this.UserData.snake.direction = 1;
        elseif strcmp(eventArgs.Key, 'leftarrow') && this.UserData.snake.direction ~= 0
            this.UserData.snake.direction = 2;
        elseif strcmp(eventArgs.Key, 'downarrow') && this.UserData.snake.direction ~= 1
            this.UserData.snake.direction = 3;
        end
        this.UserData.overloadProtectionEnabled = 1;
    end
end