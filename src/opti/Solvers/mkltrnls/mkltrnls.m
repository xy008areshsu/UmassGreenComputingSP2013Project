% MKLTRNLS  Solve a NLS using MKLTRNLS
%
% THIS IS A LOW LEVEL FUNCTION - USE opti_mkltrnls() INSTEAD!
%
% mktrnls uses the Intel MKL Trust Region NLS Solver.
%
%   [x,fval,exitflag,iter] = mktrnls(fun,grad,x0,ydata,lb,ub,opts)
%
%   Input arguments:
%       fun - nonlinear fitting function handle
%       grad - gradient of nonlinear fitting function handle (optional)
%       x0 - initial solution guess
%       ydata - fitting data
%       lb - decision variable lower bounds (optional)
%       ub - decision variable upper bounds (required if lb present)
%       opts - solver options (see below)
%
%   Return arguments:
%       x - solution vector
%       fval - objective value at the solution
%       exitflag - exit status (see below)
%       iter - number of iterations taken by the solver
%
%   Option Fields (all optional):
%       maxiter - maximum solver iterations
%
%   Return Status:
%       1 - optimal 
%       0 - maximum iterations exceeded
%      -1 - could not converge / tolerance too small
%      -2 - singular or other error
%      -3 - unknown error
%
%   
%
%   Copyright (C) 2012 Jonathan Currie (I2C2)