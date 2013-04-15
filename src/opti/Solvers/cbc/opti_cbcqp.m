function [x,fval,exitflag,info] = opti_cbcqp(H,f,A,rl,ru,lb,ub,int,opts)
%OPTI_CBCQP Solve a MIQP using CBC
%
%   min 0.5*x'*H*x + f'*x      subject to:     rl <= A*x <= ru
%    x                                         lb <= x <= ub
%                                              for i = 0..n: xi in Z
%                                              for j = 0..m: xj in {0,1} 
%
%   x = opti_cbcqp(H,f,A,rl,ru,lb,ub,xint) solves a QP where H and f are 
%   the objective matrix and vector respectively, A,rl,ru are the linear 
%   constraints, lb,ub are the  bounds and int is a string of integer 
%   variables ('C', 'I', 'B')
%
%   x = opti_cbcqp(H,...,xint,opts) uses opts to pass optiset options to 
%   the solver.
%
%   [x,fval,exitflag,info] = opti_cbcqp(...) returns the objective value at
%   the solution, together with the solver exitflag, and an information
%   structure.
%
%   THIS IS A WRAPPER FOR CBC USING THE MEX INTERFACE
%   See supplied Eclipse Public License

%   Copyright (C) 2012 Jonathan Currie (I2C2)

%ERROR!
error('Not implemented - Cannot work out Quadratic Objective via CBC (Suggestions Anyone?)');

t = tic;

% Handle missing arguments
if nargin < 9, opts = optiset; end 
if nargin < 8, int = repmat('C',size(f)); end
if nargin < 7, ub = []; end
if nargin < 6, lb = []; end
if nargin < 5, error('You must supply at least 5 arguments to opti_cbcqp'); end

warn = strcmpi(opts.warnings,'all');

%Check sparsity
if(~issparse(H))
    if(warn)
        optiwarn('opti:sparse','The H matrix should be sparse, correcting.');
    end
    H = sparse(H);
end
if(~issparse(A))
    if(warn)
        optiwarn('opti:sparse','The A matrix should be sparse, correcting: [sparse(A)]');
    end
    A = sparse(A);
end

%Check Sym Tril
if(any(any(triu(H,1) ~= 0)))
    if(warn)
        optiwarn('opti:cbc','The H matrix should be Symmetric TRIL, correcting.');
    end
    H = tril(H);
end

%Setup Printing
opts.display = dispLevel(opts.display);
    
%Setup Integer Vars
if(~ischar(int) || length(int) ~= length(f))
    error('The integer string must be a char array %d x 1!',length(f));
else
    int = upper(int);
    ivars = zeros(size(f));
    ivars(strfind(int,'I')) = 1;
    ind = strfind(int,'B');
    if(~isempty(ind))
        if(isempty(lb)), lb = -Inf(size(f)); end
        if(isempty(ub)), ub = Inf(size(f)); end
        ivars(ind) = 1;
        lb(ind) = 0;
        ub(ind) = 1;
    end
end

%MEX contains error checking
[x,fval,exitflag,iter] = cbc(f, A, rl, ru, lb, ub, int32(ivars), opts, H);

%Assign Outputs
info.Iterations = iter;
info.Time = toc(t);
info.Algorithm = 'CBC: Branch and Cut using CLP';

switch(exitflag)
    case 1
        info.StatusString = 'Integer Optimal';
    case 0
        info.StatusString = 'Exceeded Iterations';
    case -1
        info.StatusString = 'Infeasible';
    case -2
        info.StatusString = 'Unbounded or Infeasible';
    case -5
        info.StatusString = 'User Exited';
    otherwise
        info.StatusString = [];
end

info.Lambda = []; %to do

function  print_level = dispLevel(lev)
%Return CBC compatible display level
switch(lower(lev))
    case'off'
        print_level = 0;
    case 'iter'
        print_level = 4;
    case 'final'
        print_level = 1;
end