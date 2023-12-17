clc, clear

global counter
counter = 0;

WatchDogTimer = timer('ExecutionMode', 'fixedRate', 'Period', 2, ...
                                'TimerFcn', @(~,~) WatchDogUpdate);

start(WatchDogTimer);

whileloop();



function WatchDogUpdate()

    global counter
    counter = counter + 1;
    disp(counter);
    

end

function whileloop()

    while(1)
        a = 10;
    end

end