% Deferable Loads Modeling: [relative deadline in hours, period in hours, 
% excution time in hours, energy per period in kWh]

% Assume period is integer, and can be divisible by T, no residual, and
% deadline is equal to period
ACCentral = [24, period, 8, 56 / (24 / period)];
%refregerator = [2, 2, 1, 0.36];

dishWasher = [24, 24, 2, neededPower];
clothesWasher = [24, 24, 0.8, 7];
clothesDryer = [24, 24, 1.5, 5];
%hahaha = [24, 3, 1.5, 5];

nonPreemptibleLoads = [dishWasher; clothesWasher; clothesDryer];
preemptibleLoads = [ACCentral];