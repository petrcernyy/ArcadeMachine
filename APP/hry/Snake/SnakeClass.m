classdef SnakeClass < handle
    properties (Access = public)
        direction = 0;
    end
    
    properties (Access = private)
        ax = 0;
        markerSize = 0
        xLimit = 0;
        yLimit = 0;
        startLength = 0;
        coordinates = 0;
        lineObjects = 0;
    end

    methods (Access = public)
        % constructor
        function this = SnakeClass(ax, markerSize, xLimit, yLimit, startLength, startDirection)
            % asign constructor values
            this.startLength = startLength;
            this.direction = startDirection;
            this.ax = ax;
            this.markerSize = markerSize;
            this.xLimit = xLimit;
            this.yLimit = yLimit;

            % calculate starting position of snake
            for i = 1 : this.startLength
                this.coordinates(1, i) = ceil(this.xLimit / 2) + (ceil(this.startLength / 2) - i) * cos(this.direction * pi / 2);
                this.coordinates(2, i) = ceil(this.yLimit / 2) + (ceil(this.startLength / 2) - i) * sin(this.direction * pi / 2);
            end

            % create line objects
            for i = 1 : this.startLength
                this.lineObjects(i) = line(this.ax,...
                    "Marker", "s",...
                    "MarkerSize", this.markerSize,...
                    "MarkerFaceColor", "black",...
                    "MarkerEdgeColor", "black"...
                );
            end
            set(this.lineObjects(1), "MarkerFaceColor", "red", "MarkerEdgeColor", "red");
        end

        % calculates new position of snake
        function CalculateNewPosition(this)
            % move body one block
            for i = size(this.coordinates, 2) : -1 : 2
                this.coordinates(:, i) = this.coordinates(:, i - 1);
            end

            % calculate new position of head based on direction
            this.coordinates(1, 1) = round(this.coordinates(1, 1) + cos(this.direction * pi / 2));
            this.coordinates(2, 1) = round(this.coordinates(2, 1) + sin(this.direction * pi / 2));

            % check whether head has left the playing field, if so, move it to the other side
            if this.coordinates(1, 1) < 0
                this.coordinates(1, 1) = this.xLimit;
            elseif this.coordinates(1, 1) > this.xLimit
                this.coordinates(1, 1) = 0;
            end
            
            if this.coordinates(2, 1) < 0
                this.coordinates(2, 1) = this.yLimit;
            elseif this.coordinates(2, 1) > this.yLimit
                this.coordinates(2, 1) = 0;
            end
        end

        % updates graphics
        function UpdateGraphics(this)
            for i = 1 : length(this.lineObjects)
                set(this.lineObjects(i), "XData", this.coordinates(1, i), "YData", this.coordinates(2, i));
            end
        end
        
        % extends snake's body
        function Extend(this, extension)
            for i = 1 : extension
                this.coordinates(:, end + 1) = 0;

                this.lineObjects(end + 1) = line(this.ax,...
                    "Marker", "s",...
                    "MarkerSize", this.markerSize,...
                    "MarkerFaceColor", "black",...
                    "MarkerEdgeColor", "black"...
                );
            end
        end

        % coordinates getter
        function coords = GetCoordinates(this)
            coords = this.coordinates;
        end

        % check whether has is inside snkaes body
        function match = CheckHeadInBody(this)
            match = 0;
            for i = 2 : size(this.coordinates, 2)
                if this.coordinates(:, 1) == this.coordinates(:, i)
                    match = 1;
                end
            end
        end

        % check whether head matches specified coordinates
        function matched = CheckHead(this, inputCoordinates)
            matched = 0;
            if this.coordinates(:, 1) == inputCoordinates;
                matched = 1;
            end
        end
    end
end