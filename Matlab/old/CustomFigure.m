classdef CustomFigure < handle
    properties
        Figure
        Axis
    end
    
    methods
        function obj = CustomFigure()
            % Constructor: Create a figure and axis
            obj.Figure = figure;
            obj.Axis = axes;
            
            % Set the close request function to call customCloseFunction
            set(obj.Figure, 'CloseRequestFcn', @(src, event) obj.customCloseFunction(src, event));
        end
        
        function customCloseFunction(obj, ~, ~)
            % Custom function to be executed when the figure is closed
            disp('Special function executed when the figure is closed!');
            % Perform additional actions or cleanup here if needed
            
            % Close the figure
            delete(obj.Figure);
        end
    end
end