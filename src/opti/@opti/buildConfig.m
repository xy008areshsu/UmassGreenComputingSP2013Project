function [prob,opts,nlprob] = buildConfig(prob,opts)
%BUILDCONFIG  Setup Solver Dependent Configuration
%
%   This function builds the problem and options configuration suitable for
%   solving a problem with a specified solver. It is not designed to be
%   called by the user.

%   Copyright (C) 2011 Jonathan Currie (I2C2)

%Get Warning Level
if(strcmpi(opts.warnings,'all'))
    warn = 2;
elseif(strcmpi(opts.warnings,'critical'))
    warn = 1;
else
    warn = 0;
end

nlprob = []; %default we don't have a nonlinear problem

%--Check & Build Config--%
switch(lower(opts.solver))
    case 'bonmin'
        [prob,nlprob] = setupBONMIN(prob,opts,warn);
    case 'cbc'
        prob = setupCBC(prob,warn);
    case 'clp'
        prob = setupCLP(prob,warn);
    case 'cplex'
        [prob,opts] = setupCPLEX(prob,opts,warn);
    case 'csdp'
        [prob,opts] = setupCSDP(prob,opts,warn);
    case 'dsdp'
        [prob,opts] = setupDSDP(prob,opts,warn);
    case 'filtersd'
        [prob,opts,nlprob] = setupFILTERSD(prob,opts,warn);
    case 'glpk'
        prob = setupGLPK(prob,warn);
    case 'gmatlab'
        [prob,opts,nlprob] = setupGMATLAB(prob,opts,warn);
    case 'hybrj'
        nlprob = setupHYBRJ(prob,opts);
    case 'ipopt'
        [prob,nlprob] = setupIPOPT(prob,opts,warn);
    case 'lbfgsb'
        nlprob = setupLBFGSB(prob,opts,warn);
    case 'levmar'
        nlprob = setupLEVMAR(prob,opts,warn);
    case 'lmder'
        nlprob = setupLMDER(prob,opts);
    case 'lp_solve'
        prob = setupLPSOLVE(prob,warn);
    case 'm1qn3'
        nlprob = setupM1QN3(prob,opts);
    case 'matlab'
        [prob,opts,nlprob] = setupMATLAB(prob,opts,warn);
    case 'mkltrnls'
        nlprob = setupMKLTRNLS(prob,opts);
    case 'mosek'
        [prob,opts] = setupMOSEK(prob,opts,warn);
    case 'mumps'
        prob = setupMUMPS(prob,warn);
	case 'nl2sol'
		nlprob = setupNL2SOL(prob,opts);
    case 'nomad'
		[prob,nlprob] = setupNOMAD(prob,opts,warn);
    case 'nlopt'
        [prob,nlprob] = setupNLOPT(prob,opts,warn);
    case 'ooqp'
        prob = setupOOQP(prob,warn);
    case 'opti'
        [prob,nlprob] = setupOPTI(prob,opts,warn);
    case 'pswarm'
        nlprob = setupPSWARM(prob,opts,warn);
    case 'qsopt'
        prob = setupQSOPT(prob,warn);
    case 'scip'
        [prob,nlprob] = setupSCIP(prob,opts,warn);
    case 'sedumi'
        prob = setupSEDUMI(prob,warn);
    otherwise
        error('Unknown solver: %s',opts.solver);
end

% -- BONMIN -- %
function [prob,nlprob] = setupBONMIN(prob,opts,warn)
prob = fixLin('row',prob,warn,'BONMIN'); %Check & Fix Linear Constraints
prob = fixNlin('row',prob,warn,'BONMIN'); %Check & Fix Nonlinear Constraints
nlprob = convBonmin(prob,opts,warn); %Build MINLP problem

% -- CBC -- %
function prob = setupCBC(prob,warn)
prob = fixLin('row',prob,warn,'CBC'); %Check & Fix Linear Constraints
prob = fixSparsity(prob,warn,'CBC'); %Check & Fix Sparsity
prob = fixSymHL(prob,warn,'CBC'); %Check & Fix QP H 

% -- CLP -- %
function prob = setupCLP(prob,warn)
prob = fixLin('row',prob,warn,'CLP'); %Check & Fix Linear Constraints
prob = fixSparsity(prob,warn,'CLP'); %Check & Fix Sparsity
prob = fixSymHL(prob,warn,'CLP'); %Check & Fix QP H

% -- CPLEX -- %
function [prob,opts] = setupCPLEX(prob,opts,warn)
prob = fixLin('row',prob,warn,'CPLEX'); %Check & Fix Linear Constraints
%Build Cplex Options
%Display
switch(opts.display)
    case 'off', level = 0; 
    case 'final', level = 1;
    case 'iter', level = 2;
end
opts.solverOpts.simplex.display.Cur = level;
opts.solverOpts.barrier.display.Cur = level;
opts.solverOpts.sifting.display.Cur = level;
if(level), opts.solverOpts.mip.display.Cur = 2; else opts.solverOpts.mip.display.Cur = 0; end
%Limits
opts.solverOpts.simplex.limits.iterations.Cur = opts.maxiter;
opts.solverOpts.barrier.limits.iteration.Cur = opts.maxiter;
opts.solverOpts.sifting.iterations.Cur = opts.maxiter;
opts.solverOpts.mip.limits.nodes.Cur = opts.maxnodes;
opts.solverOpts.timelimit.Cur = round(opts.maxtime);
%Tolerances
opts.solverOpts.simplex.tolerances.feasibility.Cur = opts.tolrfun;
opts.solverOpts.barrier.convergetol.Cur = opts.tolrfun;
opts.solverOpts.barrier.qcpconvergetol.Cur = opts.tolrfun;
opts.solverOpts.mip.tolerances.integrality.Cur = opts.tolint;

% -- CSDP -- %
function [prob,opts] = setupCSDP(prob,opts,warn)
prob = fixLin('gen_ineq',prob,warn,'CSDP'); %Check & Fix Linear Constraints
prob = fixSparsity(prob,warn,'CSDP'); %Check & Fix Sparsity
%Set OPTI options in dsdpset options
if(~isfield(opts,'solverOpts') || isempty(opts.solverOpts))
    opts.solverOpts.objtol = opts.tolrfun;
end

% -- DSDP -- %
function [prob,opts] = setupDSDP(prob,opts,warn)
prob = fixLin('gen_ineq',prob,warn,'DSDP'); %Check & Fix Linear Constraints
prob = fixSparsity(prob,warn,'DSDP'); %Check & Fix Sparsity
%Set OPTI options in dsdpset options
if(~isfield(opts,'solverOpts') || isempty(opts.solverOpts))
    opts.solverOpts.ptol = opts.tolafun;
end

% -- FILTERSD -- %
function [prob,opts,nlprob] = setupFILTERSD(prob,opts,warn)
prob = fixLin('row',prob,warn,'FILTERSD'); %Check & Fix Linear Constraints
prob = fixNlin('row',prob,warn,'FILTERSD'); %Check & Fix Nonlinear Constraints
nlprob = convFilterSD(prob,opts); %Build NLP problem
                            
% -- GLPK -- %                            
function prob = setupGLPK(prob,warn)
prob = fixLin('gen',prob,warn,'GLPK'); %Check & Fix Linear Constraints
prob = fixSparsity(prob,warn,'GLPK'); %Check & Fix Sparsity

% -- GMATLAB -- %
function [prob,opts,nlprob] = setupGMATLAB(prob,opts,warn)
%Build optimset struct, adding any passed options (ignored by optimset if not recognised)
opts.solverOpts = optimset(opts.solverOpts,'Display',opts.display,'MaxIter',opts.maxiter,'MaxFunEvals',opts.maxfeval,...
                            'MaxTime',opts.maxtime,'TolFun',opts.tolrfun,'TolXInteger',opts.tolint);
%Build NLP
prob = fixLin('gen',prob,warn,'GMATLAB'); %Check & Fix Linear Constraints
prob = fixNlin('gen',prob,warn,'GMATLAB'); %Check & Fix Nonlinear Constraints
nlprob = convGMatlab(prob,opts);

% -- HYBRJ -- %
function nlprob = setupHYBRJ(prob,opts)
%Error Checks
checkPType('HYBRJ',prob.type,'SNLE');
checkCon('HYBRJ',prob.sizes,'uncon');
%Assign Callbacks
nlprob.fun = prob.fun;
nlprob.grad = prob.f;
%Setup Options
nlprob.options.maxfeval = opts.maxfeval;
nlprob.options.maxtime = opts.maxtime;
nlprob.options.display = opts.display;
nlprob.options.iterfun = opts.iterfun;

% -- IPOPT -- %
function [prob,nlprob] = setupIPOPT(prob,opts,warn)
prob = fixLin('row',prob,warn,'IPOPT'); %Check & Fix Linear Constraints
prob = fixNlin('row',prob,warn,'IPOPT'); %Check & Fix Nonlinear Constraints
nlprob = convIpopt(prob,opts); %Build NLP problem

% -- L-BFGS-B -- %
function nlprob = setupLBFGSB(prob,opts,~)
%Error Checks
checkPType('L-BFGS-B',prob.type,'NLP');
checkCon('L-BFGS-B',prob.sizes,'bound');
%Assign Callbacks
nlprob.fun = prob.fun;
nlprob.grad = prob.f;
%Assign Constraints
nlprob.lb = prob.lb;
nlprob.ub = prob.ub;
%Setup Options
nlprob.options.maxiter = opts.maxiter;
nlprob.options.display = opts.display;
nlprob.options.tolrfun = opts.tolrfun;
nlprob.options.iterfun = opts.iterfun;

% -- LEVMAR -- %
function nlprob = setupLEVMAR(prob,opts,warn)
%Error Checks
checkPType('LEVMAR',prob.type,'NLS');
checkCon('LEVMAR',prob.sizes,'lincon');
%Assign Callbacks + Data
[fun,grad,ydata] = setupDataFit(prob);
nlprob.fun = fun;
nlprob.grad = grad;
nlprob.ydata = ydata;
%Assign Constraints
prob = fixLin('gen',prob,warn,'LEVMAR'); %Check & Fix Linear Constraints
nlprob.lb = prob.lb;
nlprob.ub = prob.ub;
nlprob.A = prob.A;
nlprob.b = prob.b;
nlprob.Aeq = prob.Aeq;
nlprob.beq = prob.beq;
%Setup Options
nlprob.options.maxiter = opts.maxiter;
nlprob.options.maxfeval = opts.maxfeval;
nlprob.options.display = opts.display;
nlprob.options.tolrfun = opts.tolrfun;
nlprob.options.tolafun = opts.tolafun;
nlprob.options.iterfun = opts.iterfun;

% -- LMDER -- %
function nlprob = setupLMDER(prob,opts)
%Error Checks
checkPType('LM_DER',prob.type,{'SNLE','NLS'});
checkCon('LM_DER',prob.sizes,'uncon');
%Assign Callbacks + Data
[fun,grad,ydata] = setupDataFit(prob);
nlprob.fun = fun;
nlprob.grad = grad;
nlprob.ydata = ydata;
%Setup Options
nlprob.options.maxfeval = opts.maxfeval;
nlprob.options.maxtime = opts.maxtime;
nlprob.options.display = opts.display;
nlprob.options.tolrfun = opts.tolrfun;
nlprob.options.iterfun = opts.iterfun;

% -- LPSOLVE -- %                            
function prob = setupLPSOLVE(prob,warn)
prob = fixLin('gen',prob,warn,'LP_SOLVE'); %Check & Fix Linear Constraints
prob = fixSparsity(prob,warn,'LP_SOLVE'); %Check & Fix Sparsity

% -- M1QN3 -- %
function nlprob = setupM1QN3(prob,opts)
%Error Checks
checkPType('M1QN3',prob.type,{'UNO'});
checkCon('M1QN3',prob.sizes,'uncon');
%Assign Callbacks
nlprob.fun = prob.fun;
nlprob.grad = prob.f;
%Setup Options
nlprob.options.maxiter = opts.maxiter;
nlprob.options.maxfeval = opts.maxfeval;
nlprob.options.maxtime = opts.maxtime;
nlprob.options.display = opts.display;
nlprob.options.tolafun = opts.tolafun;
nlprob.options.iterfun = opts.iterfun;

% -- MATLAB -- %
function [prob,opts,nlprob] = setupMATLAB(prob,opts,warn)
nlprob = []; %Assume not nonlinear for now
if(strcmpi(prob.type,'sle')) %no setup for sle
    return;
end
%Otherwise is LP, QP, NLS, or NLP
prob = fixLin('gen',prob,warn,'MATLAB'); %Check & Fix Linear Constraints
%Build optimset struct, adding any passed options (ignored by optimset if not recognised)
p = which('quadprog.m');
if(~isempty(p))
    opts.solverOpts = optimset(opts.solverOpts,'Diagnostics',diagState(opts.display),...
                                'Display',opts.display,'MaxIter',opts.maxiter,'MaxTime',opts.maxtime,...
                                'MaxFunEvals',opts.maxfeval,'TolFun',opts.tolrfun,'TolRLPFun',opts.tolrfun,'TolXInteger',opts.tolint,...
                                'MaxNodes',opts.maxnodes);
    %Check Settings for QP or Build NLP
    switch(lower(prob.type))
        case 'qp'
            if(~prob.sizes.nineq && ~prob.sizes.neq) %bounded problem
                opts.solverOpts = optimset(opts.solverOpts,'Algorithm','trust-region-reflective');
            else %linearly constrained
                opts.solverOpts = optimset(opts.solverOpts,'Algorithm','active-set');
            end
        case {'nlp','uno','nls','snle'}
            prob = fixNlin('gen',prob,warn,'MATLAB'); %Check & Fix Nonlinear Constraints
            nlprob = convMatlab(prob,opts);
    end
end
    
% -- MKLTRNLS -- %
function nlprob = setupMKLTRNLS(prob,opts)
%Error Checks
checkPType('MKLTRNLS',prob.type,{'SNLE','NLS'});
checkCon('MKLTRNLS',prob.sizes,'bound');
%Assign Callbacks + Data
[fun,grad,ydata] = setupDataFit(prob);
nlprob.fun = fun;
nlprob.grad = grad;
nlprob.ydata = ydata;
%Assign Constraints
nlprob.lb = prob.lb;
nlprob.ub = prob.ub;
%Setup Options
nlprob.options.maxiter = opts.maxiter;
nlprob.options.maxtime = opts.maxtime;
nlprob.options.display = opts.display;
nlprob.options.tolrfun = opts.tolrfun;
nlprob.options.tolafun = opts.tolafun;
nlprob.options.iterfun = opts.iterfun;

% -- MOSEK -- %
function [prob,opts] = setupMOSEK(prob,opts,warn)
prob = fixLin('gen',prob,warn,'MOSEK'); %Check & Fix Linear Constraints
prob = fixSparsity(prob,warn,'MOSEK'); %Check & Fix Sparsity
checkSymH(prob,'MOSEK'); %Check (Don't Fix) QP H
%Build mosekset struct, adding any passed options (ignored by mosekset if not recognised)
opts.solverOpts = mosekset(opts.solverOpts,'display',opts.display,'warnings',opts.warnings,...
                           'maxiter',opts.maxiter,'maxtime',opts.maxtime,'ptol',opts.tolrfun,...
                           'dtol',opts.tolrfun,'tolint',opts.tolint,'maxbranch',opts.maxnodes);

% -- MUMPS -- %                            
function prob = setupMUMPS(prob,warn)
prob = fixSparsity(prob,warn,'MUMPS'); %Check & Fix Sparsity

% -- NL2SOL -- %
function nlprob = setupNL2SOL(prob,opts)
%Error Checks
checkPType('NL2SOL',prob.type,{'SNLE','NLS'});
checkCon('NL2SOL',prob.sizes,'bound');
%Assign Callbacks + Data
[fun,grad,ydata] = setupDataFit(prob);
nlprob.fun = fun;
nlprob.grad = grad;
nlprob.ydata = ydata;
%Assign Constraints
nlprob.lb = prob.lb;
nlprob.ub = prob.ub;
%Setup Options
nlprob.options.maxiter = opts.maxiter;
nlprob.options.maxfeval = opts.maxfeval;
nlprob.options.display = opts.display;
nlprob.options.tolrfun = opts.tolrfun;
nlprob.options.tolafun = opts.tolafun;
nlprob.options.iterfun = opts.iterfun;
         
% -- NLOPT -- %
function [prob,nlprob] = setupNLOPT(prob,opts,warn)
prob = fixLin('gen',prob,warn,'NLOPT'); %Check & Fix Linear Constraints
prob = fixNlin('gen',prob,warn,'NLOPT'); %Check & Fix Nonlinear Constraints
nlprob = convNlopt(prob,opts); %Build NLP problem 

% -- NOMAD -- %
function [prob,nlprob] = setupNOMAD(prob,opts,warn)
%Error Checks
checkPType('NOMAD',prob.type,{'UNO','NLP','MINLP'});
checkCon('NOMAD',prob.sizes,'ineq');
%Assign Callbacks
nlprob.fun = prob.fun;
%Assign Constraints
prob = fixLin('gen',prob,warn,'NOMAD'); %Check & Fix Linear Constraints
prob = fixNlin('gen',prob,warn,'NOMAD'); %Check & Fix Nonlinear Constraints
prob = genlin2nl(prob,0,warn); %Check for and process linear constraints to nonlinear
nlprob.lb = prob.lb;
nlprob.ub = prob.ub;
nlprob.xtype = prob.int.str;
%Setup Nonlinear Constraints
[nlcon,nlrhs] = setupNLIneq(prob);
nlprob.nlcon = nlcon;
nlprob.nlrhs = nlrhs;
%Setup Options (note options processing done in opti_nomad)
nlprob.options = opts;

% -- OOQP -- %                            
function prob = setupOOQP(prob,warn)
prob = fixLin('mix',prob,warn,'OOQP'); %Check & Fix Linear Constraints
prob = fixSparsity(prob,warn,'OOQP'); %Check & Fix Sparsity
prob = fixSymHU(prob,warn,'OOQP'); %Check & Fix QP H

% -- PSWARM -- %                            
function nlprob = setupPSWARM(prob,opts,warn)
%Error Checks
checkPType('PSwarm',prob.type,'NLP');
checkCon('PSwarm',prob.sizes,'lineq');
%Assign Callbacks
nlprob.fun = prob.fun;
%Assign Constraints
prob = fixLin('gen',prob,warn,'PSWARM'); %Check & Fix Linear Constraints
prob = fixBnds(prob,warn,'PSWARM'); %Check & Fix Infinite Bounds
nlprob.lb = prob.lb;
nlprob.ub = prob.ub;
nlprob.A = prob.A;
nlprob.b = prob.b;
%Setup Options (note options processing done in opti_pswarm)
nlprob.options = opts;

% -- QSOPT -- %                            
function prob = setupQSOPT(prob,warn)
prob = fixLin('gen',prob,warn,'QSOPT'); %Check & Fix Linear Constraints
prob = fixSparsity(prob,warn,'QSOPT'); %Check & Fix Sparsity

% -- SCIP -- %
function [prob,nlprob] = setupSCIP(prob,opts,warn)
if(prob.ampl.useASL) %Check for AMPL solve
    nlprob = [];  
elseif(isempty(prob.fun)) %linear / quadratic
    prob = fixLin('row',prob,warn,'SCIP'); %Check & Fix Linear Constraints
    prob = fixSparsity(prob,warn,'SCIP'); %Check & Fix Sparsity
    nlprob = [];
else %nonlinear
    nlprob = prob;
    %Setup constraints
    nlprob = fixLin('row',nlprob,warn,'SCIP'); %Check & Fix Linear Constraints
    nlprob = fixSparsity(nlprob,warn,'SCIP'); %Check & Fix Sparsity
    nlprob = fixNlin('row',nlprob,warn,'SCIP'); %Check & Fix Nonlinear Constraints
    %Setup Options (note options processing done in opti_scipnl)
    nlprob.options = opts;
end

% -- SEDUMI -- %
function prob = setupSEDUMI(prob,warn)
prob = fixLin('gen_ineq',prob,warn,'SeDuMi'); %Check & Fix Linear Constraints
prob = fixSparsity(prob,warn,'SeDuMi'); %Check & Fix Sparsity
%Convert to sedumi format (or simply extract if already)
[At,b,c,K] = opti2sedumi(prob);
prob.sdcone = struct('At',At,'b',b,'c',c,'K',K);
%Clear existing vars
prob.A = []; prob.b = [];
prob.lb = []; prob.ub = [];


%Check and fix infinite bounds
function prob = fixBnds(prob,warn,solver)
if(~isempty(prob.lb))
    ind = isinf(prob.lb);
    if(any(ind))
        if(warn)
            optiwarn('opti:finbnds','%s Config - This solver expects finite lower bounds. This interface will set infinite lower bounds to -1e30, but this may cause numerical issues.',upper(solver));
        end
        prob.lb(ind) = -1e30;
    end
end
if(~isempty(prob.ub))
    ind = isinf(prob.ub);
    if(any(ind))
        if(warn)
            optiwarn('opti:finbnds','%s Config - This solver expects finite upper bounds. This interface will set infinite upper bounds to 1e30, but this may cause numerical issues.',upper(solver));
        end
        prob.ub(ind) = 1e30;
    end
end       

%Convert Linear Constraints to a Form the Solver Accepts
function prob = fixLin(mode,prob,warn,solver)

switch(mode)            
    case 'gen' %Ensure constraints of the form Ainx <= bin, Aeqx <= beq
        if(~isempty(prob.rl) || ~isempty(prob.ru))
            if(warn > 1)
                optiwarn('opti:lincon','%s Config - This solver expects linear constraints of the form A*x <= b, Aeq*x <= beq, correcting.',upper(solver));
            end
            [prob.A,prob.b,prob.Aeq,prob.beq] = row2gen(prob.A,prob.rl,prob.ru);
            %Remove unused fields
            prob.rl = []; prob.ru = [];
        end
        
    case 'row' %Ensure constraints of the form rl <= Ax <= ru
        if(~isempty(prob.b) || ~isempty(prob.beq))
            if(warn > 1)
                optiwarn('opti:lincon','%s Config - This solver expects linear constraints of the form rl <= A*x <= ru, correcting.',upper(solver));
            end
            [prob.A,prob.rl,prob.ru] = gen2row(prob.A,prob.b,prob.Aeq,prob.beq);
            %Remove unused fields
            prob.b = []; prob.Aeq = []; prob.beq = []; 
        end
        
    case 'gen_ineq' %Only Ainx <= bin
        if(~isempty(prob.rl) || ~isempty(prob.ru))
            if(warn > 1)
                optiwarn('opti:lincon','%s Config - This solver expects linear constraints of the form A*x <= b, correcting.',upper(solver));
            end
            [prob.A,prob.b,prob.Aeq,prob.beq] = row2gen(prob.A,prob.rl,prob.ru);
            %Remove unused fields
            prob.rl = []; prob.ru = []; 
        end
        if(~isempty(prob.Aeq))
            if(warn)
                optiwarn('opti:linineq',['%s Config - This solver only supports linear inequality constraints. Equality constraints '...
                                         'will be converted to ''squeezing'' inequalities, but the solver is unlikely to find a solution'],upper(solver));
            end
            prob.A = [prob.A;prob.Aeq;-prob.Aeq];
            prob.b = [prob.b;prob.beq;-prob.beq];   
            %Update sizes
            prob.sizes.nineq = prob.sizes.nineq + 2*prob.sizes.neq;
            prob.sizes.ncon = prob.sizes.ncon + prob.sizes.neq;
            prob.sizes.neq = 0;            
            %Remove unused fields
            prob.Aeq = []; prob.beq = [];
        end
        
    case 'mix' %Constraints of the form rl <= Ax <= ru AND Aeqx <= beq
        if(~isempty(prob.b))
            if(warn > 1)
                optiwarn('opti:lincon','%s Config - This solver expects linear constraints of the form rl <= A*x <= ru (ineq) AND Aeq*x = beq (beq), correcting.',upper(solver));
            end
            [prob.A,prob.rl,prob.ru] = gen2row(prob.A,prob.b,[],[]);
            %Remove unused fields
            prob.b = []; 
        end
        len = length(prob.rl);
        %Now check if any row constraints include equalities, and move if neccessary
        [prob.A,prob.rl,prob.ru,prob.Aeq,prob.beq] = rowe2gene(prob.A,prob.rl,prob.ru,prob.Aeq,prob.beq);
        %Warn if we changed anything
        if(len ~= length(prob.rl) && (warn > 1))
            optiwarn('opti:lincon','%s Config - This solver expects linear constraints of the form rl <= A*x <= ru (ineq) AND Aeq*x = beq (eq), correcting.',upper(solver));
        end
end

%Convert Nonlinear Constraints to a Form the Solver Accepts
function prob = fixNlin(mode,prob,warn,solver)

switch(mode)
    case 'gen'
        if(~isempty(prob.cl) || ~isempty(prob.cu))
            if(warn > 1)
                optiwarn('opti:nlcon','%s Config - This solver expects nonlinear constraints of the form nlcon(x) <=,>=,== nlrhs with type dictated by nle, correcting.',upper(solver));
            end
            prob = nrow2mix(prob); %more complex conversion here (if double bounded)
        end
    case 'row'
        if(~isempty(prob.nlrhs))
            if(warn > 1)
                optiwarn('opti:nlcon','%s Config - This solver expects nonlinear constraints of the form cl <= nlcon(x) <= cu, correcting.',upper(solver));
            end
            prob = nmix2row(prob);          
        end        
end

%Ensure A, Ain, Aeq, H, Arguments are sparse
function prob = fixSparsity(prob,warn,solver)

if(~isempty(prob.A) && ~issparse(prob.A))
    if(warn > 1)
        optiwarn('opti:sparse','%s Config - The A matrix should be sparse, correcting: [sparse(A)]',upper(solver));
    end
    prob.A = sparse(prob.A);
end
if(~isempty(prob.Aeq) && ~issparse(prob.Aeq))
    if(warn > 1)
        optiwarn('opti:sparse','%s Config - The Aeq matrix should be sparse, correcting: [sparse(Aeq)]',upper(solver));
    end
    prob.Aeq = sparse(prob.Aeq);
end
if(~isempty(prob.H) && ~issparse(prob.H) && isnumeric(prob.H))
    if(warn > 1)
        optiwarn('opti:sparse','%s Config - The H matrix should be sparse, correcting: [sparse(H)]',upper(solver));
    end
    prob.H = sparse(prob.H);
end
if(~isempty(prob.Q))
    if(iscell(prob.Q))
        for i = 1:length(prob.Q)
            if(~issparse(prob.Q{i}))
                if(warn > 1)
                    optiwarn('opti:sparse','%s Config - The Q matrix in cell %d, should be sparse, correcting: [sparse(Q{%d})]',upper(solver),i,i);
                end
                prob.Q{i} = sparse(prob.Q{i});
            end
        end
    elseif(~issparse(prob.Q))
        if(warn > 1)
            optiwarn('opti:sparse','%s Config - The Q matrix should be sparse, correcting: [sparse(Q)]',upper(solver));
        end
        prob.Q = sparse(prob.Q);
    end
end 
if(isfield(prob,'sdp') && ~isempty(prob.sdp))
    if(iscell(prob.sdp))
        for i = 1:length(prob.sdp)
            if(~issparse(prob.sdp{i}))
                if(warn > 1)
                    optiwarn('opti:sparse','%s Config - The SDP constraint in cell %d, should be sparse, correcting: [sparse(sdp{%d})]',upper(solver),i,i);
                end
                prob.sdp{i} = sparse(prob.sdp{i});
            end
        end
    elseif(~issparse(prob.sdp))
        if(warn > 1)
            optiwarn('opti:sparse','%s Config - The SDP constraint should be sparse, correcting: [sparse(sdp)]',upper(solver));
        end
        prob.sdp = sparse(prob.sdp);
    end
end 
        
%Ensure H is Sym TRIL
function prob = fixSymHL(prob,warn,solver)

if(~isa(prob.H,'function_handle'))
    if(any(any(triu(prob.H,1) ~= 0)))
        if(warn > 1)
            optiwarn('opti:clp','%s Config - The H matrix should be Symmetric Lower Triangular, correcting: [tril(H)]',upper(solver));
        end
        prob.H = tril(prob.H);
    end
end

%Ensure H is Sym TRIU
function prob = fixSymHU(prob,warn,solver)

if(~isa(prob.H,'function_handle'))
    if(any(any(tril(prob.H,-1) ~= 0)))
        if(warn > 1)
            optiwarn('opti:clp','%s Config - The H matrix should be Symmetric Upper Triangular, correcting: [triu(H)]',upper(solver));
        end
        prob.H = triu(prob.H);
    end
end
    
%Ensure H is Sym
function checkSymH(prob,solver)

if(~isempty(prob.H))
    %Check for symmetrical H
    sym = abs(tril(prob.H,-1)-triu(prob.H,1)') > 1e-12;
    if(any(any(sym)))       
        error('%s Config - The H matrix must be Symmetric.',upper(solver));
    end
end

%Setup Data Fitting Objective + Gradient
function [fun,grad,ydata] = setupDataFit(prob)
%Objective Callback Function   
if(~isempty(prob.xdata))
    if(nargin(prob.fun) ~= 2)
        error('When supplying xdata it is expected the objective function will take the form of fun(x,xdata)');
    end
    fun = @(x) prob.fun(x,prob.xdata);
    %Gradient needs xdata spec'd from above
    grad = @(x)mklJac(fun,x,length(prob.ydata));    
else
    fun = prob.fun;
    grad = prob.f;
end
%Data
if(strcmpi(prob.type,'SNLE'))
    if(~isempty(prob.x0))
        ydata = zeros(size(prob.x0));
    elseif(prob.sizes.ndec > 0)
        ydata = zeros(prob.sizes.ndec,1);
    else
        ydata = prob.ydata;
    end
else
    ydata = prob.ydata;
end

%Setup Nonlinear Inequality Constraints (convert >= to <=)
function [nlcon,nlrhs] = setupNLIneq(prob)
%Build Nonlinear Constraints
if(any(prob.nle == 1)) %if we have >= constraints, have to convert
    min_in = prob.nle == -1;
    max_in = prob.nle == 1;
    nlcon = @(x) nlConLE(x,prob.nlcon,max_in,min_in);
    nlrhs = prob.nlrhs;
    nlrhs(max_in) = -nlrhs(max_in);
else
    nlcon = prob.nlcon;
    nlrhs = prob.nlrhs;
end

function c = nlConLE(x,fun,max_in,min_in)
% Handle to convert nonlinear >= inequalities to <= inequalities
%Get Constraint Eval
sol = fun(x);
%Defaults
c = [];
%Assign results with bounds
if(any(max_in))
    c = -sol(max_in);
end
if(any(min_in))
    c = [c; sol(min_in)];
end

%Diagnostics state
function state = diagState(print)
if(~strcmpi(print,'off'))
    state = 'on';
else
    state = 'off';
end

%Check Problem Type
function checkPType(solver,ptype,stype)
%Check for error
if(~any(strcmpi(ptype,stype)))
	error('%s is not configured to solve a %s.',upper(solver),upper(ptype));
end

%Check Constraints
function checkCon(solver,sizes,mode)
switch(mode)
    case 'uncon'
        if(sizes.ncon > 0)
            error('%s can only solve unconstrained problems!',upper(solver));
        end
    case 'bound'
        if((sizes.nineq + sizes.neq + sizes.nnlineq + sizes.nnleq + sizes.nqc) > 0)
            error('%s can only solve bounded problems!',upper(solver));
        end
    case 'lincon'
        if((sizes.nnlineq + sizes.nnleq + sizes.nqc) > 0)
            error('%s can only solve bounded and linearly constrained problems!',upper(solver));
        end
        
    case 'lineq'
        if((sizes.neq + sizes.nnlineq + sizes.nnleq + sizes.nqc) > 0)
            error('%s can only solve bounded and linear inequality constrained problems!',upper(solver));
        end 
        
    case 'ineq'
        if((sizes.neq + sizes.nnleq + sizes.nqc) > 0)
            error('%s can only solve bounded and nonlinear inequality constrained problems!',upper(solver));
        end
        
    otherwise
        error('Unknown constraint check');
end
    


