%% Green Computing Project: Energy Efficiency in Smart Homes
% Parameters out of our control:
%   Load_t: average predicted required power for each time interval, in kWh.
%   (if the workload is deferable, we might add a new variable WorkLoad_t as
%   the offered load in each time interval)
%   T: number of time intervals
%   BattCapa: battery's usable capacity, in kWh
%   BattE: battery charging efficiency
%   GridCost: grid energy price in real time, in cents per kWh
%   Green_t: amount of preditced green power available in each time interval
%   alpha: percentage of retail price paid in net metering
% -------------------------------------------------------------------------
% Variables under our control for optimization:
%   LoadGreen_t: amount of green power to be used for load
%   LoadGrid_t: amount of grid power to be used for load
%   LoadBatt_t: amount of battery power to be used for load
%   BattGreen_t: amount of green power to be used for charging battery
%   BattGrid_t: amount of grid power to be used for charging battery
%   NetGreen_t: amount of green power to be used in net metering 
%   Grid_t: amount of grid power to be used for any purpose
%   bin_t: ensure mutual exclusive
%   preemptibleLoadsSchedule
%   nonPreemptibleLoadsSchedule



%% ==================== Parameters Initialization =========================
% number of time intervals
T = 24; 

% Non Deferable Load Pattern
% Hard coded power consumption prediction for the following day, 24 hours
% There should be predicted power consumption for each time interval using
% ML techniques, which is missing here
nonDeferLoad = hardCodedPower('./data/2012-Jul-30.csv', T);

% DeferableLoads Pattern, pre or nonPreemptible
deferableLoads;

% Assume only one non preemptible job for now, dishwahser
job = dishWasher;
deadline = job(1);
period = job(2);
execTime = job(3);
powerPerCycle = job(4);

%in kWh, battery's usable capacity
BattCapa = 30;  

% battery charging efficiency
BattE = 0.855; 

% grid power prices for every hour, in cents per kWh
GridCost = [2.7; 2.4; 2.3; 2.3; 2.3; 2.5; 2.8; 3.4; 3.8; 5; 6.1; 6.8; 7.4; 
            8.2; 10; 10.9; 11.9; 10.1; 9.2; 7; 7; 5.2; 4.2; 3.5];
 
% HARD CODED green power predicted for every hour, in kWh, Should BE DONE USING ML!!!
% OR USING the FORMULA: E_t = B_t * (1 - CloudCover)
Green = [0; 0; 0; 0; 0; 0; 0.1; 0.2; 0.8; 1.2; 2.0; 2.5; 2.7; 3.2; 3.0; 
         2.5; 2.3; 1.7; 1.2; 0.5; 0; 0; 0; 0];
 
% alpha
alpha = 0.4;

% Infinite number value, for MILP
infVal = 10;

%% =========Convert Non Preemptible Loads into Non Deferable Loads=========
% Try every possible time scheduling for Non Preemptible Loads, converting
% into Non Deferable Loads
nonDeferLoadChoice = zeros(T - execTime + 1, T);
costs = zeros(T - execTime + 1, 1);
powerPerInterval = powerPerCycle / execTime;

% Solve each possible non preemtible laods scheduling
for i = 1 : T - execTime + 1
    nonDeferLoadChoice(i, :) = mergeNonPreemtibleToNonDefer(nonDeferLoad, powerPerInterval, i, execTime)';
    [~, costs(i), ~, ~] = LPBatterySolarDeferableFunction(T, nonDeferLoadChoice(i, :)', GridCost, BattCapa, BattE, Green, alpha, infVal,preemptibleLoads);
end

% Get the minimum cost for these schedulings
[minCost, minIndex ] = min(costs);
nonPreemptibleLoadsSchedule = zeros(T, 1);
nonPreemptibleLoadsSchedule(minIndex : minIndex + execTime - 1) = powerPerInterval;
[x cost numOfPreemptible info] = LPBatterySolarDeferableFunction(T, nonDeferLoadChoice(minIndex, :)', GridCost, BattCapa, BattE, Green, alpha, infVal,preemptibleLoads);

%% ================ Results and Plots =====================================
clear i;
BattGreen = reshape(x(1 : T), T, 1);
BattGrid = reshape(x(T + 1: 2 * T), T, 1);
LoadBatt = reshape(x(2 * T + 1 : 3 * T), T, 1);
LoadGrid = reshape(x(3 * T + 1 : 4 * T), T, 1);
Grid = reshape(x(4 * T + 1 : 5 * T), T, 1);
LoadGreen = reshape(x(5 * T + 1 : 6 * T), T, 1);
NetGreen = reshape(x(6 * T + 1 : 7 * T), T, 1);
bin = reshape(x(7 * T + 1 : 8 * T), T, 1);
preemptibleLoadsSchedule = reshape(x(8 * T + 1 : (8 + numOfPreemptible) * T), T, numOfPreemptible);

if abs(cost - minCost) <= 0.01
    ACPower = zeros(T, 1);
    refregPower = zeros(T, 1);
    dishwashserPower = zeros(T, 1);
    ACPower(16:24) = ACCentral(4) / ACCentral(2);
    refregPower(1:24) = refregerator(4) / refregerator(2);
    dishwashserPower(17: 17 + execTime - 1) = powerPerCycle / execTime;
    originalPrice = sum((nonDeferLoad + ACPower + refregPower + dishwashserPower) .* GridCost) / 100;
    info
    fprintf('The Electricity Bill originally per Day is: $%f\n', originalPrice);
    fprintf('The Electricity Bill with Green Switch: the Home Adaption per Day is: $%f\n', cost);
    fprintf('Total cost reduction is: %f%%\n', (originalPrice - cost) / originalPrice * 100);
    costReductArr = ones(T, 1) * ((originalPrice - cost) / originalPrice * 100);
    scheduleSolarBattDefer = [BattGreen, BattGrid, LoadBatt, LoadGrid, Grid, LoadGreen, NetGreen, (nonDeferLoad + preemptibleLoadsSchedule(:,1) +  preemptibleLoadsSchedule(:,2) + nonPreemptibleLoadsSchedule), nonDeferLoad, preemptibleLoadsSchedule, nonPreemptibleLoadsSchedule, costReductArr];
    csvwrite('scheduleSolarBattDefer.csv', scheduleSolarBattDefer);
end



    