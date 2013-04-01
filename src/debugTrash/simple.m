%% Green Computing Project: Energy Efficiency in Smart Homes
% This is the simple case

clear ; close all; clc

% x(1) = s, x(2) = d, x(3) = p

%% ==========================Initializations===============================

paramInit


%% ===========================separate bounds==============================

% lowerBounds(1) = s, lowerBounds(2) = d lowerBounds(3) = p
lowerBounds = zeros(3, 1);

% upperBounds(1) = s, upperBounds(2) = d upperBounds(3) = p
upperBounds = Inf(3, 1);

% s <= C / 4, contraints number 3
upperBounds(1) = C / 4;     

%% ====================linear inequality constraints======================

% linear inequality matrix and vector A*x <= b, two inequality constraints, 
% 3 varibles: s, d, and p, so A is 2*3, b is 2*1
A = zeros(2, 3); 

% -e*s + d <= 0 constraints 4; s - 1/e * d <= C constraints 5
b = zeros(2, 1);

% -e * x1 + x2 <= 0;  constraints 4
% x1 - 1/e * x2 <= C; constraints 5
A(1, 1) = -e; 
A(1, 2) = 1;
A(2, 1) = 1;
A(2, 2) = -(1/e);
b(1) = 0;
b(2) = C;

%% =========================linear equality constraints====================
Aeq = zeros(1,3);
beq = zeros(1,1);

% There should be at least one constraint here, which is p + d = predicted
% power consumption, using ML, 0 * x1 + x2 + x3 = powerPredict
Aeq(1, 2) = 1;
Aeq(1, 3) = 1;
beq(1, 1) = 5;  % To be changed to a reasonable value







%% ========================objective function==============================

% objective function: cost m = (p + s - d) * c => m = c*x1 - c*x2 + c*x3
m = zeros(3, 1); 
m(1) = c;
m(2) = -c;
m(3) = c;

%% =======================LP solver ======================================
[x cost] = linprog(m, A, b, Aeq, beq, lowerBounds, upperBounds);

