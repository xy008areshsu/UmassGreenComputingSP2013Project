% OOQP  Solve a LP or QP using OOQP
%
% THIS IS A LOW LEVEL FUNCTION - USE opti_ooqp() INSTEAD!
%
% ooqp uses the Object Orientated Quadratic Programming library.
%
%   [x,fval,stat,iter,lambda] = ooqp(H, f, A, rl, ru, Aeq, beq, lb, ub, opts)
%
%   Input arguments:
%       H - quadratic objective matrix (sparse, triu, optional)
%       f - linear objective vector
%       A - linear inequality matrix (sparse, row major)
%       rl - linear inequality lower bounds
%       ru - linear inequality upper bounds
%       Aeq - linear equality matrix (sparse, row major)
%       beq - linear equality rhs
%       lb - decision variable lower bounds
%       ub - decision variable upper bounds
%       opts - solver options (see below)
%
%   Return arguments:
%       x - solution vector
%       fval - objective value at the solution
%       stat - exit status (see below)
%       iter - number of iterations taken by the solver
%       lambda - structure of dual information
%
%   Option Fields (all optional):
%       display - solver display level [0,1,2]
%
%   Return Status:
%       0 - optimal
%       1 - not finished
%       2 - maximum iterations exceeded
%       3 - infeasible
%       4 - ooqp error
%
%
%   Code is based in parts on original MEX interface by E. Michael Gertz, 
%   Stephen J. Wright
%
%   Copyright (C) 2011 Jonathan Currie (I2C2)
%
%   See Also opti_ooqp