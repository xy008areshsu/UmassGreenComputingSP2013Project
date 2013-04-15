classdef opti < handle
%OPTI  Create an OPTI object for Linear, Quadratic & Nonlinear Optimization
%
%   optObj = opti('param1',value1,'param2',value2,...) creates an OPTI
%   object with the parameters 'param' set to their corresponding
%   values in 'value'. Parameters not specified will be set to the OPTI
%   default.
%
%   optObj = opti(...,'options',opts) creates the object with optiset
%   options supplied to the OPTI constructor.
%
%   opti() prints a list of all possible fields and their function.
%
%   optObj = opti(prob) creates an opti object based on the optimization
%   problem specified in prob. Use 'optiprob' to generate the structure
%   'prob'.
%
%   optObj = opti(prob,opts) creates the opti object with specified 
%   options. Use 'optiset' to generate the options structure 'opts'.
%
%
%   Typical usage examples:
%
%   1) LP
%   optObj = opti('f',f,'ineq',A,b,'bounds',lb,ub)
%
%   2) Bounded NLP
%   optObj = opti('fun',fun,'bounds',lb,ub,'x0',x0)
%
%   3) Option Setting
%   optObj = opti('fun',fun,'options',optiset('solver','nlopt'))
%
%
%   See also opti.solve optiprob optiset opti.plot 
%
%   Copyright (C) 2011-2013 Jonathan Currie (www.i2c2.aut.ac.nz)
    
    properties (SetAccess = private)
        prob        % Problem Structure (optiprob)
        nlprob      % Nonlinear Problem Structure 
        opts        % Setup & Runtime options (optiset)
        sol         % Previous solution (Vector)
        obj         % Previous objective value
        ef          % Previous Exit Flag
        info        % Previous Info Structure
    end
    
    methods
        
        %-- Constructor --%
        function op = opti(varargin) 
            %OPTI Constructor
            if(~nargin)
                optiprob;
                fprintf('\nOPTION SETTING:\n');
                fprintf('         options: [ Problem Setup & Solving Options specified via optiset() ]\n\n');
                return;
            end
            [p,o] = opti.buildOpti(varargin{:});
            [op.prob,op.opts,op.nlprob] = opti.buildConfig(p,o);
            op.sol = []; op.ef = []; 
        end
        
        %-- Solve --%
        function [x,fval,exitflag,info] = solve(optObj,varargin)
            %SOLVE  Solve OPTI Optimization Problem
            %
            %   [x,fval,exitflag,info] = solve(optObj) solves the optimization 
            %   problem specified by optObj and returns the solution vector x, 
            %   the function value at x in fval, an exitflag and information in 
            %   info regarding the solution.
            %
            %   [x,fval,exitflag,info] = solve(optObj,x0) solves the optimization
            %   problem using x0 as the initial guess. If x0 is specified within 
            %   opti() / optiprob(), this x0 will take precedence.
            %
            %   ExitFlags:
            %        1 - Converged / Terminated Successfully
            %        0 - Maximum Iterations / Function Evaluations / Time Exceeded
            %       -1 - Infeasible / Could Not Converge
            %       -2 - Unbounded / Solver Error
            %       -3 - Solver Specific Errors (Set option 'display' as 'iter')
            %       -5 - User Exited via Ctrl-C
            %
            %   Information Structure:
            %         Iterations - The number of iterations taken by the solver
            %               Time - The execution time of the solver as measured by MATLAB (tic + toc)
            %          Algorithm - The solver and algorithm being used
            %             Status - A status string indicating the solver specific exit message
            %             Lambda - A structure of the Lagrange multipliers at the solution (if available)
            
            %Check class isn't empty
            if(isempty(optObj.prob))
                error('You cannot solve an empty OPTI object!');
            end
            
            %Get Optional Arguments
            if(~isempty(varargin))
                x0 = varargin{1}; 
            elseif(~isempty(optObj.prob.x0) && ~any(isnan(optObj.prob.x0)))
                x0 = optObj.prob.x0;
            else
                x0 = [];
            end   
            %Solve Problem
            [x,fval,exitflag,info] = solveOpti(optObj,x0);
            optObj.sol = x;
            optObj.obj = fval;
            optObj.ef = exitflag;
            optObj.info = info;
            if(isempty(optObj.prob.sizes.ndec))
                optObj.prob.sizes.ndec = length(x0);
            end
            %Check for maximization
            if(optObj.prob.sense==-1)
                fval = -fval;
            end
            %Check if we should write an ampl solution file
            if(optObj.prob.ampl.writesol && asl('isopen') == 1)
                asl('writesol',info.Status(1:min(end,100)),x);
                %If the problem is not nonlinear, close the interface
                if(isempty(optObj.prob.fun) && isempty(optObj.prob.nlcon))
                    asl('close');
                end
            end
        end
        
        %-- Check Solution --%
        function [ok,msg] = checkSol(optObj)
            %CHECKSOL  Check Optimization Solution for Errors
            %
            %   [ok,msg] = checkSol(optObj) checks the solution stored in
            %   optObj for error messages or broken constraints. It returns
            %   true in 'ok' if no problems detected, otherwise it returns
            %   false with the problem in 'msg'.
            
            if(isempty(optObj.sol))
                error('This OPTI object has not been solved yet!');
            end
            
            [ok,msg] = checkOptiSol(optObj);
        end  
        
        %-- Display --%
        function display(optObj)   
            
            %Check if empty
            if(isempty(optObj.prob))
                disp(' ');
                disp('------------------------------------------------------');
                disp('Empty OPTI Object');
                disp('------------------------------------------------------');
                return;
            end
            %Otherwise normal method
            displayOPTI(optObj);
        end
            
        %-- Plot --%
        function plot(optObj,varargin)
            %PLOT  Plot optimization field (2D only)
            %
            %   plot(optObj) plots the optimization field for the current
            %   OPTI object.
            %
            %   plot(optObj,scale) plots with a user defined zoom level.
            %   scale is defined as the range +- of the solution to be
            %   drawn.
            %
            %   plot(obtObj,scale,dolog) plots the log of the objective
            %   function (NL only)
            
            %Check class isn't empty
            if(isempty(optObj.prob))
                error('You cannot plot an empty OPTI object!');
            end
            
            %Get Optional Arguments
            if(~isempty(varargin) && ~isempty(varargin{1})); scale = varargin{1}; else scale = 5; end
            if(length(varargin) > 1); dolog = varargin{2}; else dolog = 0; end
            %Check 2D
            if(optObj.prob.sizes.ndec ~= 2)
                error('You can only plot problems with two decision variables!');
            end
            
            %Check if problem already solved
            if(isempty(optObj.sol))
                %remove warnings
                nopts = optiset(optObj.opts,'warnings','off');
                optObj = opti(getProb(optObj),nopts);
                xb = solve(optObj);
            else
                xb = optObj.sol;
            end
            
            if(isempty(xb))
                clf;
                warning('opti:plot','The problem is not / cannot be solved so you cannot plot the solution');  
                return;
            end
            
            plotOptiProb(optObj.prob,xb,scale,dolog);                    
        end          
        
        %-- write --%
        function write(optObj,filename,type)
            %WRITE  Write an OPTI LP/MILP/QP/MIQP/SDP to a MPS/QPS/LP/SDPA/SEDUMI file
            %
            %   write(optObj,filename)
            %
            %   write(optObj,filename,type)
            
            %Check class isn't empty
            if(isempty(optObj.prob)), error('You cannot write an empty OPTI object!'); end            
            if(nargin < 3), type = []; end
            %Check if we have a type
            if(~isempty(type))
                switch(lower(type))
                    case {'sdpa','sdpa-s','sedumi','sdpas','sdp','dat','dat-s','mat'}
                        sdpWrite(optObj.prob,filename,type);
                        return;
                    case {'mps','qps','lp'}            
                        coinWrite(optObj.prob,filename,type);
                        return;
                    otherwise
                        error('Unknown file type to write to!');
                end
            end
            %If not, go on extension
            if(isempty(strfind(filename,'.')))
                error('You must supply a file extension if you do not specify a file type!');
            end
            ext = regexp(filename,'\.','split');
            switch(lower(ext{end}))
                case {'dat','mat','dat-s'}
                    sdpWrite(optObj.prob,filename,type);
                case {'mps','qps','lp'}            
                    coinWrite(optObj.prob,filename,type);
                otherwise
                    error('Unknown file extension to write to! For non-standard file extensions please specify the file type.');
            end
        end
        
        
        %-- getProb --%
        function retprob = getProb(optObj)
            %GETPROB  Return optiprob compatible problem structure
            %
            %   prob = getProb(optObj)
            
            %Check class isn't empty
            if(isempty(optObj.prob))
                error('You cannot get the problem from an empty OPTI object!');
            end
            
            retprob = optObj.prob;
            retprob = rmfield(retprob,{'iscon','sizes','numdif','type'});
            retprob.int = retprob.int.str;
        end          
    end
    
    methods (Static)
        [prob,opts] = buildOpti(varargin);
        [prob,opts,nlprob] = buildConfig(prob,opts);
    end
    
end

