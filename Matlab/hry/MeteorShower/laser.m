classdef laser < handle
  properties
    velocity = 5 %5 at 15 FPS
    posx
    posy
    shape = '|'
    body
  end
  
  methods
    function obj = laser()
    end
    function spawn(obj, hAx)
      obj.body = text(hAx, obj.posx, obj.posy+5, obj.shape, 'HorizontalAlignment', 'center', 'Color', [1 1 1]);
    end
    function move(obj, hAx)
      obj.posy = obj.posy + obj.velocity;
      delete(obj.body);
      obj.body = text(hAx, obj.posx, obj.posy, obj.shape, 'HorizontalAlignment', 'center', 'Color', [1 1 1]);
    end
  end
end