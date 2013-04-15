function [x,fval,exitflag,info] = opti_clpqp(H,f,A,rl,ru,lb,ub,opts)
%OPTI_CLPQP Solve a QP using CLP
%
%   min 0.5*x'*H*x + f'*x      subject to:     rl <= A*x <= ru
%    x                                         lb <= x <= ub
%                                              
%   x = opti_clpqp(H,f,A,rl,ru,lb,ub) solves a QP where H and f are 
%   the objective matrix and vector respectively, A,rl,ru are the linear 
%   constraints, and lb,ub are the bounds. 
%
%   x = opti_clpqp(H,...,ub,opts) uses opts to pass optiset options to the
%   solver.
%
%   [x,fval,exitflag,info] = opti_clpqp(...) returns the objective value at
%   the solution, together with the solver exitflag, and an information
%   structure.
%
%   THIS IS A WRAPPER FOR CLP USING THE MEX INTERFACE
%   See supplied Eclipse Public License

%   (C) 2011 Jonathan Currie (I2C2)

%   Copyright (C) 2012 Jonathan Currie (I2C2)

t = tic;

% Handle missing arguments
if nargin < 8, opts = optiset; end 
if nargin < 7, ub = []; end
if nargin < 6, lb = []; end
if nargin < 5, error('You must supply at least 5 arguments to opti_clpqp'); end

warn = strcmpi(opts.warnings,'all');

%Check sparsity
if(~issparse(H))
    if(warn)
        optiwarn('opti:sparse','The H matrix should be sparse, correcting.');
    end
    H = sparse(H);
end
if(~issparse(A))
    if(~isempty(A) && warn)
        optiwarn('opti:sparse','The A matrix should be sparse, correcting.');
    end
    A = sparse(A);
end

%Check Sym Tril
if(any(any(triu(H,1) ~= 0)))
    if(warn)
        optiwarn('opti:clp','The H matrix should be Symmetric TRIL, correcting.');
    end
    H = tril(H);
end

%Setup Printing
opts.display = dispLevel(opts.display);
    
%MEX contains error checking
[x,fval,exitflag,iter] = clp(f, A, rl, ru, lb, ub, opts, H);

%Assign Outputs
info.Iterations = iter;
info.Time = toc(t);
info.Algorithm = 'CLP: Primal Simplex';

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