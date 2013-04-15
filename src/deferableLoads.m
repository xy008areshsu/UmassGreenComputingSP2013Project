% Deferable Loads Modeling: [relative deadline in hours, period in hours, 
% excution time in hours, power per period in kWh, relative starting point 
% within each period in hours]

% Assume period is integer, and can be divisible by T, no residual
ACCentral = [24, 24, 8, 56, 12];
refregerator = [2, 2, 2, 0.36, 0];

dishWasher = [24, 24, 2, 4, 0];
clothesWasher = [24, 24, 0.8, 7, 0];
clothesDryer = [24, 24, 1.5, 5, 0];

nonPreemptibleLoads = [dishWasher; clothesWasher; clothesDryer];
preemptibleLoads = [ACCentral; refregerator];