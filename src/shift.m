%% Green Computing Project: Energy Efficiency in Smart Homes(Shift, preemptive loads), ASSUME JUST ONE PREEMPTIBLE LOAD
% Parameters out of our control:
%   NonDeferLoad_t: average predicted required power for each time interval, in kWh.
%   (if the workload is deferable, we might add a new variable WorkLoad_t as
%   the offered load in each time interval)
%   T: number of time intervals
%   GridCost: grid energy price in real time, in cents per kWh
% -------------------------------------------------------------------------
% Variables under our control for optimization:
%   preemptibleLoadsSchedule
%   Grid_t: amount of grid power to be used for any purpose


%% ==================== Parameters Initialization =========================
% number of time intervals
T = 24; 

% Non Deferable Load Pattern
% Hard coded power consumption prediction for the following day, 24 hours
% There should be predicted power consumption for each time interval using
% ML techniques, which is missing here
%nonDeferLoad = load('../dataset/070112.csv');

% Deferable Load Pattern Model
neededPower = 4;
deferableLoads;
i = size(preemptibleLoads);
numOfPreemptible = i(1);
i = size(nonPreemptibleLoads);
numOfNonPreemptible = i(1);

% grid power prices for every hour, in cents per kWh
GridCost = [2.7; 2.4; 2.3; 2.3; 2.3; 2.5; 2.8; 3.4; 3.8; 5; 6.1; 6.8; 7.4; 
            8.2; 10; 10.9; 11.9; 10.1; 9.2; 7; 7; 5.2; 4.2; 3.5];
 
%% ===========================Separate Bounds==============================

% lowerBounds(:, 1) = preemptibleLoads
lowerBounds = zeros(T, numOfPreemptible + 1);

upperBounds = Inf(T, numOfPreemptible + 1);

% unroll into vectors: 
% 1 : 24 = preemptibleLoads;
% 25 : 48 = preempribleLoads2
lowerBounds = lowerBounds(:);
upperBounds = upperBounds(:);



%% ====================Linear Inequality Constraints======================
A = zeros(1 * T, (numOfPreemptible + 1) * T); 

b = zeros(1 * T, 1);

% Grid_t >= NonDeferLoad_t + preemptible_t
for i = 1 : T
    A(i, i) = 1;     %preemptible_t
    A(i, i + T) = -1;   %Grid_t
    b(i) =  -nonDeferLoad(i);
end
    




%% =========================Linear Equality Constraints====================
% T = 24 time intervals, linear equality matrix and vector Aeq*x = beq, 
% 8 * T = 192 equality constraints, plus (T / period)  consstraints for
% each preemptible deferableLoads
% 10 * T = 240 varibles: see above
count = zeros(numOfPreemptible, 1);
for i = 1 : numOfPreemptible
    count(i) =  T / preemptibleLoads(i, 2);
end
Aeq = zeros(sum(count), (numOfPreemptible + 1)* T);
beq = zeros(sum(count), 1);



% preemptibleLoad scheduling
period = preemptibleLoads(1, 2);
powerPerPeriod = preemptibleLoads(1, 4);
k = 0;
for i = 1 : count(1)
    for j = 0 : period - 1
        Aeq(i, 1 + k * period  + j) = 1;    
    end   
    k = k + 1;
    beq(i) = powerPerPeriod;
end


clear i;
        

%% ========================Objective Function(Minimize)====================
% objective function: Total electricity cost: m = sum(GridCost_t * Grid_t 
f = zeros((numOfPreemptible + 1) * T, 1); 

for i = 1 : T
    f(i +  T) = GridCost(i);          % GridCost_t * Grid_t
end

clear i;

%% =======================LP Solver ======================================
% Indices of x which are considered to be integers
xtype = [];  
Opt = opti('f', f, 'ineq', A, b, 'eq', Aeq, beq, 'bounds', lowerBounds, upperBounds, 'xtype', xtype);
[x,cost,exitflag,info] = solve(Opt);
%[x cost exitflag info] = MILP(f, A, b, Aeq, beq, lowerBounds, upperBounds, xtype, 0.01);
preemptibleLoadsSchedule = reshape(x(1 :  T), T, numOfPreemptible);
Grid = reshape(x(T + 1 : 2 * T), T, 1);
cost = cost / 100;     % convert from cents to dollars

%% =======================Plot Results and Write to File===================
nonDerPrice = sum(nonDeferLoad.*GridCost) / 100;
ACPrice = sum(56 / 8 * GridCost(16:24)) / 100;
originalPrice = nonDerPrice + ACPrice;
fprintf('The Electricity Bill without Smart Charge per Day is: $%f\n', originalPrice);
fprintf('The Electricity Bill with Smart Charge Solar-Battery per Day is: $%f\n', cost);
fprintf('Total cost reduction is: %f%%\n', (originalPrice - cost) / originalPrice * 100);

