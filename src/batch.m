clear; close all; clc;

%% 
% grid power prices for every hour, in cents per kWh
GridCost = [2.7; 2.4; 2.3; 2.3; 2.3; 2.5; 2.8; 3.4; 3.8; 5; 6.1; 6.8; 7.4; 
            8.2; 10; 10.9; 11.9; 10.1; 9.2; 7; 7; 5.2; 4.2; 3.5];
 
% HARD CODED green power predicted for every hour, in kWh, Should BE DONE USING ML!!!
% OR USING the FORMULA: E_t = B_t * (1 - CloudCover)
Green = [0; 0; 0; 0; 0; 0; 0.1; 0.2; 0.8; 1.2; 2.0; 2.5; 2.7; 3.2; 3.0; 
         2.5; 2.3; 1.7; 1.2; 0.5; 0; 0; 0; 0];


%% Job 1, Fixed nonDeferablePower
neededPower = 2;
LPBatteryOnly
LPBatterySolarNonDeferable
LPBatterySolarDeferableAllInOne

data = load('scheduleBattOnly.csv');
s = data(:, 1);
d = data(:, 2);
p = data(:, 3);
clear data;

data = load('scheduleSolarBatt.csv');
BattGreen1 = data(:, 1);
BattGrid1 = data(:, 2);
LoadBatt1 = data(:, 3);
LoadGrid1 = data(:, 4);
Grid1 = data(:, 5);
LoadGreen1 = data(:, 6);
NetGreen1 = data(:, 7);
Load1 = data(:, 8);
clear data;

data = load('scheduleSolarBattDefer.csv');
BattGreen2 = data(:, 1);
BattGrid2 = data(:, 2);
LoadBatt2 = data(:, 3);
LoadGrid2 = data(:, 4);
Grid2 = data(:, 5);
LoadGreen2 = data(:, 6);
NetGreen2 = data(:, 7);
Load2 = data(:, 8);
nonDeferableLoad = data(:, 9);
preemptibleLoadsSchedule = data(:, 10:11);
nonPreemptibleLoadsSchedule = data(:, 12);

plotData


% %% =============Job 2: Variable Non Deferable Power ======================
% clear; clc;
% 
% %% 
% % grid power prices for every hour, in cents per kWh
% GridCost = [2.7; 2.4; 2.3; 2.3; 2.3; 2.5; 2.8; 3.4; 3.8; 5; 6.1; 6.8; 7.4; 
%             8.2; 10; 10.9; 11.9; 10.1; 9.2; 7; 7; 5.2; 4.2; 3.5];
%  
% % HARD CODED green power predicted for every hour, in kWh, Should BE DONE USING ML!!!
% % OR USING the FORMULA: E_t = B_t * (1 - CloudCover)
% Green = [0; 0; 0; 0; 0; 0; 0.1; 0.2; 0.8; 1.2; 2.0; 2.5; 2.7; 3.2; 3.0; 
%          2.5; 2.3; 1.7; 1.2; 0.5; 0; 0; 0; 0];
% powerUpper = 20;
% cycle = (powerUpper - 4) / 2;
% costReduct = zeros(cycle, 3);
% index = 1;
% for neededPower = 4 : 2 : powerUpper
%     LPBatteryOnly
%     LPBatterySolarNonDeferable
%     LPBatterySolarDeferableAllInOne
%     data = load('scheduleBattOnly.csv');
%     costReduct(index, 1) = data(1, end);
%     data = load('scheduleSolarBatt.csv');
%     costReduct(index, 2) = data(1, end);
%     data = load('scheduleSolarBattDefer.csv');
%     costReduct(index, 3) = data(1, end);
%     index = index + 1;
% end
% 
% figure;
% hold on
% neededPower = 4 : 2 : 20;
% 
% plot(neededPower, costReduct(:, 1), 'g-','LineWidth',2);
% plot(neededPower, costReduct(:, 2), 'r-','LineWidth',2);
% plot(neededPower, costReduct(:, 3), 'b-','LineWidth',2);
% grid
% 
% title('Cost Reduction for different Deferable Load Power');
% xlabel('Deferable Load Power');
% ylabel('cost reduction in %');
% legend('Cost Reduction for LP Battery', 'Cost Reduction for LP Battery Solar', 'Cost Reduction for LP Battery Solar Deferable', 'Location', 'SouthOutside')
% 

    

