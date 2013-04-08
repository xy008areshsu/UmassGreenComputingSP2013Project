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

clear ; close all;

%% ==================== Parameters Initialization =========================
% number of time intervals
T = 24; 

% Hard coded power consumption prediction for the following day, 24 hours
% There should be predicted power consumption for each time interval using
% ML techniques, which is missing here
Load = hardCodedPower('./data/2012-Jul-30.csv', T);

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
%% ===========================Separate Bounds==============================

% lowerBounds(:, 1) = BattGreen; 
% lowerBounds(:, 2) = BattGrid;
% lowerBounds(:, 3) = LoadBatt;
% lowerBounds(:, 4) = LoadGrid;
% lowerBounds(:, 5) = Grid;
% lowerBounds(:, 6) = LoadGreen;
% lowerBounds(:, 7) = NetGreen;
lowerBounds = zeros(T, 7);

% upperBounds(:, 1) = BattGreen; 
% upperBounds(:, 2) = BattGrid;
% upperBounds(:, 3) = LoadBatt;
% upperBounds(:, 4) = LoadGrid;
% upperBounds(:, 5) = Grid;
% upperBounds(:, 6) = LoadGreen;
% upperBounds(:, 7) = NetGreen;
upperBounds = Inf(T, 7);

% unroll into vectors: 
% 1:24 = BattGreen;
% 25:48 = BattGrid;
% 49:72 = LoadBatt;
% 73: 96 = LoadGrid;
% 97: 120 = Grid;
% 121: 144 = LoadGreen;
% 145: 168 = NetGreen;
lowerBounds = lowerBounds(:);
upperBounds = upperBounds(:);


%% ====================Linear Inequality Constraints======================
% T = 24 time intervals, linear inequality matrix and vector A*x <= b, 
% 4 * T = 96 inequality constraints, 
% 7 * T = 168 varibles: see above
A = zeros(4 * T, 7 * T);
b = zeros(4 * T, 1);

% Total battery charge rate cannot be higher than BattCapa / 4: 
% BattGreen_t + BattGrid_t <= BattCapa / 4, constraints 1 to 24
for i = 1 : T
    A(i, i) = 1;                             % BattGreen_t
    A(i, i + T) = 1;                         % BattGrid_t
    b(i) = BattCapa / 4;           
end
        
% Power discharged from the battery is never greater than the power charged
% to the battery: 
% sum(LoadBatt_t) - BattE * sum(BattGreen_t + BattGrid_t) <= 0, constraints
% 24 to 48
for i = T + 1 : 2 * T
    for j = 1 : i
        A(i, j) = -BattE;                    % -BattE * sum(BattGreen_t)
        A(i, j + T) = -BattE;                % -BattE * sum(BattGrid_t)
        A(i, j + 2 * T) = 1;                 % sum(LoadBatt_t)
    end
    b(i) = 0;
end

% The energy stored in battery, which is the difference between the energy
% charged to or discharged from the battery over the previous time
% intervals, cannot be greater than its capacity:
% sum(BattGreen_t) + sum(BattGrid_t) - (1/BattE) * sum(LoadBatt_t) <=
% BattCapa, constraints 49 to 72
for i = 2 * T + 1 : 3 * T
    for j = 1 : i
        A(i, j) = 1;                          % sum(BattGreen_t)
        A(i, j + T) = 1;                      % sum(BattGrid_t)
        A(i, j + 2 * T) = -(1/BattE);         % -(1/BattE) * sum(LoadBatt_t)
    end
    b(i) = BattCapa;
end


% The renewable pwer, Green_t, may be used to run the LoadGreen_t, to charge
% the battery(BattGreen_t), and/or net metering(NetGreen_t):
% LoadGreen_t + BattGreen_t + NetGreen_t <= Green_t, constraints 73 to 96
for i = 3 * T + 1 : 4 * T
    A(i, i - 3 * T) = 1;                     % BattGreen_t
    A(i, i - 3 * T + 5 * T) = 1;             % LoadGreen_t
    A(i, i - 3 * T + 6 * T) = 1;             % NetGreen_t
    b(i) = Green(i - 3 * T);                 % Green_t
end

clear i j;


%% =========================Linear Equality Constraints====================
% T = 24 time intervals, linear equality matrix and vector Aeq*x = beq, 
% 2 * T = 48 equality constraints, 
% 7 * T = 168 varibles: see above
Aeq = zeros(2 * T, 7 * T);
beq = zeros(2 * T, 1);

% Three sources can be used to power the house, LoadGreen_t, LoadGrid_t,
% and/or LoadBatt_t: LoadBatt_t + LoadGrid_t + LoadGreen_t = Load_t,
% constraints 1 to 24
for i = 1 : T
    Aeq(i, i + 2 * T) = 1;                  % LoadBatt_t
    Aeq(i, i + 3 * T) = 1;                  % LoadGrid_t
    Aeq(i, i + 5 * T) = 1;                  % LoadGreen_t
    beq(i) = Load(i);                       % Load_t
end

% The grid can be used to power the load and/or charge the battery:
% LoadGrid_t + BattGrid_t - Grid_t = 0, constraints 25 to 48
for i = T + 1 : 2 * T
    Aeq(i, i - T + T) = 1;                  % BattGrid_t
    Aeq(i, i - T + 3 * T) = 1;              % LoadGrid_t
    Aeq(i, i - T + 4 * T) = -1;             % Grid_t
    beq(i) = 0;                             
end


clear i;
        

%% ========================Objective Function(Minimize)====================
% objective function: Total electricity cost: m = sum(GridCost_t * Grid_t 
% - alpha * GridCost_t * NetGreen_t), minimize it
m = zeros(7 * T, 1); 

for i = 1 : T
    m(i + 4 * T) = GridCost(i);          % GridCost_t * Grid_t
    m(i + 6 * T) = -alpha * GridCost(i); % -alpha * GridCost_t * NetGreen_t
end

clear i;

%% =======================LP Solver ======================================
[x cost] = linprog(m, A, b, Aeq, beq, lowerBounds, upperBounds);
BattGreen = reshape(x(1 : T), T, 1);
BattGrid = reshape(x(T + 1: 2 * T), T, 1);
LoadBatt = reshape(x(2 * T + 1 : 3 * T), T, 1);
LoadGrid = reshape(x(3 * T + 1 : 4 * T), T, 1);
Grid = reshape(x(4 * T + 1 : 5 * T), T, 1);
LoadGreen = reshape(x(5 * T + 1 : 6 * T), T, 1);
NetGreen = reshape(x(6 * T + 1 : 7 * T), T, 1);
cost = cost / 100;     % convert from cents to dollars

%% =======================Plot Results and Write to File===================
originalPrice = sum(Load.*GridCost) / 100;
fprintf('The Electricity Bill without Smart Charge per Day is: $%f\n', originalPrice);
fprintf('The Electricity Bill with Smart Charge Solar-Battery per Day is: $%f\n', cost);
fprintf('Total cost reduction is: %f%%\n', (originalPrice - cost) / originalPrice * 100);

scheduleSolarBatt = [BattGreen, BattGrid, LoadBatt, LoadGrid, Grid, LoadGreen, NetGreen, Load];
csvwrite('scheduleSolarBatt.csv', scheduleSolarBatt);
