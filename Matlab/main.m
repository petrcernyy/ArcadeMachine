clc, clear

% if isempty(gcp())
%     parpool('local', 1);
% end
% 
% workerQueueConstant = parallel.pool.Constant(@parallel.pool.PollableDataQueue);
% workerQueueClient = fetchOutputs(parfeval(@(x) x.Value, 1, workerQueueConstant));
% future = parfeval(@WatchDogTimer, 1, workerQueueConstant);

myUI = UI.createUIClassInstance();


