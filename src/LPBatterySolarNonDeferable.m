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

infVal = 10;

% DeferableLoads Pattern, pre or nonPreemptible
deferableLoads;

% Assume only one non preemptible job for now, dishwahser
job = dishWasher;
deadline = job(1);
period = job(2);
execTime = job(3);
powerPerCycle = job(4);

% Merge AC, refregerator, dishwahser into Non deferable Loads
ACPower = zeros(T, 1);
refregPower = zeros(T, 1);
dishwashserPower = zeros(T, 1);
% Assume all deferable loads are spreaded evenly in their cycles
ACPower(16:24) = ACCentral(4) / ACCentral(2);
refregPower(1:24) = refregerator(4) / refregerator(2);
% Assume dishwahser is working at 8 to 10pm
dishwashserPower(17: 17 + execTime - 1) = powerPerCycle / execTime;
Load = Load + ACPower + refregPower + dishwashserPower;

%% ===========================Separate Bounds==============================

% lowerBounds(:, 1) = BattGreen;  0
% lowerBounds(:, 2) = BattGrid;   T
% lowerBounds(:, 3) = LoadBatt;   2T
% lowerBounds(:, 4) = LoadGrid;   3T 
% lowerBounds(:, 5) = Grid;       4T
% lowerBounds(:, 6) = LoadGreen;  5T
% lowerBounds(:, 7) = NetGreen;   6T
% lowerBounds(:, 8) = bin; ensure mutual exclusive 7T
lowerBounds = zeros(T, 8);

% upperBounds(:, 1) = BattGreen; 
% upperBounds(:, 2) = BattGrid;
% upperBounds(:, 3) = LoadBatt;
% upperBounds(:, 4) = LoadGrid;
% upperBounds(:, 5) = Grid;
% upperBounds(:, 6) = LoadGreen;
% upperBounds(:, 7) = NetGreen;
% upperBounds(:, 8) = bin; Additional variable to ensure mutual exclusive
upperBounds = Inf(T, 8);
upperBounds(:, 8) = 1;    % bin is either 0 or 1, Mixed Integer LP

% unroll into vectors: 
% 1:24 = BattGreen;
% 25:48 = BattGrid;
% 49:72 = LoadBatt;
% 73: 96 = LoadGrid;
% 97: 120 = Grid;
% 121: 144 = LoadGreen;
% 145: 168 = NetGreen;
% 169 : 192 = bin;
lowerBounds = lowerBounds(:);
upperBounds = upperBounds(:);



%% ====================Linear Inequality Constraints======================
% T = 24 time intervals, linear inequality matrix and vector A*x <= b, 
% 16 * T = 384 inequality constraints, 
% 8 * T = 192 varibles: see above
A = zeros(13 * T, 8 * T);
b = zeros(13 * T, 1);

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


% The renewable power, Green_t, may be used to run the LoadGreen_t, to charge
% the battery(BattGreen_t), and/or net metering(NetGreen_t):
% LoadGreen_t + BattGreen_t + NetGreen_t <= Green_t, constraints 73 to 96
for i = 3 * T + 1 : 4 * T
    A(i, i - 3 * T) = 1;                     % BattGreen_t
    A(i, i - 3 * T + 5 * T) = 1;             % LoadGreen_t
    A(i, i - 3 * T + 6 * T) = 1;             % NetGreen_t
    b(i) = Green(i - 3 * T);                 % Green_t
end

% A trick for mutual excusive: given X >= 0 => Y = 0 or vice versa: 
% X <= bin * infinity   => X - Inf * bin <= 0
% bin <= X * infinity   => -Inf * X + bin_t <= 0
% Y <= (1 - bin) * infinity   => Y + Inf * bin <= Inf

% % The renewable power cannot be used to charge the battery and sell back to
% % net metering at the same time interval: given BattGreen_t > 0, NetGreen
% % should = 0, or vice versa. 
% % BattGreen_t - Inf * bin_t <= 0: Constraints 97 to 120
% for i = 4 * T + 1 : 5 * T
%     A(i, i - 4 * T) = 1;                   % BattGreen_t
%     A(i, i - 4 * T + 7 * T) = -infVal;        % -Inf * bin_t
%     b(i) = 0;
% end
% 
% % -Inf * BattGreen_t + bin_t <= 0: Constraints 121 to 144
% for i = 5 * T + 1 : 6 * T
%     A(i, i - 5 * T) = -infVal;               % -Inf * BattGreen_t
%     A(i, i - 5 * T + 7 * T) = 1;          % bin_t
%     b(i) = 0;
% end
% 
% % NetGreen_t + Inf * bin_t <= inf; Constraints 145 to 168
% for i = 6 * T + 1 : 7 * T
%     A(i, i - 6 * T + 6 * T) = 1;          % NetGreen_t
%     A(i, i - 6 * T + 7 * T) = infVal;        % Inf * bin_t
%     b(i) = infVal;
% end


% we cannot use the batteries and do net metering at the same time
% given  LoadBatt_t > 0, NetGreen_t should = 0 or vice versa
% LoadBatt_t - inf * bin_t <= 0: Constraints 169 to 192
for i = 4 * T + 1 : 5 * T
    A(i, i - 4 * T + 2 * T) = 1;         % LoadBatt_t
    A(i, i - 4 * T + 7 * T) = -infVal;      % -inf * bint_t
    b(i) = 0;
end

% -inf * LoadBatt_t + bin_t <= 0: Constraints 193 to 216
for i = 5 * T + 1 : 6 * T
    A(i, i - 5 * T + 2 * T) = -infVal;      % -inf * LoadBatt_t
    A(i, i - 5 * T + 7 * T) = 1;         % bin_t
    b(i) = 0;
end

% NetGreen_t + Inf * bin_t <= inf; Constraints 217 to 240
for i = 6 * T + 1 : 7 * T
    A(i, i - 6 * T + 6 * T) = 1;          % NetGreen_t
    A(i, i - 6 * T + 7 * T) = infVal;        % Inf * bin_t
    b(i) = infVal;
end

%we cannot draw from the grid to power the load at the same time as doing
%net metering
%given LoadGrid_t >= 0, NetGreen_t should = 0 or vice versa
%LoadGrid_t - inf * bin_t <= 0: Constraints 241 to 264
for i = 7 * T + 1 : 8 * T
    A(i, i - 7 * T + 3 * T) = 1;        % LoadGrid_t 
    A(i, i - 7 * T + 7 * T) = -infVal;     % -inf * bin_t
    b(i) = 0;
end

% -inf * LoadGrid_t + bin_t <= 0: Constraints 265 to 288
for i = 8 * T + 1 : 9 * T
    A(i, i - 8 * T + 3 * T) = -infVal;    % -inf * LoadGrid_t
    A(i, i - 8 * T + 7 * T) = 1;       % bint_t
    b(i) = 0;
end

% NetGreen_t + Inf * bin_t <= inf; Constraints 289 to 312
for i = 9 * T + 1 : 10 * T
    A(i, i - 9 * T + 6 * T) = 1;          % NetGreen_t
    A(i, i - 9 * T + 7 * T) = infVal;        % Inf * bin_t
    b(i) = infVal;
end

% we cannot charge and discharge the battery at the same time
% given LoadBatt_t > 0, BattGreen_t + BattGrid_t should = 0 or vice versa
% LoadBatt_t - inf * bin_t <= 0, constraints 313 to 336
for i = 10 * T + 1 : 11 * T
    A(i, i - 10 * T + 2 * T) = 1;          % LoadBatt_t
    A(i, i - 10 * T + 7 * T) = -infVal;       % -inf * bin_t
    b(i) = 0;
end

% -inf * LoadBatt_t + bin_t <= 0, constraints 337 to 360
for i = 11 * T + 1 : 12 * T
    A(i, i - 11 * T + 2 * T) = -infVal;       % -inf * LoadBatt_t
    A(i, i - 11 * T + 7 * T) = 1;          % bin_t
    b(i) = 0;
end

% BattGreen_t + BattGrid_t + inf * bin_t <= inf; constraints 361 to 384
for i = 12 * T + 1 : 13 * T
    A(i, i - 12 * T) = 1;                  % BattGreen_t
    A(i, i - 12 * T + T) = 1;              % BattGrid_t
    A(i, i - 12 * T + 7 * T) = infVal;        % inf * bin_t
    b(i) = infVal; 
end


clear i j;


%% =========================Linear Equality Constraints====================
% T = 24 time intervals, linear equality matrix and vector Aeq*x = beq, 
% 2 * T = 48 equality constraints, 
% 8 * T = 192 varibles: see above
Aeq = zeros(2 * T, 8 * T);
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
f = zeros(8 * T, 1); 

for i = 1 : T
    f(i + 4 * T) = GridCost(i);          % GridCost_t * Grid_t
    f(i + 6 * T) = -alpha * GridCost(i); % -alpha * GridCost_t * NetGreen_t
end

clear i;

%% =======================LP Solver ======================================
% Indices of x which are considered to be integers, here bin_t should be
% integers either 0 or 1, and bin_t is in indices from 7*T + 1 to 8*T
xtype = 7 * T + 1 : 8 * T;  
Opt = opti('f', f, 'ineq', A, b, 'eq', Aeq, beq, 'bounds', lowerBounds, upperBounds, 'xtype', xtype);
[x,cost,exitflag,info] = solve(Opt);
info
%[x cost] = MILP(f, A, b, Aeq, beq, lowerBounds, upperBounds, xtype, 0.01);
BattGreen = reshape(x(1 : T), T, 1);
BattGrid = reshape(x(T + 1: 2 * T), T, 1);
LoadBatt = reshape(x(2 * T + 1 : 3 * T), T, 1);
LoadGrid = reshape(x(3 * T + 1 : 4 * T), T, 1);
Grid = reshape(x(4 * T + 1 : 5 * T), T, 1);
LoadGreen = reshape(x(5 * T + 1 : 6 * T), T, 1);
NetGreen = reshape(x(6 * T + 1 : 7 * T), T, 1);
bin = reshape(x(7 * T + 1 : 8 * T), T, 1);
cost = cost / 100;     % convert from cents to dollars

%% =======================Plot Results and Write to File===================
originalPrice = sum(Load.*GridCost) / 100;
fprintf('The Electricity Bill orginally per Day is: $%f\n', originalPrice);
fprintf('The Electricity Bill with LP Solar-Battery per Day is: $%f\n', cost);
fprintf('Total cost reduction is: %f%%\n', (originalPrice - cost) / originalPrice * 100);
costReductArr = ones(T, 1) * ((originalPrice - cost) / originalPrice * 100);
scheduleSolarBatt = [BattGreen, BattGrid, LoadBatt, LoadGrid, Grid, LoadGreen, NetGreen, Load, costReductArr];
csvwrite('scheduleSolarBatt.csv', scheduleSolarBatt);
