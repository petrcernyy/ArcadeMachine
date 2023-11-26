clc, clear

device = serialport("COM4", 9600);

configureCallback(device, "terminator", @readSerialData);


function readSerialData(scr, evt)

    data = readline(scr)

end

