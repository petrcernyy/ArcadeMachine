

fig = uifigure();
btn = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Button', ...
    'Callback', @myCallback, ...
    'BackgroundColor', [0 0 0], ... % Set background color to match figure
    'ForegroundColor', [0.8 0.8 0.8], ... % Set font color to black
    'Enable', 'off'); % Button is initially disabled


set(fig, 'KeyPressFcn', @(src, event) handleKeyPress(event, btn));

function handleKeyPress(event, btn)
    if strcmp(event.Key, 'space')
            myCallback(btn, []);
    end
end

function myCallback(hObject, eventdata)
    % Your callback code here
    disp('Button pressed!');
end