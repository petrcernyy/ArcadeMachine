classdef Padlle < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        X
        Y
        Width = 10
        Height = 100
        PanelWidth
        PanelHeight
        PadllePlot

    end

    methods
        function this = Padlle(Pong, side)
                this.PanelHeight = Pong.Height;
                this.PanelWidth = Pong.Width;

                this.Y = this.PanelHeight/2;
                if(side)
                    this.X = 15;
                else
                    this.X = this.PanelWidth - 15;
                end

                this.PadllePlot = rectangle('Parent', Pong.axis, 'Position', [this.X-(this.Width/2), this.Y-(this.Height/2), this.Width, this.Height], 'FaceColor', 'g');
        end

        function moveUp(this)
                this.Y = this.Y + 10;
                if (this.Y+this.Height/2 > this.PanelHeight)
                    this.Y = this.PanelHeight - this.Height/2;
                end
        end

        function moveDown(this)
                this.Y = this.Y - 10;
                if (this.Y-this.Height/2 < 0)
                    this.Y = this.Height/2;
                end
        end

        function plotPadlle(this)
                set(this.PadllePlot, 'Position', [this.X-(this.Width/2), this.Y-(this.Height/2), this.Width, this.Height]);
        end
    end
end