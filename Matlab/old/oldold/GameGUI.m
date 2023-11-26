classdef GameGUI < handle
    properties
        Figure
        Axis
        ImportButton
        Game
    end
    
    methods
        function obj = GameGUI()
            obj.Figure = figure('Position', [100, 100, 600, 400]);
            obj.Axis = axes('Parent', obj.Figure, 'Position', [0.1, 0.2, 0.8, 0.7]);
            obj.ImportButton = uicontrol('Style', 'pushbutton', 'String', 'Import Game', ...
                                         'Position', [50, 50, 100, 30], 'Callback', @obj.importGame);
            obj.Game = [];
        end
        
        function importGame(obj, ~, ~)
            [filename, path] = uigetfile('*.mat', 'Select a MATLAB game file');
            if filename
                gameData = load(fullfile(path, filename));
                if isfield(gameData, 'Game')
                    obj.Game = gameData.Game;
                    obj.updateGame();
                else
                    msgbox('Invalid game file. Game object not found.', 'Error', 'error');
                end
            end
        end
        
        function updateGame(obj)
            if ~isempty(obj.Game)
                axes(obj.Axis);
                obj.Game.draw();
                set(obj.Figure, 'KeyPressFcn', @obj.keyPressCallback);
            end
        end
        
        function keyPressCallback(obj, ~, event)
            if ~isempty(obj.Game)
                switch event.Key
                    case 'uparrow'
                        obj.Game.move('up');
                    case 'downarrow'
                        obj.Game.move('down');
                    case 'leftarrow'
                        obj.Game.move('left');
                    case 'rightarrow'
                        obj.Game.move('right');
                end
                obj.updateGame();
            end
        end
    end
end