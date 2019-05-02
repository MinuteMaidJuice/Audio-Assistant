data = loadjson('C:/Users/Ray/Documents/MATLAB/research/Step4_validate/schedule.json');    
url = 'http://localhost/myfiles/schedule.php';
%options = weboptions('MediaType','application/json','ContentType','json');
options = weboptions;
response = webwrite(url, data, options);

fileID = fopen('D:/XAMPP/htdocs/myfiles/test.html','w');
fprintf(fileID,response);
fclose(fileID);

system('start http://localhost/myfiles/test.html');