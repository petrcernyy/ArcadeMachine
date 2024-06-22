classdef Tetris < handle
    properties (Access = private)
        % work variables
        hUI
        fig;
        ax;
        t;
        windowXLimit;
        windowYLimit;
        xLimit;
        yLimit;
        updateFrequency;
        currentBlock;
        lineObjects;
        takenPosition;
        keys;
        markerSize;
        score = 0;
        scoreText

        % config
        edgeColor = [0.75, 0.75, 0.75]; % Matlab color of plaing field surrounding edges
        bottomLimit = 1; % last Y position any part of any block can be on
        leftLimit = 1; % first X position any part of any block can be on
        rightLimit = 0; % = xLimit, assigned in constructor, last X position any part of any block may be on
        moveDown = 2; % how much is the block moved down on keypress
    end
    methods (Access = public)
        function this = Tetris(hUI)
            % assign parameters to variables
            this.hUI = hUI;
            position = [this.hUI.AxesPanelSize(1), this.hUI.AxesPanelSize(2)];
            this.windowXLimit = position(1);
            this.windowYLimit = position(2);
            this.xLimit = 25;
            this.yLimit = 25;
            this.updateFrequency = 3;
            % this.keys = keys;

            this.rightLimit = this.xLimit;

            % calculate size of marker + correction
            this.markerSize = this.windowXLimit / this.xLimit - 1.9;

            this.hUI.enableButtonsIRQ([1 1 1 1 1 1]);

            % % check for the right number of keys
            % if length(keys) ~= 6
            %     error("Invalid number of keys. Array must contain 6 keys in order [move down, drop down, move left, move right, rotate CW, rotate CCW].");
            % end

            % check for the right number of position values
            if length(position) ~= 2
                error("Position is invalid. Valid position is an 1x2 array of X and Y coordinates from bottom left corner.");
            end


            this.ax = hUI.Axes;
            set(this.ax, "XLim", [0, this.xLimit + this.leftLimit], "YLim", [0, this.yLimit + this.bottomLimit], "Units", "pixels", "Position", [0, 0, position(1), position(2)]);
            hUI.setTimerFreq(1);
            this.scoreText = text(this.hUI.Axes, this.xLimit-2, this.yLimit-1, '0', 'FontSize', 20);
            % create horizontal edges
            for i = 0 : this.xLimit + 1
                line(this.ax, "XData", i, "YData", 0, "Marker", "s", "MarkerSize", this.markerSize, "MarkerFaceColor", this.edgeColor, "MarkerEdgeColor", this.edgeColor);
                line(this.ax, "XData", i, "YData", this.yLimit + 1, "Marker", "s", "MarkerSize", this.markerSize, "MarkerFaceColor", this.edgeColor, "MarkerEdgeColor", this.edgeColor);
            end

            % create vertical edges
            for i = 1 : this.yLimit
                line(this.ax, "XData", 0, "YData", i, "Marker", "s", "MarkerSize", this.markerSize, "MarkerFaceColor", this.edgeColor, "MarkerEdgeColor", this.edgeColor);
                line(this.ax, "XData", this.xLimit + 1, "YData", i, "Marker", "s", "MarkerSize", this.markerSize, "MarkerFaceColor", this.edgeColor, "MarkerEdgeColor", this.edgeColor);
            end
            
            % create first block, must be before starting the timer
            this.CreateNewBlock();
        end
    end
    methods (Access = public)
        % timer function, main function that handles regular playing field updates
        function runFrame(this)
            % if block has reached something in the way
            if this.CheckBlockPosition(this.currentBlock.position(:, 2), this.bottomLimit, 0) || this.CheckBlockPosition(this.currentBlock.position, this.takenPosition, [0, -1])
                % if block has not moved since creation -> game over
                if ~this.currentBlock.moved

                    text('Parent', this.hUI.Axes, 'String', 'GAME OVER', 'Position', [this.xLimit/4 this.yLimit/2], 'FontSize', 40);
                    this.hUI.saveScore(this.score);
                    delete(this.currentBlock);

                    return;
                end

                % store line objects from not moving blocks
                if isempty(this.lineObjects)
                    this.lineObjects = this.currentBlock.Destruct();
                else
                    this.lineObjects = [this.lineObjects, this.currentBlock.Destruct()];
                end

                % check each horizontal line whether it is full -> if it is, delete it
                lineDeleted = 1;
                % in a while loop to restart for loop because the y position changes after each line deletion
                while lineDeleted
                    lineDeleted = 0;
                    for i = this.bottomLimit : this.yLimit
                        % count line objects in each line
                        yLines = 0;
                        for j = 1 : length(this.lineObjects)
                            if get(this.lineObjects(j), "YData") == i
                                yLines = yLines + 1;
                            end
                        end

                        % if number of line objects in a line is equal to or greater than (accounting for possible errors) the maximum number
                        if yLines >= this.xLimit
                            % in a while loop to restart for loop because the length changes after each deletion
                            lineObjectDeleted = 1;
                            while lineObjectDeleted
                                lineObjectDeleted = 0;
                                for j = 1 : length(this.lineObjects)
                                    if get(this.lineObjects(j), "YData") == i
                                        delete(this.lineObjects(j));
                                        this.lineObjects(j) = [];
                                        lineObjectDeleted = 1;
                                        break;
                                    end
                                end
                            end
                            
                            % move down everything above the deleted horizontal line
                            for j = 1 : length(this.lineObjects)
                                yData = get(this.lineObjects(j), "YData");
                                if yData > i
                                    set(this.lineObjects(j), "YData", yData - 1);
                                end
                            end

                            lineDeleted = 1;
                            this.score = this.score + 100;
                            set(this.scoreText, 'String', num2str(this.score));
                            break;
                        end
                    end
                end

                % continue by creating new block
                this.CreateNewBlock();
            else
                % if block is free to move down, then move it
                this.currentBlock.MoveBlock(0, -1);
                this.currentBlock.UpdateGraphics();
            end
            
            % get taken positions, which the controlled block cannot enter
            this.FindTakenPosition();
        end

        % key press function, main function that handles pressed keys
        function BtnUpPressed(this)
            while ~this.CheckBlockPosition(this.currentBlock.position(:, 2), this.bottomLimit, 0) && ~this.CheckBlockPosition(this.currentBlock.position, this.takenPosition, [0, -1])
                this.currentBlock.MoveBlock(0, -1);
            end
            this.currentBlock.UpdateGraphics();
        end

        function BtnDownPressed(this)
            for i = 1 : this.moveDown
                if ~this.CheckBlockPosition(this.currentBlock.position(:, 2), this.bottomLimit, 0) && ~this.CheckBlockPosition(this.currentBlock.position, this.takenPosition, [0, -1])
                    this.currentBlock.MoveBlock(0, -1);
                    this.currentBlock.UpdateGraphics();
                end
            end
        end

        function BtnLeftPressed(this)
            if ~this.CheckBlockPosition(this.currentBlock.position(:, 1), this.leftLimit, 0)  && ~this.CheckBlockPosition(this.currentBlock.position, this.takenPosition, [-1, 0])
                this.currentBlock.MoveBlock(-1, 0);
                this.currentBlock.UpdateGraphics();
            end
        end

        function BtnRightPressed(this)
            if ~this.CheckBlockPosition(this.currentBlock.position(:, 1), this.rightLimit, 0) && ~this.CheckBlockPosition(this.currentBlock.position, this.takenPosition, [1, 0])
                this.currentBlock.MoveBlock(1, 0);
                this.currentBlock.UpdateGraphics();
            end
        end

        function BtnEnterPressed(this)
            newCoordinates = this.currentBlock.GetRotatedBlockPosition([1, -1]);
            if ~(this.CheckBlockPosition(newCoordinates, this.takenPosition, [0, 0]) || this.CheckBlockPosition(this.currentBlock.position(:, 1), this.rightLimit, 0) || this.CheckBlockPosition(this.currentBlock.position(:, 1), this.leftLimit, 0) || this.CheckBlockPosition(this.currentBlock.position, this.takenPosition, [0, -1]) || this.CheckBlockPosition(this.currentBlock.position(:, 2), this.bottomLimit, 0))
                this.currentBlock.position = newCoordinates;
                this.currentBlock.UpdateGraphics();
            end
        end

        function BtnExitPressed(this)
            this.hUI.saveScore(this.score);
            this.hUI.backToMainMenu();
        end

        % create new block
        function CreateNewBlock(this)
            this.currentBlock = BlockClass(this.ax, ceil(this.xLimit / 2), this.yLimit, this.markerSize);
        end

        % function to check whether a position aligns with another, returns true if positions match, arguments: position to be tested (n by x array), position to be tested against (m by x array), correction (1 by x array, how much to modify the tested position), each row is a set of coordinates (i.e. x, [x, y],...)
        function output = CheckBlockPosition(this, blockPosition, position, correction)
            output = 0;
            if size(blockPosition, 2) == size(position, 2) && size(blockPosition, 2) == size(correction, 2)
                for i = 1 : size(position, 1)
                    for j = 1 : size(blockPosition, 1)
                        if blockPosition(j, :) + correction(1, :) == position(i, :)
                            output = 1;
                        end
                    end
                end
            end
        end

        % function to get positions, which the controlled block cannot enter, i.e. positions that are occupied by other line objects
        function FindTakenPosition(this)
            if ~isempty(this.lineObjects)
                this.takenPosition = [];
                for i = 1 : length(this.lineObjects)
                    this.takenPosition(i, 1) = get(this.lineObjects(i), "XData");
                    this.takenPosition(i, 2) = get(this.lineObjects(i), "YData");
                end
            end
        end
    end
end