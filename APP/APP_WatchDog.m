classdef APP_WatchDog < handle

    properties
        APP_UI

        WatchDogTimerCounter = 0
        workerQueueConstant1
        workerQueueConstant2
        workerQueueClient
        future
        returnVal = 0
    end

    methods
        function this = APP_WatchDog(APP_UI)

            this.APP_UI = APP_UI;

            this.workerQueueConstant1 = parallel.pool.DataQueue;
            afterEach(this.workerQueueConstant1, @this.ReturnValueUpdate);
            this.workerQueueConstant2 = parallel.pool.PollableDataQueue;
            this.future = parfeval(@WatchDogTimer,0,this.workerQueueConstant1,this.workerQueueConstant2);
            this.workerQueueClient = poll(this.workerQueueConstant2,10);

        end

        function WatchDogUpdate(this)

            if (this.WatchDogTimerCounter == 1)
                this.WatchDogTimerCounter = 0;
            elseif (this.WatchDogTimerCounter == 0)
                this.WatchDogTimerCounter = 1;
            end
            send(this.workerQueueClient, this.WatchDogTimerCounter);

        end

        function ReturnValueUpdate(this, data)

            this.returnVal = data;

        end
    end
end