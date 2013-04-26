%% Green Computing Project: Energy Efficiency in Smart Homes
% This is the simple case

 

% x(1) = s, x(2) = d, x(3) = p

%% ====================Constant Parameters Initialization===============
C = 30;  %in kWh, battery's usable capacity

% in cents per kWh, cost per kWh
c = [2.7; 2.4; 2.3; 2.3; 2.3; 2.5; 2.8; 3.4; 3.8; 5; 6.1; 6.8; 7.4; 8.2; 10;
     10.9; 11.9; 10.1; 9.2; 7; 7; 5.2; 4.2; 3.5];
 
% number of time intervals
T = 24;     
 
% Hard coded power consumption prediction for the following day, 24 hours
% There should be predicted power consumption for each time interval using
% ML techniques, which is missing here
Load = hardCodedPower('./data/2012-Jul-30.csv', T);

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

% battery charging efficiency
e = 0.855;  



%% ===========================Separate Bounds==============================

% lowerBounds(:, 1) = s, lowerBounds(:, 2) = d lowerBounds(:, 3) = p
lowerBounds = zeros(T, 3);

% upperBounds(:, 1) = s, upperBounds(:, 2) = d upperBounds(:, 3) = p
upperBounds = Inf(T, 3);

% s <= C / 4, contraints number 3
upperBounds(: , 1) = C / 4; 

% unroll into vectors: 1:24 = s, 25:48 = d, 49:72 = p
lowerBounds = lowerBounds(:);
upperBounds = upperBounds(:);


%% ====================Linear Inequality Constraints======================

% T = 24 time intervals, linear inequality matrix and vector A*x <= b, 
% 2 * T = 48 inequality constraints, 
% 3 * T = 72 varibles: T s, T d, and T p, so A is 48*72, b is 48*1
A = zeros(2 * T, 3 * T); 

% -e*s + d <= 0 constraints 4; s - 1/e * d <= C constraints 5
b = zeros(2 * T, 1);

% -e * sum(s_t) + sum(d_t) <= 0;  constraints 4, first T constraints for 
% constaint 4 in the paper
for i = 1 : T
    for j = 1 : i
        A(i, j) = -e;      % -e * sum(s_t)
        A(i, T + j) = 1;   % sum(d_t) 
    end
    b(i) = 0;
end

clear i j;

% sum(s_t) - 1/e * sum(d_t) <= C; constraints 5, second T constraints for
% constraint 5 in the paper
for i = 25 : 2 * T
    for j = 1 : i - T
        A(i, j) = 1;              % sum(s_t)
        A(i, T + j) = -(1/e);     % -(1/e) * sum(d_t)
    end
    b(i) = C;
end

clear i j;


%% =========================Linear Equality Constraints====================
Aeq = zeros(T, 3 * T);
beq = zeros(T, 1);

% There should be at least one constraint here, which is p_i + d_i = predicted
% power consumption, here we are using hard coded power, which should be
% changed to ML predicted power in the future
for i = 1 : T
    Aeq(i, T + i) = 1;
    Aeq(i, 2 * T + i) = 1;
    beq(i) = Load(i);
end

clear i;
        

%% ========================Objective Function(Minimize)===================

% objective function: cost m = sum(p + s) * c slightly different from the
% objective funtion in paper
m = zeros(3 * T, 1); 

for i = 1 : 24
    m(i) = c(i);
   % m(T + i) = -c(i);
    m(2 * T + i) = c(i);
end
clear i;

%% =======================LP Solver ======================================
[x cost] = linprog(m, A, b, Aeq, beq, lowerBounds, upperBounds);
s = reshape(x(1 : T), T, 1);
d = reshape(x(T + 1: 2 * T), T, 1);
p = reshape(x(2 * T + 1 : 3 * T), T, 1);
cost = cost / 100;     % convert from cents to dollars

%% =======================Plot Results and Write to File===================

originalPrice = sum(Load.*c) / 100;
fprintf('The Electricity Bill originally per Day is: $%f\n', originalPrice);
fprintf('The Electricity Bill with LP Batterty-Only per day is: $%f\n', cost);
fprintf('Total cost reduction is: %f%%\n', (originalPrice - cost) / originalPrice * 100);
costReductArr = ones(T, 1) * ((originalPrice - cost) / originalPrice * 100);
scheduleBattOnly = [s, d, p, Load, costReductArr];
csvwrite('scheduleBattOnly.csv', scheduleBattOnly);

%plotData;
