classdef SerialReader
    properties (SetAccess = private)
        data
        flag = 1
    end

    properties (Access = public)
        device
        myUI
    end

    methods
        function this = SerialReader(hUI)
            this.myUI = hUI;
               availablePorts = serialportlist;
               for i = 1:length(availablePorts)
                    try
                        this.device = serialport(availablePorts(i), 9600);
                    catch

                    end
               end

               configureCallback(this.device, "terminator", @this.readSerialData);
               flush(this.device);
        end

        function readSerialData(this, ~, ~)
            this.data = readline(this.device);
            chardata = convertStringsToChars(this.data)
            if (str2double(chardata(1)) == Enums.Data)
                this.flag = 1;
                this.myUI.receiveSerialData(chardata(2:end));
            elseif (str2double(chardata(1)) == Enums.User) && (this.flag == 1)
                this.flag = 0;
                this.myUI.dabataseData(chardata(3:end));
            end

        end

        function toggleBlueLed(this, ~, ~)

            writeline(this.device, "3");

        end

        function onBlueLed(this, ~, ~)

            writeline(this.device, "4");

        end

        function offBlueLed(this, ~, ~)

            writeline(this.device, "5");

        end

        function toggleRedLed(this, ~, ~)

            writeline(this.device, "0");

        end

        function onRedLed(this, ~, ~)

            writeline(this.device, "1");

        end

        function offRedLed(this, ~, ~)

            writeline(this.device, "2");

        end

    end
end