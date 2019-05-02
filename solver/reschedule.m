clear
flag = false;
filepath = sprintf('C:\\Users\\xwa24\\cse_project\\newins.json');
filename = sprintf('newsche.json');
while ~flag
    flag = final_one_short_JSON(filepath, filename);
end

exit