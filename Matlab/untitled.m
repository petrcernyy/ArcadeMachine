if isempty(gcp())
    parpool('local', 1);
end

q1 = parallel.pool.DataQueue;
afterEach(q1,@disp);

q11 = parallel.pool.PollableDataQueue;

parfeval(@worker1,0,q1,q11);
q2 = poll(q11,10);

for i = 1:10
    send(q2,i);
end

pause(100);

function worker1(q1,q11)
    nodatacounter = 0;
    q2 = parallel.pool.PollableDataQueue;
    send(q11,q2);
    while(nodatacounter < 10)
        [data, datarcvd] = poll(q2,10);
        if datarcvd
            send(q1,1);
            nodatacounter = 0;
        else
            nodatacounter = nodatacounter + 1;
        end
    end
    system('taskkill /F /IM MATLAB.exe')
end