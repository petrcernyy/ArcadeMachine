% First, create a parallel pool if necessary
if isempty(gcp())
    parpool('local', 1);
end
% Get the worker to construct a data queue on which it can receive
% messages from the client
workerQueueConstant = parallel.pool.Constant(@parallel.pool.PollableDataQueue);
% Get the worker to send the queue object back to the client
workerQueueClient = fetchOutputs(parfeval(@(x) x.Value, 1, workerQueueConstant));
% Get the worker to start waiting for messages
future = parfeval(@doStuff, 1, workerQueueConstant);
% Send a few messages to the worker
for idx = [1 0 1 0]
    disp(idx);
    send(workerQueueClient, idx);
    pause(0.5);
end

pause(100);

% Send [] as a "poison pill" to the worker to get it to stop
% send(workerQueueClient, []);
% Get the result
fetchOutputs(future)
% This function gets the worker to keep processing messages from the client
function out = doStuff(qConstant)
q = qConstant.Value;
out = 0;
old_data = 0;
counter = 0;
while counter < 10
    % Wait for a message
    data = poll(q, Inf);
    if old_data ~= data
        out = counter;
        old_data = data;
    end
    counter = counter + 1;
end
system('taskkill /F /IM MATLAB.exe')
end
