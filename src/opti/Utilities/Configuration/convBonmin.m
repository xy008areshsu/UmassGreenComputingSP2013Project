function mprob = convBonmin(prob,opts,warn)
%CONVBONMIN Convert OPTI problem to BONMIN Mixed Integer Nonlinear problem
%
%   mprob = convBonmin(prob,opts)

%   Copyright (C) 2011 Jonathan Currie (I2C2)

%COMPATIBLE CPLEX VERSION
CPLEXVER = '12.5.0.0';

%Ensure all args passed
if(nargin < 2)
    error('You must supply both the problem + options');
end
if(~isstruct(prob) || ~isstruct(opts))
    error('Both prob + opts must be structures!');
end

%Make sure we have an MINLP
if(~any(strcmpi(prob.type,{'NLP','UNO','MINLP'})))
    error('You can only convert UNOs, NLPs and MINLPs to BONMIN format!');
end

%Ensure we have defaults for bonmin
if(isempty(opts.solverOpts))
    opts.solverOpts = bonminset;
end

%First convert to IPOPT problem (used as the internal relaxed solver)
mprob = convIpopt(prob,opts);
%Remove options from IPOPT structure we don't need
mprob.options.ipopt = rmfield(mprob.options.ipopt,'max_cpu_time'); %don't want this set in the local solver
mprob.options.ipopt = rmfield(mprob.options.ipopt,'print_level'); %don't want this set in the local solver
%Remove options already at OPTI default (appears BONMIN sets some internally different from docs)
mprob.options.ipopt = removeDefaults(mprob.options.ipopt,ipoptset('bonmin'));

%Set BONMIN options
mprob.options.bonmin = bonminset(opts.solverOpts,'noIpopt');
%Remove options set elsewhere
mprob.options.bonmin = rmfield(mprob.options.bonmin,'var_lin'); 
mprob.options.bonmin = rmfield(mprob.options.bonmin,'cons_lin'); 
%Remove options already at OPTI default (appears BONMIN sets some internally different from docs)
mprob.options.bonmin = removeDefaults(mprob.options.bonmin,bonminset());

%If user has specified Cplex, ensure we can load it
if(isfield(mprob.options.bonmin,'milp_solver') && strcmpi(mprob.options.bonmin.milp_solver,'cplex'))
    try
        %Forces to load Cplex on current platform (x86 or x64) if MATLAB interface present
        c = Cplex; %#ok<NASGU>
    catch %#ok<CTCH>
       %nothing to do 
    end
    try
        %The following will fail with a "cannot load module" if it cannot find correct version of Cplex DLL on user's PC
        v = bonminCplex(); %#ok<NASGU>
    catch %#ok<CTCH>
        if(warn)
            optiwarn('opti:bonmin_Cplex','Could not load BONMIN with CPLEX - ensure CPLEX (v%s) is installed and licensed on your PC. Using CBC for now.',CPLEXVER);
        end
        mprob.options.bonmin = rmfield(mprob.options.bonmin,'milp_solver'); 
    end
end

%Convert OPTISET options to equivalent BONMIN ones
mprob.options.bonmin.node_limit = opts.maxnodes;
mprob.options.bonmin.time_limit = opts.maxtime;
mprob.options.bonmin.integer_tolerance = opts.tolint;

%Set Display Level
if(strcmpi(opts.display,'iter'))
    mprob.options.display = 1;
else
    mprob.options.display = 0;
end

%Setup Integer Vars
mprob.options.var_type = prob.int.ind; %uses -1, 0, 1 format
%Setup Nonlinear Vars
if(isnan(opts.solverOpts.var_lin))
    mprob.options.var_lin = zeros(prob.sizes.ndec,1); %for now assuming all nonlinear
else
    varlin = opts.solverOpts.var_lin;
    if(length(varlin) ~= prob.sizes.ndec)
        error('The decision variable linearity vector is the wrong size! Expected %d x 1',prob.sizes.ndec);
    else
        mprob.options.var_lin = varlin;
    end
end
%Setup Nonlinear Constraints
nnlcon = prob.sizes.nnlineq + prob.sizes.nnleq;
ncon = prob.sizes.nineq + prob.sizes.neq;
if(isnan(opts.solverOpts.cons_lin))
    if(~nnlcon) %all linear
        mprob.options.cons_lin = ones(ncon,1);
    else
        mprob.options.cons_lin = [zeros(nnlcon,1); ones(ncon,1)]; %augment both kinds
    end
else
    conslin = opts.solverOpts.cons_lin;
    if(length(conslin) ~= (ncon+nnlcon))
        error('The constraint linearity vector is the wrong size! Expected %d x 1',ncon+nnlcon);
    else
        mprob.options.cons_lin = conslin;
    end
end

function opts = removeDefaults(opts,defs)
oFn = fieldnames(opts);
for i = 1:length(oFn)
    label = oFn{i};
    if(isfield(defs,label))
        if(ischar(opts.(label)))
            if(strcmpi(defs.(label),opts.(label)))
                opts = rmfield(opts,label);
            end
        else
            if(defs.(label) == opts.(label))
                opts = rmfield(opts,label);
            end
        end
    end
end