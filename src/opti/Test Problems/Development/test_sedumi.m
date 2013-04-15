%% Test Problems for SEDUMI Interface
clc
clear

%% LP1
clc  
%Options
opts = optiset('solver','sedumi');
%Build Object
Opt = opti(lp_prob(2),'options',opts)
%Build & Solve
[x,fval,exitflag,info] = solve(Opt)  

%% LP2
clc
%Objective & Constraints
f = -[6 5]';
A = ([1,4; 6,4; 2, -5]); 
b = [16;28;6];    
%Options
opts = optiset('solver','sedumi');
%Build Object
Opt = opti('grad',f,'ineq',A,b,'bounds',[0;0],[10;10],'options',opts)
%Build & Solve
[x,fval,exitflag,info] = solve(Opt)  

%% SDP MAT
clc

prob = sdpRead('sdp_truss5.mat');
opts = optiset('solver','sedumi');

%Build Object
Opt = opti(prob)
%Build & Solve
[x,fval,exitflag,info] = solve(Opt);

info