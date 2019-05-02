clear
disp("For all available time we checked, ")
allflag = false;
for i = 0:24
    filepath = sprintf('C:\\Users\\xwa24\\cse_project\\output%d.json',i);
    if exist(filepath, 'file') ~= 0
        [~, flag] = validate(filepath);
        if flag
            allflag = true;
            disp(num2str(i+1)+" is also an optional time with least cost");
        end
    end
end

if ~allflag
    disp("current time is the least cost one.");
end
exit