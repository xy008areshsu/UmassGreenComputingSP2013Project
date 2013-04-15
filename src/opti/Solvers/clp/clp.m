% CLP  Solve a LP or QP using CLP
%
% THIS IS A LOW LEVEL FUNCTION - USE opti_clp() INSTEAD!
%
% clp uses the Coin-Or Linear Programming library.
%
%   [x,fval,exitflag,iter,lambda] = clp(f, A, rl, ru, lb, ub, opts, H)
%
%   Input arguments:
%       f - linear objective vector
%       A - linear constraint matrix (sparse)
%       rl - linear constraint lhs
%       ru - linear constraint rhs
%       lb - decision variable lower bounds
%       ub - decision variable upper bounds
%       opts - solver options (see below)
%       H - quadratic objective matrix (sparse, tril, optional)
%
%   Return arguments:
%       x - solution vector
%       fval - objective value at the solution
%       exitflag - exit status (see below)
%       iter - number of iterations taken by the solver
%       lambda - structure of dual information
%
%   Option Fields (all optional):
%       tolfun - function tolerance
%       maxiter - maximum solver iterations
%       maxtime - maximum execution time [s]
%       display - solver display level [0,1,4]
%
%   Return Status:
%       1 - looks optimal
%       0 - maximum iterations exceeded
%      -1 - looks infeasible
%      -2 - inaccuracy / unbounded / other
%      -5 - user exit
%
%
%   Copyright (C) 2011 Jonathan Currie (I2C2)
%
%   See Also opti_clp