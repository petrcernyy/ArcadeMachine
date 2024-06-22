classdef BlockClass < handle
    properties (Access = public)
        position = 0;
        moved = 0;
    end
    properties (Access = private)
        % array of presets determinind shape of block, each preset must be a 2x4 boolean array
        shapePreset = [
            [1, 1, 0, 0;
             0, 1, 1, 0],
            [0, 0, 1, 1;
             0, 1, 1, 0],
            [1, 1, 1, 1,;
             0, 0, 0, 0],
            [1, 1, 0, 0;
             1, 1, 0, 0],
            [1, 1, 1, 1;
             0, 0, 0, 1],
            [1, 1, 1, 1;
             1, 0, 0, 0];
            [1, 1, 1, 0,
             0, 1, 0, 0]
        ];
        % array of Matlab color values determining color of block, may be RGB vector (0 to 1), word, or hexadecimal value
        colorPreset = ["red", "green", "blue"];

        % work variables
        shape = 0;
        color = 0;
        orientation = 0;
        markerSize = 0;
        ax;
        lineObjects;
    end
    methods (Access = public)
        function this = BlockClass(ax, startXPosition, startYPosition, markerSize)
            this.ax = ax;
            this.markerSize = markerSize;

            % randomly choose shape from preset
            temp =  2 * randi(size(this.shapePreset, 1) / 2);
            this.shape = this.shapePreset([temp - 1, temp], :);

            % randomly choose color from color preset
            this.color = this.colorPreset(randi(length(this.colorPreset)));

            % generate line objects positions from selected shape
            for i = 1 : size(this.shape, 1)
                for j = 1 : size(this.shape, 2)
                    if this.shape(i, j)
                        tempPosition(1) = startXPosition + j + 1 - ceil(size(this.shape, 2) / 2);
                        tempPosition(2) = startYPosition - i + 1;
                        
                        if this.position == 0
                            this.position = tempPosition;
                        else
                            this.position = [this.position; tempPosition];
                        end
                    end
                end
            end
            
            % randomly rotate block
            this.orientation = randi(4) - 1;
            if this.orientation > 0
                for i = 1 : this.orientation
                    this.position = this.GetRotatedBlockPosition([-1, 1]);
                end
            end
            
            % create line objects
            for i = 1 : length(this.position)
                this.lineObjects(i) = line(this.ax, "XData", this.position(i, 1), "YData", this.position(i, 2), "Marker", "s", "MarkerSize", this.markerSize, "MarkerFaceColor", this.color, "MarkerEdgeColor", this.color);
            end
        end

        % destructor
        function lineObjects = Destruct(this)
            lineObjects = this.lineObjects;
            delete(this);
        end

        % update line objects from position variable
        function UpdateGraphics(this)
            for i = 1 : length(this.lineObjects)
                set(this.lineObjects(i), "XData", this.position(i, 1), "YData", this.position(i, 2));
            end
        end

        % move block specified amount
        function MoveBlock(this, x, y)
            this.position(:, 1) = this.position(:, 1) + x;
            this.position(:, 2) = this.position(:, 2) + y;
            this.moved = 1;
        end

        % rotate block, only returns value, does not rotate the block itself
        function rotatedPosition = GetRotatedBlockPosition(this, rotation)
            if size(this.position, 1) > 1 && size(rotation, 1) == 1 && size(rotation, 2)
                centerOfRotation(1) = floor(mean(this.position(:, 1)));
                centerOfRotation(2) = floor(mean(this.position(:, 2)));

                for i = 1 : size(this.position, 1)
                    vector = this.position(i, :) - centerOfRotation;
                    temp = vector(1);
                    vector(1) = rotation(1) * vector(2);
                    vector(2) = rotation(2) * temp;

                    rotatedPosition(i, :) = centerOfRotation + vector;
                end
            end
        end
    end
end