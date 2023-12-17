function WatchDogTimer(q1,q11)

    q2 = parallel.pool.PollableDataQueue;
    send(q11,q2);
    while (true)
        [data, datarcvd] = poll(q2,10);
        if datarcvd
            send(q1,data);
        end
    end
    
end
