function [x,fval,exitflag,info] = solveOpti(optObj,x0)
%SOLVE an OPTI object
%
%   Called By opti Solve

%   Copyright (C) 2011-2013 Jonathan Currie (I2C2)

prob = optObj.prob; opts = optObj.opts;
nlprob = optObj.nlprob;

%Check we have an initial point
if(~isempty(x0))
    if(length(x0) ~= optObj.prob.sizes.ndec)
        error('x0 is not the correct length! Expected %d x 1',optObj.prob.sizes.ndec);
    end
    if(size(x0,2) > 1)
        x0 = x0';
    end    
end
%Ensure dense starting guess
x0 = full(x0);

%Check for solving via AMPL alone
if(prob.ampl.useASL && ~isempty(prob.ampl.path))
    switch(opts.solver)
        case 'scip'
            [x,fval,exitflag,info] = opti_scipasl(prob.ampl.path,opts);
    end
    return
end

%Check for unconstrained problem
if(~prob.iscon) 
    switch(optObj.prob.type)
        case 'SLE'
            [x,fval,exitflag,info] = solveSLE(prob,opts);
        case 'QP'
            [x,fval,exitflag,info] = unconQP(prob);
        case 'SNLE'
            [x,fval,exitflag,info] = solveSNLE(nlprob,x0,opts);
        case 'NLS'
            [x,fval,exitflag,info] = solveNLS(nlprob,x0,opts);
        case 'UNO'
            [x,fval,exitflag,info] = solveUNO(nlprob,x0,opts);
        otherwise
            error('The problem appears unconstrained yet is not a LSE, QP or UNO');
    end
    return
end

%Otherwise is a constrained problem
switch(optObj.prob.type)
    case 'LP'
        [x,fval,exitflag,info] = solveLP(prob,x0,opts);
    case 'MILP'
        [x,fval,exitflag,info] = solveMILP(prob,x0,opts);
    case 'BILP'
        [x,fval,exitflag,info] = solveBILP(prob,x0,opts);
    case 'QP'
        [x,fval,exitflag,info] = solveQP(prob,x0,opts);
    case 'QCQP'
        [x,fval,exitflag,info] = solveQCQP(prob,x0,opts);
    case 'MIQP'
        [x,fval,exitflag,info] = solveMIQP(prob,x0,opts);
    case 'MIQCQP'
        [x,fval,exitflag,info] = solveMIQCQP(prob,x0,opts);
    case 'SDP'
        [x,fval,exitflag,info] = solveSDP(prob,x0,opts);
    case 'MISDP'
        [x,fval,exitflag,info] = solveMISDP(prob,x0,opts);
    case 'NLS'
        [x,fval,exitflag,info] = solveNLS(nlprob,x0,opts);
    case 'NLP'
        [x,fval,exitflag,info] = solveNLP(nlprob,x0,opts);
    case 'MINLP'
        [x,fval,exitflag,info] = solveMINLP(nlprob,x0,opts);
        
    otherwise
        error('Problem Type not Implemented Yet');
end



function [x,fval,exitflag,info] = solveLP(p,x0,opts)
%Solve a Linear Program using a selected solver

switch(opts.solver)       
    case 'cplex'
        [x,fval,exitflag,info] = opti_cplex([],p.f,p.A,p.rl,p.ru,p.lb,p.ub,[],[],[],x0,opts.solverOpts); 
    case 'csdp'
        [x,fval,exitflag,info] = opti_csdp(p.f,p.A,p.b,p.lb,p.ub,[],x0,opts); 
    case 'dsdp'
        [x,fval,exitflag,info] = opti_dsdp(p.f,p.A,p.b,p.lb,p.ub,[],x0,opts); 
    case 'mosek'
        [x,fval,exitflag,info] = moseklp(p.f,p.A,p.b,p.Aeq,p.beq,p.lb,p.ub,x0,opts.solverOpts);
    case 'glpk'
        [x,fval,exitflag,info] = opti_glpk(p.f,p.A,p.b,p.Aeq,p.beq,p.lb,p.ub,p.int.str,opts);
    case 'clp'
        [x,fval,exitflag,info] = opti_clp(p.f,p.A,p.rl,p.ru,p.lb,p.ub,opts);
    case 'scip'
        [x,fval,exitflag,info] = opti_scip([],p.f,p.A,p.rl,p.ru,p.lb,p.ub,[],[],[],opts);
    case 'qsopt'
        [x,fval,exitflag,info] = opti_qsopt(p.f,p.A,p.b,p.Aeq,p.beq,p.lb,p.ub,opts);
    case 'ooqp'
        [x,fval,exitflag,info] = opti_ooqp([],p.f,p.A,p.rl,p.ru,p.Aeq,p.beq,p.lb,p.ub,opts);
    case 'lp_solve'
        [x,fval,exitflag,info] = opti_lpsolve(p.f,p.A,p.b,p.Aeq,p.beq,p.lb,p.ub,p.int.str,[],opts);
    case 'matlab'
        t = tic;
        [x,fval,exitflag,output,lambda] = linprog(p.f,p.A,p.b,p.Aeq,p.beq,p.lb,p.ub,x0,opts.solverOpts);
        info = matlabInfo(output,lambda,toc(t),'LINPROG');         
    case 'sedumi'
        [x,fval,exitflag,info] = opti_sedumi(p.sdcone.At,p.sdcone.b,p.sdcone.c,p.sdcone.K,opts);
        
    otherwise
        error('The Solver %s cannot be used to solve a LP',opts.solver);
        
end

function [x,fval,exitflag,info] = solveMILP(p,x0,opts)
%Solve a Mixed Integer Linear Program using a selected solver

switch(opts.solver)
    case 'cplex'
        [x,fval,exitflag,info] = opti_cplex([],p.f,p.A,p.rl,p.ru,p.lb,p.ub,p.int.str,p.sos,[],x0,opts.solverOpts);    
    case 'mosek'
        [x,fval,exitflag,info] = mosekmilp(p.f,p.A,p.b,p.Aeq,p.beq,p.lb,p.ub,p.int.str,x0,opts.solverOpts);
    case 'scip'
        [x,fval,exitflag,info] = opti_scip([],p.f,p.A,p.rl,p.ru,p.lb,p.ub,p.int.str,p.sos,[],opts);
    case 'cbc'
        [x,fval,exitflag,info] = opti_cbc(p.f,p.A,p.rl,p.ru,p.lb,p.ub,p.int.str,p.sos,opts);
    case 'glpk'
        [x,fval,exitflag,info] = opti_glpk(p.f,p.A,p.b,p.Aeq,p.beq,p.lb,p.ub,p.int.str,opts);
    case 'lp_solve'
        [x,fval,exitflag,info] = opti_lpsolve(p.f,p.A,p.b,p.Aeq,p.beq,p.lb,p.ub,p.int.str,p.sos,opts);              
        
    otherwise
        error('The Solver %s cannot be used to solve a MILP',opts.solver);
end

function [x,fval,exitflag,info] = solveBILP(p,x0,opts)
%Solve a Linear Program using a selected solver

switch(opts.solver)    
   
    case 'cplex'
        [x,fval,exitflag,info] = opti_cplex([],p.f,p.A,p.rl,p.ru,p.lb,p.ub,p.int.str,p.sos,[],x0,opts.solverOpts);
    case 'mosek'
        [x,fval,exitflag,info] = mosekbilp(p.f,p.A,p.b,p.Aeq,p.beq,x0,opts.solverOpts);
    case 'scip'
        [x,fval,exitflag,info] = opti_scip([],p.f,p.A,p.rl,p.ru,p.lb,p.ub,p.int.str,p.sos,[],opts);
    case 'glpk'
        [x,fval,exitflag,info] = opti_glpk(p.f,p.A,p.b,p.Aeq,p.beq,p.lb,p.ub,p.int.str,opts);
    case 'lp_solve'
        [x,fval,exitflag,info] = opti_lpsolve(p.f,p.A,p.b,p.Aeq,p.beq,p.lb,p.ub,p.int.str,p.sos,opts);
    case 'cbc'
        [x,fval,exitflag,info] = opti_cbc(p.f,p.A,p.rl,p.ru,p.lb,p.ub,p.int.str,p.sos,opts);
    case 'matlab'
        t = tic;
        [x,fval,exitflag,output] = bintprog(p.f,p.A,p.b,p.Aeq,p.beq,x0,opts.solverOpts);
        info = matlabInfo(output,[],toc(t),'BINTPROG');       
        
    otherwise
        error('The Solver %s cannot be used to solve a BILP',opts.solver);
        
end


function [x,fval,exitflag,info] = solveQP(p,x0,opts)
%Solve a Quadratic Program using a selected solver

switch(opts.solver)       
    case 'cplex'
        [x,fval,exitflag,info] = opti_cplex(p.H,p.f,p.A,p.rl,p.ru,p.lb,p.ub,[],[],[],x0,opts.solverOpts); 
    case 'mosek'
        [x,fval,exitflag,info] = mosekqp(p.H,p.f,p.A,p.b,p.Aeq,p.beq,p.lb,p.ub,x0,opts.solverOpts);
    case 'ooqp'
        [x,fval,exitflag,info] = opti_ooqp(p.H,p.f,p.A,p.rl,p.ru,p.Aeq,p.beq,p.lb,p.ub,opts);
    case 'clp'
        [x,fval,exitflag,info] = opti_clpqp(p.H,p.f,p.A,p.rl,p.ru,p.lb,p.ub,opts);
    case 'scip'
        [x,fval,exitflag,info] = opti_scip(p.H,p.f,p.A,p.rl,p.ru,p.lb,p.ub,[],[],[],opts);
    case 'matlab'
        t = tic;
        [x,fval,exitflag,output,lambda,] = quadprog(p.H,p.f,p.A,p.b,p.Aeq,p.beq,p.lb,p.ub,x0,opts.solverOpts);
        info = matlabInfo(output,lambda,toc(t),'QUADPROG'); 
    otherwise
        error('The Solver %s cannot be used to solve a QP',opts.solver);
        
end

function [x,fval,exitflag,info] = solveQCQP(p,x0,opts)
%Solve a Quadratically Constrained Program using a selected solver

%Form QC structure
qc.Q = p.Q; qc.l = p.l; qc.qrl = p.qrl; qc.qru = p.qru;

switch(opts.solver)      
    case 'cplex'        
        [x,fval,exitflag,info] = opti_cplex(p.H,p.f,p.A,p.rl,p.ru,p.lb,p.ub,[],[],qc,x0,opts.solverOpts);
    case 'mosek'
        [x,fval,exitflag,info] = mosekqcqp(p.H,p.f,p.A,p.b,p.Aeq,p.beq,p.Q,p.l,p.r,p.lb,p.ub,x0,opts.solverOpts);
    case 'scip'
        [x,fval,exitflag,info] = opti_scip(p.H,p.f,p.A,p.rl,p.ru,p.lb,p.ub,[],[],qc,opts);
    otherwise
        error('The Solver %s cannot be used to solve a QCQP',opts.solver);        
end

function [x,fval,exitflag,info] = solveMIQP(p,x0,opts)
%Solve a Mixed Integer Quadratic Program using a selected solver

switch(opts.solver)      
    case 'cplex'
        [x,fval,exitflag,info] = opti_cplex(p.H,p.f,p.A,p.rl,p.ru,p.lb,p.ub,p.int.str,p.sos,[],x0,opts.solverOpts); 
    case 'mosek'
        [x,fval,exitflag,info] = mosekmiqp(p.H,p.f,p.A,p.b,p.Aeq,p.beq,p.lb,p.ub,p.int.str,x0,opts.solverOpts);
    case 'cbc'
        [x,fval,exitflag,info] = opti_cbcqp(p.H,p.f,p.A,p.rl,p.ru,p.lb,p.ub,p.int.str,opts);
    case 'scip'
        [x,fval,exitflag,info] = opti_scip(p.H,p.f,p.A,p.rl,p.ru,p.lb,p.ub,p.int.str,p.sos,[],opts);
        
    otherwise
        error('The Solver %s cannot be used to solve a MIQP',opts.solver);        
end

function [x,fval,exitflag,info] = solveMIQCQP(p,x0,opts)
%Solve a Mixed Integer Quadratically Constrained Quadratic Program using a selected solver

%Form QC structure
qc.Q = p.Q; qc.l = p.l; qc.qrl = p.qrl; qc.qru = p.qru;

switch(opts.solver)      
    case 'cplex'
        [x,fval,exitflag,info] = opti_cplex(p.H,p.f,p.A,p.rl,p.ru,p.lb,p.ub,p.int.str,p.sos,qc,x0,opts.solverOpts);
    case 'mosek'
        [x,fval,exitflag,info] = mosekmiqcqp(p.H,p.f,p.A,p.b,p.Aeq,p.beq,p.Q,p.l,p.r,p.lb,p.ub,p.int.str,x0,opts.solverOpts);
    case 'scip'
        [x,fval,exitflag,info] = opti_scip(p.H,p.f,p.A,p.rl,p.ru,p.lb,p.ub,p.int.str,p.sos,qc,opts);
        
    otherwise
        error('The Solver %s cannot be used to solve a MIQCQP',opts.solver);        
end

function [x,fval,exitflag,info] = solveSDP(p,x0,opts)
%Solve a Semidefinite Programming problem using a selector solver

switch(opts.solver) 
    case 'csdp'
        [x,fval,exitflag,info] = opti_csdp(p.f,p.A,p.b,p.lb,p.ub,p.sdcone,x0,opts);
    case 'dsdp'
        [x,fval,exitflag,info] = opti_dsdp(p.f,p.A,p.b,p.lb,p.ub,p.sdcone,x0,opts);
    case 'sedumi'
        [x,fval,exitflag,info] = opti_sedumi(p.sdcone.At,p.sdcone.b,p.sdcone.c,p.sdcone.K,opts);
        
    otherwise
        error('The Solver %s cannot be used to solve a SDP',opts.solver);        
end

function [x,fval,exitflag,info] = solveMISDP(prob,x0,opts)
%Solve a Mixed Integer Semidefinite Programming problem using a selector solver
error('Not implemented yet');


function [x,fval,exitflag,info] = solveSNLE(nlprob,x0,opts)
%Solve a Nonlinear Equation Problem using a selected solver

%Must have x0 for SNLE
if(isempty(x0))
    error('You must supply x0 when solving an SNLE!');
else
    nlprob.x0 = full(x0);
end

switch(opts.solver)
    case 'matlab'
        t = tic;
        [x,fval,exitflag,output] = fsolve(nlprob);
        info = matlabInfo(output,[],toc(t),'FSOLVE');
    case 'hybrj'
        [x,fval,exitflag,info] = opti_hybrj(nlprob.fun,nlprob.grad,nlprob.x0,nlprob.options);
    case 'nl2sol'
        if(~isfield(nlprob,'ydata') || isempty(nlprob.ydata)) %allows for runtime generation of eq rhs
            nlprob.ydata = zeros(size(nlprob.x0));
        end
        [x,fval,exitflag,info] = opti_nl2sol(nlprob.fun,nlprob.grad,nlprob.x0,nlprob.ydata,nlprob.lb,nlprob.ub,nlprob.options);
    case 'lmder'
        if(~isfield(nlprob,'ydata') || isempty(nlprob.ydata))
            nlprob.ydata = zeros(size(nlprob.x0));
        end
        [x,fval,exitflag,info] = opti_lmder(nlprob.fun,nlprob.grad,nlprob.x0,nlprob.ydata,nlprob.options);
    case 'mkltrnls'
        if(~isfield(nlprob,'ydata') || isempty(nlprob.ydata)) 
            nlprob.ydata = zeros(size(nlprob.x0));
        end
        [x,fval,exitflag,info] = opti_mkltrnls(nlprob.fun,nlprob.grad,nlprob.x0,nlprob.ydata,nlprob.lb,nlprob.ub,nlprob.options);
    otherwise
        error('The Solver %s cannot be used to solve a SNLE',opts.solver);
end

function [x,fval,exitflag,info] = solveNLS(nlprob,x0,opts)
%Solve a Nonlinear Least Squares Problem using a selected solver

%Must have x0 for NLS
if(isempty(x0))
    error('You must supply x0 when solving an NLS!');
else
    nlprob.x0 = full(x0);
end

switch(opts.solver)
    case 'matlab'
        t = tic;
        [x,fval,~,exitflag,output,lambda] = lsqnonlin(nlprob);
        info = matlabInfo(output,lambda,toc(t),'LSQNONLIN');
    case 'lmder'
        [x,fval,exitflag,info] = opti_lmder(nlprob.fun,nlprob.grad,nlprob.x0,nlprob.ydata,nlprob.options);
    case 'levmar'
        [x,fval,exitflag,info] = opti_levmar(nlprob.fun,nlprob.grad,nlprob.x0,nlprob.ydata,nlprob.lb,nlprob.ub,...
                                             nlprob.A,nlprob.b,nlprob.Aeq,nlprob.beq,nlprob.options);
    case 'mkltrnls'
        [x,fval,exitflag,info] = opti_mkltrnls(nlprob.fun,nlprob.grad,nlprob.x0,nlprob.ydata,nlprob.lb,nlprob.ub,nlprob.options);
	case 'nl2sol'
		[x,fval,exitflag,info] = opti_nl2sol(nlprob.fun,nlprob.grad,nlprob.x0,nlprob.ydata,nlprob.lb,nlprob.ub,nlprob.options); 
    otherwise
        error('The Solver %s cannot be used to solve a NLS',opts.solver);
end

function [x,fval,exitflag,info] = solveNLP(nlprob,x0,opts)
%Solve a Nonlinear Program using a selected solver

%Must have x0 for NLP
if(isempty(x0))
    error('You must supply x0 when solving an NLP!');
else
    nlprob.x0 = full(x0);
end

switch(opts.solver)
    case 'matlab'
        t = tic;
        [x,fval,exitflag,output,lambda] = fmincon(nlprob);
        info = matlabInfo(output,lambda,toc(t),'FMINCON - Interior Point');
    case 'ipopt'
        [x,fval,exitflag,info] = opti_ipopt(nlprob,x0); 
    case 'filtersd'
        [x,fval,exitflag,info] = opti_filtersd(nlprob.fun,nlprob.grad,nlprob.x0,nlprob.lb,nlprob.ub,nlprob.nlcon,nlprob.nljac,nlprob.nljacstr,nlprob.cl,nlprob.cu,nlprob.options);
    case 'nlopt'
        [x,fval,exitflag,info] = opti_nlopt(nlprob,x0); 
    case 'lbfgsb'
        [x,fval,exitflag,info] = opti_lbfgsb(nlprob.fun,nlprob.grad,nlprob.lb,nlprob.ub,nlprob.x0,nlprob.options);
    case 'nomad'
        [x,fval,exitflag,info] = opti_nomad(nlprob.fun,nlprob.x0,nlprob.lb,nlprob.ub,nlprob.nlcon,nlprob.nlrhs,nlprob.xtype,nlprob.options);
    case 'pswarm'
        [x,fval,exitflag,info] = opti_pswarm(nlprob.fun,nlprob.lb,nlprob.ub,nlprob.x0,nlprob.A,nlprob.b,nlprob.options);
    case 'scip'
        [x,fval,exitflag,info] = opti_scipnl(nlprob.fun,nlprob.A,nlprob.rl,nlprob.ru,nlprob.lb,nlprob.ub,nlprob.nlcon,nlprob.cl,nlprob.cu,nlprob.int.str,nlprob.x0,nlprob.options);
    case 'gmatlab'
        t = tic;
        [x,fval,exitflag,output] = patternsearch(nlprob);
        info = gmatlabInfo(output,toc(t),'PATTERNSERACH - Global Direct Search');
    otherwise
        error('The Solver %s cannot be used to solve a NLP',opts.solver);
end

function [x,fval,exitflag,info] = solveMINLP(nlprob,x0,opts)
%Solve a Mixed Integer Nonlinear Program using a selected solver

%Must have x0 for MINLP
if(isempty(x0))
    error('You must supply x0 when solving an MINLP!');
else
    nlprob.x0 = full(x0);
end

switch(opts.solver)
    case 'bonmin'
        [x,fval,exitflag,info] = opti_bonmin(nlprob,x0);
    case 'scip'
        [x,fval,exitflag,info] = opti_scipnl(nlprob.fun,nlprob.A,nlprob.rl,nlprob.ru,nlprob.lb,nlprob.ub,nlprob.nlcon,nlprob.cl,nlprob.cu,nlprob.int.str,nlprob.x0,nlprob.options);
    case 'nomad'
        [x,fval,exitflag,info] = opti_nomad(nlprob.fun,nlprob.x0,nlprob.lb,nlprob.ub,nlprob.nlcon,nlprob.nlrhs,nlprob.xtype,nlprob.options);
    case 'gmatlab'
        t = tic;
        [x,fval,exitflag,output] = ga(nlprob);
        info = gmatlabInfo(output,toc(t),'GA - Genetic Algorithm');
    otherwise
        error('The Solver %s cannot be used to solve a MINLP',opts.solver);
end


%-- UNCONSTRAINED PROBLEMS --%

function [x,fval,exitflag,info] = solveSLE(prob,opts)
%Solve a System of Linear Equations
fval = [];
exitflag = [];

switch(opts.solver)
    case 'matlab'
        t = tic;
        x = prob.A\prob.b;
        info = matlabInfo([],[],toc(t),'mldivide');
    case 'mumps'
        [x,info] = opti_mumps(prob.A,prob.b);
    otherwise
        error('The solver %s cannot be used to solve a LSE',opts.solver);
end



function [x,fval,exitflag,info] = unconQP(p)
%Solve an Unconstrained QP

t = tic;
x = -p.H\p.f;

info = struct('Iterations',[],'Time',toc(t),'Algorithm','MATLAB: mldivide','StatusString',[]);
fval = 0.5*x'*p.H*x + p.f'*x;
exitflag = 1;


function [x,fval,exitflag,info] = solveUNO(nlprob,x0,opts)
%Solve an Unconstrained Nonlinear Problem

%Must have x0 for NLP
if(isempty(x0))
    error('You must supply x0 when solving an UNO!');
else
    nlprob.x0 = full(x0);
end

switch(opts.solver)
    case 'matlab'
        t = tic;
        [x,fval,exitflag,output] = fminsearch(nlprob.objective,x0);
        info = matlabInfo(output,[],toc(t),'FMINSEARCH - Simplex');
    case 'filtersd'
        [x,fval,exitflag,info] = opti_filtersd(nlprob.fun,nlprob.grad,nlprob.x0,nlprob.lb,nlprob.ub,nlprob.nlcon,nlprob.nljac,nlprob.nljacstr,nlprob.cl,nlprob.cu,nlprob.options);
    case 'ipopt'
        [x,fval,exitflag,info] = opti_ipopt(nlprob,x0);
    case 'nlopt'
        [x,fval,exitflag,info] = opti_nlopt(nlprob,x0);
    case 'nomad'
        [x,fval,exitflag,info] = opti_nomad(nlprob.fun,nlprob.x0,nlprob.lb,nlprob.ub,nlprob.nlcon,nlprob.nlrhs,nlprob.xtype,nlprob.options);
    case 'm1qn3'
        [x,fval,exitflag,info] = opti_m1qn3(nlprob.fun,nlprob.grad,nlprob.x0,nlprob.options);
    case 'scip'
        [x,fval,exitflag,info] = opti_scipnl(nlprob.fun,[],[],[],[],[],[],[],[],[],nlprob.x0,nlprob.options);
    case 'gmatlab'
        t = tic;
        [x,fval,exitflag,output] = patternsearch(nlprob);
        info = gmatlabInfo(output,toc(t),'PATTERNSERACH - Global Direct Search');
    otherwise
        error('The Solver %s cannot be used to solve this type of problem',opts.solver);
end


function info = matlabInfo(output,lambda,t,alg)
%Convert Matlab Output to opti info structure

if(isempty(output))
    output.iterations = [];
    output.message = [];
end
if(~isfield(output,'message'))
    output.message = 'This is does not appear to be a MATLAB solver - You have overloaded it';
end

info = struct('Iterations',output.iterations,'Time',...
               t,'Algorithm',['MATLAB: ' alg],...
               'Status',output.message);       
           
if(~isempty(lambda))
    info.Lambda = lambda;
end


function info = gmatlabInfo(output,t,alg)
%Convert GMatlab Output to opti info structure

if(isempty(output))
    output.iterations = [];
    output.message = [];
end
if(~isfield(output,'message'))
    output.message = 'This is does not appear to be a MATLAB solver  - You have overloaded it';
end

if(isfield(output,'iterations'))
    info.Iterations = output.iterations;
elseif(isfield(output,'generations'))
    info.Iterations = output.generations;
else
    info.Iterations = [];
end
info.Time = t;
info.Algorithm = ['GMATLAB: ' alg];
info.Status = output.message;                       