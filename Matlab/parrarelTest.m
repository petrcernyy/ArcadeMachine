clc, clear

p = gcp();
f = parfeval(p,@myFunction,0);

ok = wait(f,'finished', 2);
if ~ok
    disp('Did not finish in time.')
else
    disp('Did finish in time.')
end



function myFunction()
    pause(3);
end