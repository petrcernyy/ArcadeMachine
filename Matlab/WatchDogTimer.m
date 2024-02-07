function WatchDogTimer(q1,q11)

    q2 = parallel.pool.PollableDataQueue;
    send(q11,q2);

    counter = 0;

    while (true)

        [data, datarcvd] = poll(q2,2);

        if datarcvd
            counter = 0;
        else
            counter = counter + 1;
        end

        if (counter > 5)
            system('taskkill /F /IM MATLAB.exe')
        end

    end
    
end
