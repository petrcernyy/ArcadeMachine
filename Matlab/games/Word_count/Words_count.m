clc,clear,close;

%loading file
str = fileread('HGG_sample.txt');

%convert to string
str = string(str);

%Insert text after every "house"
str = insertAfter(str,"house"," (Arthur's house)");

%save txt file
fid = fopen('HGG_sample_edited.txt','w');
fprintf(fid,'%s%n',str);
fclose(fid);

%split lines and delete empty strings
str = splitlines(str);
str(str == "") = [];

%chosen characters replaced by space
p = [".","?","!",",",";",":","""","(",")"];
str = replace(str,p," ");
str = strip(str);

%split words by space
words = 0;
for i = 1 : length(str)
    words = [words; split(str(i))];
end

%Find unique words
words = lower(words);
uwords = unique(words);

%Count occurance of the unique words
for i = 1 : length(uwords)
    numOfOccurance(i) = sum(uwords(i) == words); 
end

%calculate how much percent of the text are the unique words
prcnt = numOfOccurance ./ numel(words) * 100;

%creating table with 3 columns
T = table(uwords, numOfOccurance',prcnt');
T.Properties.VariableNames = ["Words" "Number of occurance" "Percent of the text"];

%sorts rows by number of occurance
T = sortrows(T,2)

