function [x,fval,exitflag,info] = opti_clp(f,A,rl,ru,lb,ub,opts)
%OPTI_CLP Solve a LP using CLP
%
%   min f'*x      subject to:     rl <= A*x <= ru
%    x                            lb <= x <= ub
%                                 
%
%   x = opti_clp(f,A,rl,ru,lb,ub) solves a LP where f is the objective 
%   vector, A,rl,ru are the linear constraints and lb,ub are the bounds.
%
%   x = opti_clp(f,...,ub,opts) uses opts to pass optiset options to the
%   solver. 
%
%   [x,fval,exitflag,info] = opti_clp(...) returns the objective value at
%   the solution, together with the solver exitflag, and an information
%   structure.
%
%   THIS IS A WRAPPER FOR CLP USING THE MEX INTERFACE
%   See supplied Eclipse Public License

%   Copyright (C) 2012 Jonathan Currie (I2C2)

t = tic;

% Handle missing arguments
if nargin < 7, opts = optiset; end 
if nargin < 6, ub = []; end
if nargin < 5, lb = []; end
if nargin < 4, error('You must supply at least 4 arguments to opti_clp'); end

warn = strcmpi(opts.warnings,'all');

%Check sparsity
if(~issparse(A))
    if(warn)
        optiwarn('opti:sparse','The A matrix should be sparse, correcting: [sparse(A)]');
    end
    A = sparse(A);
end

%Setup Printing
opts.display = dispLevel(opts.display);
    
%MEX contains error checking
[x,fval,exitflag,iter,lam] = clp(f, A, rl, ru, lb, ub, opts);

%Assign Outputs
info.Iterations = iter;
info.Time = toc(t);
info.Algorithm = 'CLP: Dual Simplex';

switch(exitflag)
    case 1
        info.Status = 'Optimal';
    case 0
        info.Status = 'Exceeded Iterations';
    case -1
        info.Status = 'Infeasible';
    case -2
        info.Status = 'Unbounded or Infeasible';
    case -5
        info.Status = 'User Exited';
    otherwise
        info.Status = [];
end

%Assign Lambda
eq = rl == ru;
info.Lambda = struct('ineqlin',lam.dual_row(~eq),'eqlin',lam.dual_row(eq),'bounds',lam.dual_col);

function  print_level = dispLevel(lev)
%Return CLP compatible display level
switch(lower(lev))
    case'off'
        print_level = 0;
    case 'iter'
        print_level = 4;
    case 'final'
        print_level = 1;
end