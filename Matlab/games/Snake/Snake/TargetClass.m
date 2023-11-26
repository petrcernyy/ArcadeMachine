classdef TargetClass < handle
    properties (Access = private)
        coordinates = [0, 0]';
        ax = 0;
        markerSize = 0;
        xLimit = 0;
        yLimit = 0;
        lineObject = 0;
    end

    methods (Access = public)
        % constructor
        function this = TargetClass(ax, markerSize, xLimit, yLimit)
            this.ax = ax;
            this.markerSize = markerSize;
            this.xLimit = xLimit;
            this.yLimit = yLimit;

            this.lineObject = line(this.ax, "Marker", "s", "MarkerSize", this.markerSize, "MarkerFaceColor", "blue", "MarkerEdgeColor", "blue");
        end

        % generate new target position, must be called after constructor as well
        function GenerateNew(this, avoidCoordinates)
            exitRoutine = 0;
            while ~exitRoutine
                % generate new coordinates
                this.coordinates(1, 1) = randi(this.xLimit);
                this.coordinates(2, 1) = randi(this.yLimit);
                match = 0;
                
                % check whether coordinates match those to avoid
                for i = 1 : size(avoidCoordinates, 2)
                    if this.coordinates(1, 1) == avoidCoordinates(1, i) && this.coordinates(2, 1) == avoidCoordinates(2, i)
                        match = 1;
                    end
                end
                
                % if coordinates don't match those to avoid, exit
                if ~match
                    exitRoutine = 1;
                    set(this.lineObject, "XData", this.coordinates(1, 1), "YData", this.coordinates(2, 1));
                end
            end
        end

        % coordinates getter
        function coords = GetCoordinates(this)
            coords = this.coordinates;
        end
    end
end