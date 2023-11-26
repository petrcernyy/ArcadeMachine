classdef SerialReader
    properties (SetAccess = private)
        data
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
            chardata = convertStringsToChars(this.data);
            this.myUI.receiveSerialData(chardata);

        end

    end
end