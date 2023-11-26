classdef SimpleGame
    properties
        Position
    end
    
    methods
        function obj = SimpleGame()
            obj.Position = [0, 0];
        end
        
        function move(obj, direction)
            switch direction
                case 'up'
                    obj.Position(2) = obj.Position(2) + 1;
                case 'down'
                    obj.Position(2) = obj.Position(2) - 1;
                case 'left'
                    obj.Position(1) = obj.Position(1) - 1;
                case 'right'
                    obj.Position(1) = obj.Position(1) + 1;
            end
        end
        
        function draw(obj)
            plot(obj.Position(1), obj.Position(2), 'ro', 'MarkerSize', 10);
            xlim([-10, 10]);
            ylim([-10, 10]);
            grid on;
            title('Simple Game');
        end
    end
end