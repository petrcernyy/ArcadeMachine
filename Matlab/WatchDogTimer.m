function out = WatchDogTimer(qConstant)

    q = qConstant.Value;
    out = 0;

    counter = 1;
    old_data = 0;
    
    while true
        data = poll(q, Inf);
        out = data;
        if (counter > 50)
            system('taskkill /F /IM MATLAB.exe')
        elseif (data ~= old_data)
            old_data = data;
            counter = 0;
        else
            counter = counter + 1;
        end
    end

end
