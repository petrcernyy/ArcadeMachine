clear;
clc;

% config
% define size of the playing field (unitless)
xLimit = 50;
yLimit = 50;

% define size of the window (px)
windowXLimit = 500;
windowYLimit = 500;

% maximum frequency at which the game is updated
updateFrequency = 10; % Hz

snakeStartLength = 3;

% window setup
fig = figure(...
"MenuBar", "none",...
"Name", "Snake",...
"NumberTitle", "off",...
"Units", "pixels",...
"Position", [200, 200, windowXLimit, windowYLimit],...
"KeyPressFcn", @KeyPressHandler...
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

% snake body setup
snakeBody = 0;
fig.UserData.direction = 0;
for i = 1 : snakeStartLength
    snakeBody(i) = line(ax, "XData", ceil(xLimit / 2) + (ceil(snakeStartLength / 2) - i) * cos(fig.UserData.direction * pi / 2), "YData", ceil(yLimit / 2) + (ceil(snakeStartLength / 2) - i) * sin(fig.UserData.direction * pi / 2), "Marker", "s", "MarkerSize", windowXLimit / xLimit);
    if i == 1
        set(snakeBody(i), "MarkerFaceColor", "red", "MarkerEdgeColor", "red");
    else
        set(snakeBody(i), "MarkerFaceColor", "black", "MarkerEdgeColor", "black");
    end
end

% target setup, generate first randomly
targetX = 0;
targetY = 0;
target = line(ax, "XData", targetX, "YData", targetY, "Marker", "s", "MarkerSize", windowXLimit / xLimit, "MarkerFaceColor", "blue", "MarkerEdgeColor", "blue");
exitRoutine = 0;
while ~exitRoutine
    newTargetX = randi(xLimit);
    newTargetY = randi(yLimit);
    match = 0;
    
    % check if randomly generated target lies within the snake's body
    for i = 1 : length(snakeBody)
        if newTargetX == get(snakeBody(i), "XData") && newTargetY == get(snakeBody(i), "YData")
            match = 1;
        end
    end
    
    if ~match
        exitRoutine = 1;
        targetX = newTargetX;
        targetY = newTargetY;
        set(target, "XData", targetX, "YData", targetY);
    end
end
drawnow();

% preallocation
score = 0;
gameOver = 0;
previousTime = 0;
currentTime = 0;
tic();

% main loop
while ~gameOver
    currentTime = toc();
    if currentTime >= previousTime + 1 / updateFrequency
        % retrieve current data and calculate new position of snake's head
        direction = fig.UserData.direction;
        xHead = round(get(snakeBody(1), "XData") + cos(direction * pi / 2));
        yHead = round(get(snakeBody(1), "YData") + sin(direction * pi / 2));
        
        % check if head is outside of playng field boundaries, move it to the other side
        if xHead < 0
            xHead = xLimit;
        elseif xHead > xLimit
            xHead = 0;
        end
        
        if yHead < 0
            yHead = yLimit;
        elseif yHead > yLimit
            yHead = 0;
        end

        % check if head has reached target
        if xHead == targetX && yHead == targetY
            % update score
            score = score + 1;
            clc;
            disp("Score: " + score);
            % prolong the snake
            snakeBody(end + 1) = line(ax, "XData", 0, "YData", 0, "Marker", "s", "MarkerSize", windowXLimit / xLimit, "MarkerFaceColor", "black", "MarkerEdgeColor", "black");
            
            % generate new random target
            exitRoutine = 0;
            while ~exitRoutine
                newTargetX = randi(xLimit);
                newTargetY = randi(yLimit);
                match = 0;

                % check if randomly generated target lies within the snake's body
                for i = 1 : length(snakeBody)
                    if newTargetX == get(snakeBody(i), "XData") && newTargetY == get(snakeBody(i), "YData")
                        match = 1;
                    end
                end

                if ~match
                    exitRoutine = 1;
                    targetX = newTargetX;
                    targetY = newTargetY;
                    set(target, "XData", targetX, "YData", targetY);
                end
            end
        end
        
        % check if head is within the snake's body
        for i = 2 : length(snakeBody)
            if xHead == get(snakeBody(i), "XData") && yHead == get(snakeBody(i), "YData")
                gameOver = 1;
            end
        end

        % update snake's body, skip if gameover
        if ~gameOver
            for i = length(snakeBody) : -1 : 2
                set(snakeBody(i), "XData", get(snakeBody(i - 1), "XData"), "YData", get(snakeBody(i - 1), "YData"));
            end
            set(snakeBody(1), "XData", xHead, "YData", yHead);
            
            drawnow();
        end
        previousTime = currentTime;
    end
end

% display total score at the end
clc;
disp("Total score: " + score);

% keyboard keypress event handler
function KeyPressHandler(this, eventArgs)
    % check which key was pressed and set snake's direction accordingly, also check whether snake is allowed to make this move
    if strcmp(eventArgs.Key, 'rightarrow') && this.UserData.direction ~= 2
        this.UserData.direction = 0;
    elseif strcmp(eventArgs.Key, 'uparrow') && this.UserData.direction ~= 3
        this.UserData.direction = 1;
    elseif strcmp(eventArgs.Key, 'leftarrow') && this.UserData.direction ~= 0
        this.UserData.direction = 2;
    elseif strcmp(eventArgs.Key, 'downarrow') && this.UserData.direction ~= 1
        this.UserData.direction = 3;
    end
end