%% User Guide Examples

%% SLE
clc
%Sytem
A = [1 1; 4 1.5];
b = [2200; 5050];
% Build OPTI Problem
Opt = opti('sle',A,b)
% Solve
x = solve(Opt)

%% LP
clc
% Objective
f = -[0.07;0.08;0.12];
% Constraints
A = [-1/3 1 0; 0 0 1];
b = [0;2000];
Aeq = [1 1 1];
beq = 12000;
lb = [0;0;0];
% Build OPTI Problem
Opt = opti('f',f,'ineq',A,b,'eq',Aeq,beq,'lb',lb)
%Solve
x = solve(Opt)

%% BILP
clc
% Objective
f = -[0.2;0.3;0.5;0.1];
% Constraints
A = [0.5 1.0 1.5 0.1;
     0.3 0.8 1.5 0.4;
     0.2 0.2 0.3 0.1];
b = [3.1;2.5;0.4];
int = 'BBBB';
% Build OPTI Problem
Opt = opti('f',f,'ineq',A,b,'int',int)
%Solve
x = solve(Opt)

%% MILP
clc
% Objective
f = -[12;16;12;16;-45000;-76000;-45000;-76000];
% Constraints
A = sparse([1/52 1/38 0 0 0 0 0 0;
            0 0 1/42 1/23 0 0 0 0;
            1 0 0 0 -52*480 0 0 0;
            0 1 0 0 0 -38*480 0 0;
            0 0 1 0 0 0 -42*720 0;
            0 0 0 1 0 0 0 -23*720]);
b = [480;720;0;0;0;0];
lb = zeros(8,1);
int = 'IIIIBBBB';
% Build OPTI Problem
Opt = opti('f',f,'ineq',A,b,'lb',lb,'int',int)
%Solve
[x,fval,ef,stat] = solve(Opt)

%% QP
clc
% Objective
H = [1 -1; -1 2];
f = -[2 6]';
% Constraints
A = [1 1; -1 2; 2 1];
b = [2; 2; 3];
lb = [0;0];
% Build OPTI Problem
prob = optiprob('qp',H,f,'ineq',A,b,'lb',lb);
Opt = opti(prob);
%Solve
[x,fval,ef,stat] = solve(Opt)
plot(Opt)

%% QCQP
clc
%Objective
H = eye(2);
f = [-2;-2];
% Constraints
A = [-1 1; 1 3];
b = [2;5];
Q = [1 0;0 1];
l = [0;-2];
r = 1;
lb = [0;0];
% Build OPTI Problem
Opt = opti('H',H,'f',f,'ineq',A,b,'qc',Q,l,r,'lb',lb)
%Solve
[x,fval,exitflag,info] = solve(Opt)
plot(Opt)

%% MIQP
clc
% Objective
H = [1 -1; -1 2];
f = -[2 6]';
% Constraints
A = [1 1; -1 2; 2 1];
b = [2; 2; 3];
lb = [0;0];
int = 'IC';
% Build OPTI Problem
Opt = opti('H',H,'f',f,'ineq',A,b,'lb',lb,'int',int);
%Solve
[x,fval,ef,stat] = solve(Opt)
plot(Opt)

%% MIQCQP
clc
%Objective
H = eye(2);
f = [-2;-2];
% Constraints
A = [-1 1; 1 3];
b = [2;5];
Q = [1 0;0 1];
l = [0;-2];
r = 1;
lb = [0;0];
int = 'IC';
% Build OPTI Problem
Opt = opti('H',H,'f',f,'ineq',A,b,'qc',Q,l,r,'lb',lb,'int',int)
%Solve
[x,fval,exitflag,info] = solve(Opt)
plot(Opt)

%% SNLE
clc
% Nonlinear Equations
fun = @(x) [ 2*x(1) - x(2) - exp(-x(1));
            -x(1) + 2*x(2) - exp(-x(2))];
% Build OPTI Problem
Opt = opti('fun',fun,'ndec',2)
% Solve
x0 = [-5;5];
[x,fval,exitflag,info] = solve(Opt,x0)

%% SCNLE
% to do

%% NLS
clc
% Function to Fit
fun = @(x,xdata) x(1)*exp(x(2)*xdata);
% Fitting Data
xdata = [0.9 1.5 13.8 19.8 24.1 28.2 35.2 60.3 74.6 81.3];
ydata = [455.2 428.6 124.1 67.3 43.2 28.1 13.1 -0.4 -1.3 -1.5];
% Build OPTI Problem
Opt = opti('fun',fun,'data',xdata,ydata,'ndec',2)
%Solve
x0 = [300; -1]; 
[x,fval,exitflag,info] = solve(Opt,x0)
plot(Opt,0.05,1)

%% UNO
clc
% Objective Function
obj = @(x) (1 - x(1))^2 + 100*(x(2) - x(1)^2)^2;
% Build OPTI Problem
Opt = opti('obj',obj,'ndec',2)
% Solve
x0 = [0;0];
x = solve(Opt,x0)
plot(Opt,[],1)

%% NLP
clc
% Objective Function
obj = @(x) log(1 + x(1)^2) - x(2);
% Constraints
nlcon = @(x) (1 + x(1)^2)^2 + x(2)^2;
nlrhs = 4;
nle = 0;
% Build OPTI Problem
Opt = opti('obj',obj,'nlmix',nlcon,nlrhs,nle,'ndec',2)
% Solve
x0 = [2;2];
[x,fval,ef,info] = solve(Opt,x0)
plot(Opt)

%% MINLP
clc
%Objective Function
obj = @(x) sin(pi*x(1)/12)*cos(pi*x(2)/16);
% Constraints
A = [-1 2.5; 1 2.5]; 
b = [1;-15];
int = [1 2];
% Build OPTI Problem
Opt = opti('obj',obj,'ndec',2,'int',int,'ineq',A,b)
% Solve
x0 = [0;0];
[x,fval,ef,info] = solve(Opt,x0)
plot(Opt)

