%% Constant parameters initialization
C = 30;  %in kWh, battery's usable capacity

% in cents per kWh, cost per kWh
c = [2.7; 2.4; 2.3; 2.3; 2.3; 2.5; 2.8; 3.4; 3.8; 5; 6.1; 6.8; 7.4; 8.2; 10;
     10.9; 11.9; 10.1; 9.2; 7; 7; 5.2; 4.2; 3.5];
 
% number of time intervals
T = 24;     
 
% Hard coded power consumption prediction for the following day, 24 hours
% There should be predicted power consumption for each time interval using
% ML techniques, which is missing here
powerPredict = hardCodedPower('2012-Apr-15.csv', T);

% battery charging efficiency
e = 0.855;  



