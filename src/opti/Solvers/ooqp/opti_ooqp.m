function [x,fval,exitflag,info] = opti_ooqp(H,f,A,rl,ru,Aeq,beq,lb,ub,opts)
%OPTI_OOQP Solve a LP or QP using OOQP
%
%   min 0.5*x'*H*x + f'*x      subject to:     rl <= A*x <= ru (ineq only)
%    x                                         Aeq*x = beq
%                                              lb <= x <= ub
%
%   x = opti_ooqp(H,f,A,rl,ru,Aeq,beq,lb,ub) solves a QP where H and f are 
%   the objective matrix and vector respectively, A,rl,ru are the linear 
%   inequality constraints, Aeq,beq are the linear equality constraints and 
%   lb,ub are the bounds. Set H to [] for solving an LP.
%
%   x = opti_ooqp(H,...,ub,opts) uses opts to pass optiset options to the
%   solver.
%
%   [x,fval,exitflag,info] = opti_ooqp(...) returns the objective value at
%   the solution, together with the solver exitflag, and an information
%   structure.
%
%   THIS IS A WRAPPER FOR OOQP USING OOQP MEX INTERFACE
%   See supplied License

%   Copyright (C) 2012 Jonathan Currie (I2C2)

t = tic;

% Handle missing arguments
if nargin < 8, opts = optiset; end
if nargin < 7, ub = []; end
if nargin < 6, lb = []; end
if nargin < 5, error('You must supply at least 5 arguments to opti_ooqp'); end

warn = strcmpi(opts.warnings,'all');

%Ensure Sparsity
if(~isempty(A) && ~issparse(A))
    if(warn)
        optiwarn('opti:sparse','The A matrix should be sparse, correcting: [sparse(A)]');
    end
    A = sparse(A);
end
if(~isempty(H) && ~issparse(H))
    if(warn)
        optiwarn('opti:sparse','The H matrix should be sparse, correcting: [sparse(H)]');
    end
    H = sparse(H);
end
%Ensure Sym TRIU
if(any(any(tril(H,-1) ~= 0)))
    if(warn)
        optiwarn('opti:sym','The H matrix should be Symmetric Upper Triangular, correcting: [triu(H)]');
    end
    H = triu(H);
end

%Setup Printing
opts.display = dispLevel(opts.display);

%Call Solver
[x,fval,stat,iter,lam] = ooqp( H, f, A', rl, ru, Aeq', beq, lb, ub, opts);

%Assign Outputs
info.Iterations = iter;
info.Time = toc(t);
info.Algorithm = 'OOQP: Gondzio Predictor-Corrector';

switch(stat)
    case 0
        exitflag = 1;
        msg = 'Optimal';
    case 2
        exitflag = 0;
        msg = 'Exceeded Iterations';
    case 3 
        exitflag = -1;
        msg = 'Infeasible';
    otherwise 
        exitflag = -2;
        msg = 'OOQP Error';
end

info.Status = msg;

%Assign Lambda
info.Lambda = struct('ineqlin',lam.pi,'eqlin',lam.y,'upper',lam.phi,'lower',lam.gamma);


function  print_level = dispLevel(lev)
%Return OPTI compatible display level
switch(lower(lev))
    case'off'
        print_level = 0;
    case 'iter'
        print_level = 1;
    case 'final'
        print_level = 2;
end