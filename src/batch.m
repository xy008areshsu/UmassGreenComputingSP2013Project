LPBatteryOnly
LPBatterySolarNonDeferable

data = load('scheduleBattOnly.csv');
s = data(:, 1);
d = data(:, 2);
p = data(:, 3);
clear data;

data = load('scheduleSolarBatt.csv');
BattGreen = data(:, 1);
BattGrid = data(:, 2);
LoadBatt = data(:, 3);
LoadGrid = data(:, 4);
Grid = data(:, 5);
LoadGreen = data(:, 6);
NetGreen = data(:, 7);
Load = data(:, 8);
clear data;

plotData

