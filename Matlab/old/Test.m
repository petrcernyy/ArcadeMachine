classdef Test
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Axis
        Joystick
    end

    methods
        function this = Test(hAxis, hJoystick)
            this.Axis = hAxis;
            this.Joystick = hJoystick;
            

        end

        function plotData_obj(this,i)
                plot(this.Axis, [5 2], i);
        end
    end
end