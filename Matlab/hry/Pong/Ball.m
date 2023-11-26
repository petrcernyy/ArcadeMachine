classdef Ball < handle
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        X
        Y
        Vx
        Vy
        Radius = 15
        PanelWidth
        PanelHeight
        BallPlot
    end

    methods
        function this = Ball(Pong)
                this.PanelWidth = Pong.Width;
                this.PanelHeight = Pong.Height;
                this.X = this.PanelWidth/2;
                this.Y = this.PanelHeight/2;
                angle = randi([-45 45], 1)*(pi/180);
                this.Vx = 3*cos(angle);
                this.Vy = 3*sin(angle);

                if(rand(1) > 0.5)
                    this.Vx = -1*this.Vx;
                end
                
                this.BallPlot = rectangle('Parent', Pong.axis, 'Position', [this.X this.Y this.Radius this.Radius], 'Curvature', [1 1], 'FaceColor', 'r');
        end

        function update(this)

                this.X = this.X + this.Vx;
                this.Y = this.Y + this.Vy;

        end

        function Reset(this)

                this.X = this.PanelWidth/2;
                this.Y = this.PanelHeight/2;

        end

        function plotBall(this)
                set(this.BallPlot, 'Position', [this.X this.Y this.Radius this.Radius]);
        end
    end
end