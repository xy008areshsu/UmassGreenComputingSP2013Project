function [prob,opts] = buildOpti(varargin)
%Build an OPTI object
%
%   Called By OPTI Constructor

%   Copyright (C) 2011-2012 Jonathan Currie (I2C2)

%API Change to make optiprob redundant (1/5/12)
[prob,opts] = exPrbOpts(varargin{:});

%Check and correct problem size and setup errors
[prob,opts] = checkOpti(prob,opts);


function [prob,opts] = checkOpti(prob,opts)
%Check the objective, constraints and options when building an OPTI object

%Get Warning Level
if(strcmpi(opts.warnings,'all'))
    warn = 2;
elseif(strcmpi(opts.warnings,'critical'))
    warn = 1;
else
    warn = 0;
end

%Numerical Differences Structure
numdif = struct('grad',0,'hess',0,'jac',0);
%AMPL Interface Structure
ampl = struct('path',prob.path,'useASL',0,'writesol',0);

%Sizes structure
siz = struct('ndec',[],'ncon',[],'nrow',[],'nineq',[],'neq',[],'nbnds',[],'nbin',[],'nint',[],'nqc',[],'nsdcone',[],'nnlineq',[],'nnleq',[],'nsos',[],'nsos1',[],'nsos2',[]);

%--Check Data Types--%
if(~isempty(prob.f) && ~isa(prob.f,'function_handle')), prob.f = chkdouble(prob.f,'prob.f',warn > 1); end
if(~isempty(prob.H) && ~isa(prob.H,'function_handle')), prob.H = chkdouble(prob.H,'prob.H',warn > 1); end
if(~isempty(prob.A)),   prob.A = chkdouble(prob.A,'prob.A',warn > 1); end
if(~isempty(prob.b)),   prob.b = chkdouble(prob.b,'prob.b',warn > 1); end
if(~isempty(prob.Aeq)), prob.Aeq = chkdouble(prob.Aeq,'prob.Aeq',warn > 1); end
if(~isempty(prob.beq)), prob.beq = chkdouble(prob.beq,'prob.beq',warn > 1); end
if(~isempty(prob.rl)),  prob.rl = chkdouble(prob.rl,'prob.rl',warn > 1); end
if(~isempty(prob.ru)),  prob.ru = chkdouble(prob.ru,'prob.ru',warn > 1); end
if(~isempty(prob.cl)),  prob.cl = chkdouble(prob.cl,'prob.cl',warn > 1); end
if(~isempty(prob.cu)),  prob.cu = chkdouble(prob.cu,'prob.cu',warn > 1); end
if(~isempty(prob.nlrhs)),  prob.nlrhs = chkdouble(prob.nlrhs,'prob.nlrhs',warn > 1); end
if(~isempty(prob.x0)),  prob.x0 = chkdouble(prob.x0,'prob.x0',warn > 1); end
if(~isempty(prob.xdata)),  prob.xdata = chkdouble(prob.xdata,'prob.xdata',warn > 1); end
if(~isempty(prob.ydata)),  prob.ydata = chkdouble(prob.ydata,'prob.ydata',warn > 1); end

%--Check Objective Function--%
%Check we at least have an opti problem
if(isempty(prob.f) && isempty(prob.fun) && (isempty(prob.sdcone) || ~isstruct(prob.sdcone) || ~isfield(prob.sdcone,'b')))
    %see if we have lse
    if(isempty(prob.A) || isempty(prob.b))
        error('You have not supplied the objective function in a readable form - or it is empty!');
    else %equation problem
        [prob,opts] = buildSLE(prob,opts);
        prob.sizes = siz;       
        prob.sizes.ndec = size(prob.A,1);
        prob.ampl = ampl;
        return;
    end
end

%Transpose f if required
if(size(prob.f,2) > 1)
    prob.f = prob.f';
end
if(~isempty(prob.x0))
    [r,c] = size(prob.x0);
    if(r > 1 && c > 1)
        error('OPTI does not currently solve matrix problems. Please use reshape() within your objective / constraints, and pass x0 as a vector to OPTI to solve these problems');
    end
    if(c > 1)
        prob.x0 = prob.x0';
    end
    if(issparse(prob.x0))
        if(warn > 1), optiwarn('opti:sparsex0','The initial guess (x0) must be a dense vector'); end
        prob.x0 = full(prob.x0);
    end
end

%Check correct sizes for QP
if(~isempty(prob.H) && ~isa(prob.H,'function_handle'))
    if(isempty(prob.f))
        error('When solving a QP you must supply both H and f!');
    else
        [n,m] = size(prob.H);
        p = length(prob.f);
        if(n ~= p || m ~= p)
            error('The sizes of the QP H and f matrices don''t correspond!');
        end
    end
end

%Get ndec if not NL
if(~isempty(prob.f) && ~isa(prob.f,'function_handle'))
    siz.ndec = length(prob.f);
elseif(~isempty(prob.H) && ~isa(prob.H,'function_handle'))
    siz.ndec = size(prob.H,1);
elseif(~isempty(prob.sdcone) && isstruct(prob.sdcone) && isfield(prob.sdcone,'b'))
    siz.ndec = length(prob.sdcone.b); %sedumi b
end

%Check x0 if we have ndec
if(~isempty(siz.ndec) && ~isempty(prob.x0))
    if(siz.ndec  ~= length(prob.x0))
        error('The supplied x0 is not the correct length, expected %d x 1',siz.ndec);
    end
end

%Check for NL grad
if(~isempty(prob.fun) && isempty(prob.f))
    %Get Solver Info
    info = optiSolverInfo(opts.solver,[],[],opts);
    %Use finite difference if requires derivative
    if(info.der1)    
        if(warn > 1), optiwarn('opti:mkljac','OPTI will use MKLJAC (Numerical Difference Algorithm) for the Objective Gradient Function'); end
        %Check for Data fitting problem
        if(~isempty(prob.ydata))
            prob.f = @(x) mklJac(prob.fun,x,length(prob.ydata));
        %Normal objective, single row
        else
            prob.f = @(x) mklJac(prob.fun,x,1);
        end
        numdif.grad = 1;
    end
end 

%Check for NL hess (never really approximate using numdiff)
if(~isempty(prob.fun) && isempty(prob.f))
    numdif.hess = 1;
end

%--Check Constraints--%
%Get ndec
if(isempty(siz.ndec))
    if(~isempty(prob.x0))
        siz.ndec = length(prob.x0);
    elseif(~isempty(prob.lb))
        siz.ndec = length(prob.lb);
    elseif(~isempty(prob.ub))
        siz.ndec = length(prob.ub);
    elseif(~isempty(prob.f) && isnumeric(prob.f))
        siz.ndec = length(prob.f);
    elseif(~isempty(prob.H) && isnumeric(prob.H))
        siz.ndec = size(prob.H,1);
    elseif(~isempty(prob.A))
        siz.ndec = size(prob.A,2);
    elseif(~isempty(prob.Aeq))
        siz.ndec = size(prob.Aeq,2);    
    elseif(~isempty(prob.int))
        siz.ndec = length(prob.int);
    elseif(~isempty(prob.nljacstr))
        siz.ndec = size(prob.nljacstr(),2);
    elseif(~isempty(prob.Hstr))
        siz.ndec = size(prob.Hstr(),2);    
    else
        siz.ndec = []; %Can't determine sizes! All NL
    end
end

%If sdcone supplied as a structure, assume SeDuMi format and convert to OPTI form (if not using sedumi as the solver)
if(~isempty(prob.sdcone) && isstruct(prob.sdcone) && isfield(prob.sdcone,'b'))
    if(strcmpi(opts.solver,'auto'))
        opts.solver = 'sedumi'; %use sedumi to solve sedumi problems        
    end
    if(~strcmpi(opts.solver,'sedumi'))
        prob = sedumi2opti(prob); %otherwise convert to opti format
    end
end

%Process Integer Constraints
prob = checkInt(prob,siz.ndec);

%Determine what constraints are used
[cA,cb,cAeq,cbeq,cru,crl,clb,cub,cqc,cqrl,cqru,csdp,cint,cnl,ccl,ccu,csos] = conUsed(prob);

%Auto-fill constraint pairs if we know enough information
if(cA && crl && ~cru), prob.ru = Inf(size(prob.rl)); cru = 1; end
if(cA && cru && ~crl), prob.rl = -Inf(size(prob.ru)); crl = 1; end
if(cnl && ccl && ~ccu), prob.cu = Inf(size(prob.cl)); ccu = 1; end
if(cnl && ccu && ~ccl), prob.cl = -Inf(size(prob.cu)); ccl = 1; end

%Check correct constraint pairs used
if(crl && (cb || cbeq))
    error('Currently you cannot supply both linear row based constraints (rl <= Ax <= ru) and linear inequality constraints (Ax <= b, Aeqx = beq)');
end
if(cb && ~cA)
    error('You must supply A and b for Inequality Constraints!')
end
if(crl && ~cA)
    error('You must supply A, rl and ru for Linear Constraints!')
end
if(crl && length(prob.rl) ~= length(prob.ru))
    error('Constraint vectors rl and ru are not the same size');
end
if(xor(cAeq,cbeq))
    error('You must supply Aeq and beq for Equality Constraints!');
end
if(cnl)
    if(xor(isempty(prob.cl),isempty(prob.cu)))
        error('You must supply both bounds (cl, cu) for Nonlinear Constraints!');
    end
    if(isempty(prob.cl) && isempty(prob.nlrhs))
        %If we know ndec, we can assume all constraints are <= 0, otherwise error
        if(~isempty(siz.ndec))
            if(warn)
               optiwarn('opti:nlempty','You have not supplied the right hand side (nlrhs) or bounds (cl,cu) of the Nonlinear Constraints. OPTI will assume all are <= 0.'); 
            end
            testC = prob.nlcon(zeros(siz.ndec,1)); nnl = length(testC);
            prob.nlrhs = zeros(nnl,1);
            prob.nle = -1*ones(nnl,1);
        else
            error('You must supply the Right Hand Side (nlrhs) OR constraint bounds (cl, cu) for Nonlinear Constraints! If you wish to default to all <= 0, please supply ndec.');
        end
    end
    if(~isempty(prob.cl) && ~isempty(prob.nlrhs))
        error('Currently you cannot supply both nonlinear row based constraints (cl <= nlcon(x) <= cu) and nonlinear mixed constraints (nlcon, nlrhs, nle)');
    end
end
if(~isempty(prob.sos) && xor(isempty(prob.sos.index),isempty(prob.sos.weight)))
    error('You must supply the SOS type, indices and weights!');
end

%See if we are constrained or not
if(~cA && ~cAeq && ~clb && ~cub && ~cqc && ~csdp && ~cint && ~cnl && ~csos)
    prob.iscon = 0;
    checkLP(prob);
else
    prob.iscon = 1;
end

%Get Constraint Sizes
if(crl)
    eq = prob.rl == prob.ru;
    neq = sum(eq);
    nineq = sum(~isinf(prob.rl))+sum(~isinf(prob.ru))-2*neq;
else
    if(cb)
        nineq = length(prob.b);
    elseif(isstruct(prob.sdcone) && isfield(prob.sdcone,'K') && isfield(prob.sdcone.K,'l'))
        nineq = prob.sdcone.K.l;
    else
        nineq = 0; 
    end
    if(cbeq); neq = length(prob.beq); else neq = 0; end
end
if(clb); nbnds = length(find(~isinf(prob.lb) > 0)); else nbnds = 0; end
if(cub); nbnds = nbnds + length(find(~isinf(prob.ub) > 0)); end
if(cint)
    nbin = length(find(prob.int.str == 'B'));
    nint = length(find(prob.int.str == 'I'));
else
    nbin = 0; nint = 0;
end
if(cnl)
    if(~isempty(prob.nlrhs))
        nnl = length(prob.nlrhs);
    else
        nnl = length(prob.cl);
    end
else 
    nnl = 0; 
end
if(cqc)
    if(iscell(prob.Q)), nqc = length(prob.Q); else nqc = 1; end
else
    nqc = 0;
end
if(csdp)
    if(iscell(prob.sdcone))
        nsdcone = length(prob.sdcone); 
    elseif(isstruct(prob.sdcone) && isfield(prob.sdcone,'K') && isfield(prob.sdcone.K,'s'))
        nsdcone = length(prob.sdcone.K.s);
    else
        nsdcone = 1; 
    end
else
    nsdcone = 0;
end
if(csos)
    nsos = length(prob.sos.type);
    [r,c] = size(prob.sos.type);
    if(r > c)
        t = str2num(prob.sos.type); %#ok<*ST2NM>
    else
        t = str2num(prob.sos.type');
    end
    nsos1 = sum(t==1);
    nsos2 = sum(t==2);
else
    nsos = 0; 
    nsos1 = 0;
    nsos2 = 0;
end

%Collect number of constraints
ncon = nineq + neq + nbnds + nqc + nsdcone + nbin + nint + nnl + nsos;

%Transpose as neccesary
if(cb && size(prob.b,2) > 1)
    prob.b = prob.b';
end
if(cbeq && size(prob.beq,2) > 1)
    prob.beq = prob.beq';
end
if(crl && size(prob.rl,2) > 1)
    prob.rl = prob.rl';
end
if(cru && size(prob.ru,2) > 1)
    prob.ru = prob.ru';
end
if(clb && size(prob.lb,2) > 1)
    prob.lb = prob.lb';
end
if(cub && size(prob.ub,2) > 1)
    prob.ub = prob.ub';
end
if(cnl && size(prob.nlrhs,2) > 1)
    prob.nlrhs = prob.nlrhs';
end
if(cnl && size(prob.cl,2) > 1)
    prob.cl = prob.cl';
end
if(cnl && size(prob.cu,2) > 1)
    prob.cu = prob.cu';
end
%Check and transpose quadratic constraints
if(cqc)
    %Convert l, r to numeric if cells
    if(iscell(prob.l))
        if(size(prob.l,1) > 1 && size(prob.l,2) > 1)
            error('Quadratic constraint l must be a column cell array');
        end
        n = length(prob.l);
        l = zeros(siz.ndec,n);
        for i = 1:n
            li = prob.l{i};
            if(size(li,1) > 1 && size(li,2) > 1)
                error('Quadratic constraint l in cell %d must be a column vector!',i);
            end
            if(size(li,2) > 1)
                li = li';
            end
            l(:,i) = li;
        end
        prob.l = l;    
    end
    prob.l = chkdouble(prob.l,'prob.l',warn > 1);
    if(iscell(prob.qrl))
        if(size(prob.qrl,1) > 1 && size(prob.qrl,2) > 1)
            error('Quadratic constraint qrl must be a column cell array');
        end
        n = length(prob.qrl);
        qrl = zeros(n,1);
        for i = 1:n
            qrli = prob.qrl{i};
            if(size(qrli,1) > 1 || size(qrli,2) > 1)
                error('Quadratic constraint qrl in cell %d must be a column scalar!',i);
            end
            qrl(i) = qrli;
        end
        prob.qrl = qrl;         
    end
    if(iscell(prob.qru))
        if(size(prob.qru,1) > 1 && size(prob.qru,2) > 1)
            error('Quadratic constraint qru must be a column cell array');
        end
        n = length(prob.qru);
        qru = zeros(n,1);
        for i = 1:n
            qrui = prob.qru{i};
            if(size(qrui,1) > 1 || size(qrui,2) > 1)
                error('Quadratic constraint qru in cell %d must be a column scalar!',i);
            end
            qru(i) = qrui;
        end
        prob.qru = qru;         
    end
    prob.qrl = chkdouble(prob.qrl,'prob.qrl',warn > 1);
    prob.qru = chkdouble(prob.qru,'prob.qru',warn > 1);
    if(iscell(prob.Q))
        if(size(prob.Q,2) > 1)
            prob.Q = prob.Q';
        end
    else
        if(size(prob.l,2) > 1)
            prob.l = prob.l';
        end
    end
    if(size(prob.qrl,2) > 1)
        prob.qrl = prob.qrl';
    end
    if(size(prob.qru,2) > 1)
        prob.qru = prob.qru';
    end
end
%Auto fill missing quadratic bounds
if(cqc && cqrl && ~cqru), prob.qru = Inf(size(prob.qrl)); cqru = 1; end
if(cqc && cqru && ~cqrl), prob.qrl = -Inf(size(prob.qru)); cqrl = 1; end
if(cqrl && ~cqc)
    error('You must supply Q, l, qrl and qru for Quadratic Constraints!')
end
if(cqrl && length(prob.qrl) ~= length(prob.qru))
    error('Constraint vectors qrl and qru are not the same size');
end

%Check and transpose SOS constraints
if(csos)
    if(size(prob.sos.type,2) > 1)
        prob.sos.type = prob.sos.type';
    end
    if(iscell(prob.sos.index))
        if(size(prob.sos.index,2) > 1)
            prob.sos.index = prob.sos.index';
        end
        for i = 1:length(prob.sos.index)
            if(size(prob.sos.index{i},2) > 1)
                prob.sos.index{i} = prob.sos.index{i}';
            end
        end
    else
        if(size(prob.sos.index,2) > 1)
            prob.sos.index = prob.sos.index';
        end
    end
    if(iscell(prob.sos.weight))
        if(size(prob.sos.weight,2) > 1)
            prob.sos.weight = prob.sos.weight';
        end
        for i = 1:length(prob.sos.weight)
            if(size(prob.sos.weight{i},2) > 1)
                prob.sos.weight{i} = prob.sos.weight{i}';
            end
        end
    else
        if(size(prob.sos.weight,2) > 1)
            prob.sos.weight = prob.sos.weight';
        end
    end
end

%Fill in nle if empty (assumes all <=)
if(cnl && isempty(prob.cl) && isempty(prob.nle))
    if(warn)
        optiwarn('opti:build','Nonlinear Constraint Bounds (cl, cu) and Type (nle) are Empty - Assuming all Nonlinear Constraints are nlcon(x) <= nrhs');
    end
    prob.nle = -1*ones(nnl,1);
end

%Check for NL jac
if(cnl && isempty(prob.nljac))
    %Get Solver Info
    info = optiSolverInfo(opts.solver,[],[],opts);
    %Use finite difference if requires derivative
    if(info.der1)             
        if(warn > 1),optiwarn('opti:mkljac','OPTI will use MKLJAC (Numerical Difference Algorithm) for the Constraint Jacobian Function'); end
        numdif.jac = 1;
        prob.nljac = @(x) mklJac(prob.nlcon,x,nnl);
    end
end        

%Check Sizes if possible
if(cA && (siz.ndec ~= size(prob.A,2)))
    error('Constraint A matrix is the wrong size! Expected %d x %d (nineq x ndec)',nineq,siz.ndec);
end
if(cAeq && (siz.ndec ~= size(prob.Aeq,2)))
    error('Constraint Aeq matrix is the wrong size! Expected %d x %d (neq x ndec)',neq,siz.ndec);
end
if(clb && (siz.ndec ~= length(prob.lb)))
    error('Incorrect size of lb! Expected %d x 1 (ndec x 1)',siz.ndec);
end
if(cub && (siz.ndec ~= length(prob.ub)))
    error('Incorrect size of ub! Expected %d x 1 (ndec x 1)',siz.ndec);
end
if(crl)
    if(length(prob.rl) ~= size(prob.A,1))
        error('Constraint A matrix is the wrong size! Expected %d x %d (nlincon x ndec)',nineq+neq,siz.ndec);
    end
    if(length(prob.rl) ~= length(prob.ru))
        error('Linear constraints bounds rl and ru are not the same length!');
    end
else
    if(cA && isempty(prob.b))
        error('You must supply both A and b for inequality constraints');
    end
    if(cA && (length(prob.b) ~= size(prob.A,1)))
        error('Constraint A matrix is the wrong size! Expected %d x %d (nineq x ndec)',nineq,siz.ndec);
    end
    if(cAeq && isempty(prob.beq))
        error('You must supply both Aeq and beq for inequality constraints');
    end
    if(cAeq && (length(prob.beq) ~= size(prob.Aeq,1)))
        error('Constraint Aeq matrix is the wrong size! Expected %d x %d (neq x ndec)',neq,siz.ndec);
    end
end
if(cnl && (length(prob.nlrhs) ~= length(prob.nle)))
    error('Nonlinear RHS and e vectors are not the same length!');
end
if(ccl && ccu && (length(prob.cl) ~= length(prob.cu)))
    error('Nonlinear cl and cu vectors are not the same length!');
end
if(cqc)    
    if(iscell(prob.Q))
        if(length(prob.Q) ~= size(prob.l,2) || siz.ndec ~= size(prob.l,1))
            error('Quadratic Constraint l matrix is the wrong size! Expected %d x %d (ndec x nqc)',siz.ndec,length(prob.Q));
        end
        if(length(prob.Q) ~= length(prob.qrl))
            error('Quadratic Constraint qrl vector is the wrong size! Expected %d x %d (nqc x 1)',length(prob.Q),1);
        end
    else
        if(1 ~= size(prob.l,2) || siz.ndec ~= size(prob.l,1))
            error('Quadratic Constraint l vector is the wrong size! Expected %d x %d (ndec x nqc)',siz.ndec,1);
        end
        if(1 ~= length(prob.qrl))
            error('Quadratic Constraint qrl vector is the wrong size! Expected %d x %d (nqc x 1)',1,1);
        end
    end
end
if(csos)
    ns = length(prob.sos.type);
    if(ns > 1)
        if(~iscell(prob.sos.index))
            error('SOS Index argument is not a cell! Expected a cell array of %d x 1 (nsos x 1)',ns);
        elseif(length(prob.sos.index) ~= ns)
            error('SOS Index cell array is the wrong size! Expected %d x 1 (nsos x 1)',ns);
        end
        if(~iscell(prob.sos.weight))
            error('SOS Weights argument is not a cell! Expected a cell array of %d x 1 (nsos x 1)',ns);
        elseif(length(prob.sos.weight) ~= ns)
            error('SOS Weights cell array is the wrong size! Expected %d x 1 (nsos x 1)',ns);
        end
        for i = 1:ns
            if(length(prob.sos.index{i}) ~= length(prob.sos.weight{i}))
                error('SOS Constraint %d Index and Weight vectors are not the same length!',i);
            end
            if(any(prob.sos.index{i} < 1))
                error('SOS Constraint %d Index vector must contain indices greater than 0 (MATLAB Indexing)!',i);
            end
        end
    else
        if(iscell(prob.sos.index) || iscell(prob.sos.weight))
            error('Only use cell arrays for multiple SOS constraints. Either sosind or soswt is a cell array - but there is only one SOS.');
        end
        if(length(prob.sos.index) ~= length(prob.sos.weight))
            error('SOS Index and Weight vectors are not the same length!');
        end
        if(any(prob.sos.index < 1))
            error('SOS Index vector must contain indices greater than 0 (MATLAB Indexing)!');
        end
    end
end
        
% Check Quadratic Constraints
QCisconvex = true;
if(cqc)   
    %If we have any quadratic equalities OR double sided inequalities (assumed non-convex)
    %and the user has not specified a solver, default to SCIP (if available)
    if(any(~isinf(prob.qrl) & ~isinf(prob.qru)))
        if(strcmpi(opts.solver,'auto') && checkSolver('scip',0))
            opts.solver = 'scip';
        end
    end
    if(issparse(prob.l))
       prob.l = full(prob.l); %ensure dense
    end
    if(iscell(prob.Q))
       if(iscell(prob.l) || iscell(prob.qrl) || iscell(prob.qru))
           error('Only Quadratic Constraints Q may be a cell!');
       end       
       r0 = size(prob.Q,1);
       c1 = size(prob.l,2);
       r2 = size(prob.qrl,1);
       r3 = size(prob.qru,1);
       if(r0 ~= c1 || r0 ~= r2 || r0 ~= r3)
           error('Quadratic Constraints Q + l + qrl + qru are not the same length!');
       end
       for i = 1:r0
           %Check Data Type
           prob.Q{i} = chkdouble(prob.Q{i},['prob.Q{',i,'}'],warn > 1);
           Q = prob.Q{i};
           l = prob.l(:,i);
           rl = prob.qrl(i);
           ru = prob.qru(i);
           %Check constraint
           QCisconvex = QCisconvex & chkQC(Q,l,rl,ru,i,siz.ndec,opts.solver);
       end
    else 
        %Check Data Type
        prob.Q = chkdouble(prob.Q,'prob.Q',warn > 1);
        %Check constraint
        QCisconvex = QCisconvex & chkQC(prob.Q,prob.l,prob.qrl,prob.qru,1,siz.ndec,opts.solver);
    end
end

% Check Semidefinite Constraints
if(csdp)
    if(~isfield(siz,'ndec') || isempty(siz.ndec))
        error('In order to process semidefinite constraints you must supply ndec as well');
    end
    if(iscell(prob.sdcone))
        %Check Data type
        for i = 1:length(prob.sdcone)
            prob.sdcone{i} = chkdouble(prob.sdcone{i},sprintf('prob.sdcone{%d}',i),warn > 1);
            %Check and convert representation
            prob.sdcone{i} = chkSDCone(prob.sdcone{i},i,siz.ndec,warn);
        end
    elseif(isstruct(prob.sdcone)) %sedumi format
        %Correct structure names
        if(isfield(prob.sdcone,'A'))
            prob.sdcone.At = prob.sdcone.A;
            prob.sdcone = rmfield(prob.sdcone,'A');
        end
        if(isfield(prob.sdcone,'C'))
            prob.sdcone.c = prob.sdcone.C;
            prob.sdcone = rmfield(prob.sdcone,'C');
        end
        %Check data types
        prob.sdcone.At = chkdouble(prob.sdcone.At,'prob.sdcone.At',warn > 1);
        prob.sdcone.b = chkdouble(prob.sdcone.b,'prob.sdcone.b',warn > 1);
        prob.sdcone.c = chkdouble(prob.sdcone.c,'prob.sdcone.c',warn > 1);
        if(isfield(prob.sdcone,'K') && ~isstruct(prob.sdcone.K))
            error('SeDuMi prob.sdcone.K should be a structure!');
        end
    else
        %Check data type
        prob.sdcone = chkdouble(prob.sdcone,'prob.sdcone',warn > 1);
        %Check and convert representation
        prob.sdcone = chkSDCone(prob.sdcone,1,siz.ndec,warn);
    end    
end

% Check Special Ordered Sets
if(csos)
    %Check types are correct
    types = str2num(prob.sos.type);
    if(any(types < 1 | types > 2))
        error('Only SOS types 1 and 2 are allowed!');
    end   
    %Check Datatypes
    if(nsos > 1)
        %Check vectors
        for i = 1:nsos
            %Check Data Types
            prob.sos.index{i} = chkdouble(prob.sos.index{i},['prob.sos.index{',i,'}'],warn > 1);
            prob.sos.weight{i} = chkdouble(prob.sos.weight{i},['prob.sos.weight{',i,'}'],warn > 1);
        end  
    else
        prob.sos.index = chkdouble(prob.sos.index,'prob.sos.index',warn > 1);
        prob.sos.weight = chkdouble(prob.sos.weight,'prob.sos.weight',warn > 1);
    end    
end

%Check bounds direction
if(clb && cub)
    if(any(prob.ub < prob.lb))
        error('A lower bound is greater than its respective upper bound!');
    end
end
if(ccl && ccu)
    if(any(prob.cu < prob.cl))
        error('A nonlinear constraint lower bound is greater than its respective upper bound!');
    end
end
if(crl && cru)
    if(any(prob.ru < prob.rl))
        error('A linear constraint lower bound is greater than its respective upper bound!');
    end
end
if(cqrl && cqru)
    if(any(prob.qru < prob.qrl))
        error('A quadratic constraint lower bound is greater than its respective upper bound!');
    end
end

%Check for sparse bounds (causes problems when size doesn't match nz entries)
if(clb && issparse(prob.lb))
    error('The lower bound vector (lb) must be dense');
end
if(cub && issparse(prob.ub))
    error('The upper bound vector (ub) must be dense');
end
if(crl && issparse(prob.rl))
    error('The linear constraint lower bound vector (rl) must be dense');
end
if(cru && issparse(prob.ru))
    error('The linear constraint upper bound vector (ru) must be dense');
end
if(cb && issparse(prob.b))
    error('The linear inequality constraint RHS (b) must be dense');
end
if(cbeq && issparse(prob.beq))
    error('The linear equality constraint RHS (beq) must be dense');
end
if(ccl && issparse(prob.cl))
    error('The nonlinear constraint lower bound vector (cl) must be dense');
end
if(ccu && issparse(prob.cu))
    error('The nonlinear constraint upper bound vector (cu) must be dense');
end

%Check nonlinear constraints
if(cnl)
    if(~ccl && (any(prob.nle > 1) || any(prob.nle < -1)))
        error('Nonlinear constraint type (nle) must only contain -1, 0 or 1');
    end
end      
    
%Fill in Sizes Structure
siz.ncon = ncon;
siz.nineq = nineq;
siz.neq = neq;
siz.nbnds = nbnds;
siz.nbin = nbin;
siz.nint = nint;
siz.nqc = nqc;
siz.nsdcone = nsdcone;
siz.nsos = nsos;
siz.nsos1 = nsos1;
siz.nsos2 = nsos2;
if(crl)
    siz.nrow = nineq+neq;
else
    siz.nrow = 0;
end
if(cnl)
    if(ccl)
        eq = prob.cl == prob.cu; neq = ~eq;
        ile = isfinite(prob.cu) & neq;
        ige = isfinite(prob.cl) & neq;
        siz.nnlineq = sum(ile + ige);
        siz.nnleq = sum(eq);
        %If we have dual bounds, our number of con will be out
        if(any(ile & ige))
            siz.ncon = siz.ncon + sum(ile & ige);
        end
    else
        siz.nnlineq = sum(prob.nle ~= 0);
        siz.nnleq = sum(prob.nle == 0);
    end
else
    siz.nnlineq = 0;
    siz.nnleq = 0;
end
prob.sizes = siz;
%Fill in numerical differences structure
prob.numdif = numdif;


%-- Determine Problem Type --%
%Pre Check
if(isempty(prob.H) && isempty(prob.fun))
    prb = 'LP';
elseif(isempty(prob.fun))
    prb = 'QP';
else
    prb = 'NLP';
end
%Check we don't have function handles for H, f
if(~strcmpi(prb,'NLP'))
    if(isa(prob.H,'function_handle')) %QP
        error('When solving a Quadratic Problem the H matrix must be a double matrix - not a function handle');
    end
    if(isa(prob.f,'function_handle')) %LP or %QP
        error('When solving a Linear or Quadratic Problem the f vector must be a double vector - not a function handle');
    end
end
%Check for quadratic constraints
if(nqc)
    if(~strcmpi(prb,'QP'))
        error('Currently Quadratic Constraints are only supported with Quadratic Programs. Please reformulate your problem as a general nonlinear problem with nonlinear constraints');
    end
    prb = ['QC' prb];
end
if(nsdcone)
    if(~strcmpi(prb,'LP'))
        error('Currently only Semidefinite Constraints are supported with Linear Programs');
    end
    prb = 'SDP';
end
%Check for integer variables
if(any(prob.int.ind ~= 0) || nsos)
    if(all(prob.int.ind < 0) && strcmpi(prb,'LP')) %only allow BILPs
        prb = ['BI' prb];
    else
        prb = ['MI' prb];
    end
end
%Check if NLS
if(strcmpi(prb,'NLP') && (~isempty(prob.xdata) || ~isempty(prob.ydata)))
    prb = 'NLS';
elseif(~isempty(prob.xdata) || ~isempty(prob.ydata))
    error('Currently only Nonlinear Least Squares Problems are Supported');
end

%Check we don't have nlcon with lp/qp/other
if(cnl && isempty(strfind(prb,'NLP')))
    error('Nonlinear Constraints are only supported with Nonlinear Programs. Please reformulate your problem as a general nonlinear problem with nonlinear constraints');
end
%Check if UNO (scalar) or SNLE (vector)
if(strcmpi(prb,'NLP') && ~prob.iscon)
    % Get x0 (or try and make one)
    if(isfield(prob,'x0') && ~isempty(prob.x0))
        x0 = prob.x0;
    elseif(prob.sizes.ndec)
        x0 = zeros(prob.sizes.ndec,1);
    else
        error('OPTI cannot determine whether you are solving a UNO or SNLE. Please supply ndec or x0 to optiprob to continue.');
    end
    l = length(prob.fun(x0));
    if(l > 1)
        %Check n = n
        if(l ~= length(x0))
            error('OPTI can only solve nonlinear equations which have n equations and n variables');
        end
        prb = 'SNLE';
        %Correct for numdiff size (defaults to scalar objective)
        if(numdif.grad)
            prob.f = @(x) mklJac(prob.fun,x,l);
        end
    else    
        prb = 'UNO';
    end
end

%Matlab MI check
if(strcmpi(opts.solver,'matlab'))
    if(any(strcmpi(prb,{'MILP','MIQP','MIQCQP','SDP','MINLP'})))
        solver = checkSolver(['best_' prb]);
        if(warn)
            optiwarn('opti:mi','MATLAB does not currently supply a Mixed Integer or Semidefinite Solver\nUsing %s instead.',solver);
        end
        opts = optiset(opts,'solver',solver);
    end
end

%If user has specified a problem type manually, compare to auto one
if(isfield(prob,'probtype') && ~isempty(prob.probtype))
    if(~strcmpi(prob.probtype,prb))
        %Check user field exists
        ptypes = checkSolver('ptypes');
        switch(lower(prob.probtype))
            case ptypes
                if(warn)
                    optiwarn('opti:ptype','You have specified the problem type as a %s but OPTI identified the problem type as a %s. OPTI''s decision will be overridden.',upper(prob.probtype),upper(prb));
                end
            otherwise
                error('Unknown problem type specified in optiprob: %s',upper(prob.probtype));
        end        
    end
    prb = upper(prob.probtype);
end

%Save problem type
prob.type = prb;
if(strcmp(prob.Name,'OPTI Problem'))
    prob.Name = ['OPTI ' upper(prb) ' Problem'];
end

%-- Check (and Correct) Options based on Problem Type & Settings --%

%BILP with bounds
switch(prb)
    case 'BILP'
        if((~isempty(prob.lb) || ~isempty(prob.ub)) && warn > 1)            
            optiwarn('opti:bilp','Bounds are not currently used in BILP problems');
        end
end

%LPSOLVE instead of LP_SOLVE
if(strcmpi(opts.solver,'lpsolve'))
    opts.solver = 'lp_solve';
end

%Check for lmder variants
if(any(strcmpi(opts.solver,{'lm_der','lm_dif','lmdif'})))
    opts.solver = 'lmder';
end

%CBC for LPs
if(strcmpi(prb,'LP') && strcmpi(opts.solver,'cbc'))
    opts.solver = 'clp';
    if(warn > 1)
        optiwarn('opti:lp_cbc','CBC is for solving MILPs, using CLP instead.');
    end
end
if(strcmpi(prb,'QP') && strcmpi(opts.solver,'cbc'))
    opts.solver = 'clp';
    if(warn > 1)
        optiwarn('opti:qp_cbc','CBC is for solving MIQPs, using CLP instead.');
    end
end

%Check constraints on bounded solvers
if((siz.nineq + siz.neq + siz.nnleq + siz.nnlineq) > 0)
    if(strcmpi(opts.solver,'lbfgsb'))        
        if(warn > 1)
            optiwarn('opti:bounded','L-BFGS-B can only solve bounded problems - using IPOPT instead.')
        end
        opts.solver = 'ipopt';
    end
end
if((siz.nnleq + siz.nnlineq) > 0)
    if(strcmpi(opts.solver,'pswarm'))        
        if(warn > 1)
            optiwarn('opti:bounded','PSwarm can only solve linearly constrained problems - using IPOPT instead.')
        end
        opts.solver = 'ipopt';
    end
end
if(((siz.neq + siz.nnleq) > 0) && ((siz.nint + siz.nbin) > 0)) %MI with Equalities
    if(strcmpi(opts.solver,'gmatlab'))
        error('The MATLAB Global Optimization GA Algorithm with Integer Constraints cannot solve Equality Constrained Problems - Please use another solver.');
    end
end

%Check data fitting problems
if(~isempty(prob.ydata))
    if((siz.nineq + siz.neq) > 0)
        if(strcmpi(opts.solver,'matlab'))        
            if(warn > 1)
                optiwarn('opti:nls_lin','MATLAB''s LSQCURVEFIT can only solve bounded problems - using LEVMAR instead.')
            end
            opts.solver = 'levmar';
        end
    end
    if(siz.ncon > 0)
        if(strcmpi(opts.solver,'lmder'))
            if(warn > 1)
                optiwarn('opti:nls_con','MINPACK''s LM_DER can only solve unconstrained problems - using NL2SOL instead.')
            end
            opts.solver = 'nl2sol';
        end
    end
    if(size(prob.ydata,2) > size(prob.ydata,1))
        prob.ydata = prob.ydata';
    end
    if(~isempty(prob.xdata) && size(prob.xdata,2) > size(prob.xdata,1))
        prob.xdata = prob.xdata';
    end
end

%Bonmin for NLPs
if((strcmpi(prb,'UNO') || strcmpi(prb,'NLP')) && strcmpi(opts.solver,'bonmin'))
    opts.solver = 'ipopt';
    if(warn > 1)
        optiwarn('opti:nlp_bonmin','BONMIN is for solving MINLPs, using IPOPT instead.');
    end
end

%Unconstrained QP (-H\f)
if(strcmpi(prb,'QP') && ~prob.iscon)
    opts.solver = 'matlab';
    if(warn > 1)
        optiwarn('opti:uQP','You have supplied an Unconstrained QP. This will be solved using -H\\f.');
    end
end

%Check if the user wants to use IPOPT or BONMIN as (MI)QP/QCQP solver
if(~isempty(strfind(prob.type,'QP')) && (strcmpi(opts.solver,'ipopt') || strcmp(opts.solver,'bonmin')))
    if(warn > 1)
        optiwarn('opti:qcqp2nlp','Quadratic Program converted to NLP to suit IPOPT/BONMIN interface');
    end
    if(strcmpi(opts.solver,'ipopt') && nqc==0) %remember hessian only constant for LP/QP
        opts.solverOpts = ipoptset(opts.solverOpts,'hessian_constant','yes'); %,'mehrotra_algorithm','yes','mu_oracle','probing' %not sure this is always best, let user decide
    elseif(strcmpi(opts.solver,'bonmin') && nqc==0)
        opts.solverOpts = bonminset(opts.solverOpts,'hessian_constant','yes');
    end
    [prob,opts] = QCQP2NLP(prob,opts); 
    prb = prob.type;
end

%AUTO solver - replace with best for problem type
if(strcmpi(opts.solver,'auto'))
    try
        opts.solver = lower(checkSolver(['best_' prb]));
    catch ME
        %Convert QCQP problems to general nonlinear (for now)
        if(any(strcmpi(prb,{'QCQP','MIQP','MIQCQP'})))
            if(warn)
                optiwarn('opti:qcqp','OPTI cannot find a solver to solve a %s explicitly. It will converted to a (MI)NLP to be solved.',upper(prb));
            end
            %Do conversion then return (internally calls this function)
            [prob,opts] = QCQP2NLP(prob,opts);
            return;
        else
            rethrow(ME);
        end
    end
end

%Only certain solvers solve SOS problems
if(csos && ~any(strcmpi(opts.solver,{'CPLEX','LP_SOLVE','CBC','SCIP'})))
    oS = opts.solver;
    if(checkSolver('cplex',0)) %prefer cplex, but may not be available
        opts.solver = 'cplex';
    elseif(checkSolver('scip',0))
        opts.solver = 'scip';
    elseif(checkSolver('cbc',0))
        opts.solver = 'cbc';
    elseif(checkSolver('lp_solve',0))
        opts.solver = 'lp_solve';
    else
        error('You do not have a solver which can solve problems specified with SOS');
    end
    if(warn > 1)
        optiwarn('opti:consos','%s does not solve MILPs with Special Ordered Sets. Using %s instead.',upper(oS),upper(opts.solver));
    end
end
        
%Check constrained NLS
if(strcmpi(prb,'NLS') && ncon)
    if(~any(strcmpi(opts.solver,{'nl2sol','mkltrnls','levmar','matlab'})))
        oS = opts.solver;
        if((neq+nineq) > 0) %only levmar solves linearly constrained NLS
            checkSolver('levmar');
            opts.solver = 'levmar';
        else
            checkSolver('mkltrnls');
            opts.solver = 'mkltrnls';
        end
        if(warn > 1)
            optiwarn('opti:connls','%s does not solve constrained Nonlinear Least Squares Problems. Using %s instead.',upper(oS),upper(opts.solver));
        end
    end
end

%Check xdata supplied for fun(x,xdata) problems
if(strcmpi(prb,'NLS') && nargin(prob.fun) > 1 && isempty(prob.xdata))
    error('The supplied objective function requires more than 1 input, but xdata is empty! OPTI assumes fun(x,xdata) based on this configuration.');
end

%Binary constraints for OPTI, BONMIN, GMATLAB - use bounds
if(any(strcmpi(opts.solver,{'opti','bonmin','gmatlab'})) && any(prob.int.ind < 0))
    %lower bounds
    if(isempty(prob.lb))
        prob.lb = -Inf(siz.ndec,1);
        prob.lb(prob.int.ind < 0) = 0;
    else
        lb = prob.lb(prob.int.ind < 0);
        lb(lb < 1) = 0; %only change out of binary bounds ones (could be 1 <= x <= 1)
        prob.lb(prob.int.ind < 0) = lb;
    end
    %upper bounds
    if(isempty(prob.ub))
        prob.ub = Inf(siz.ndec,1);
        prob.ub(prob.int.ind < 0) = 1;
    else
        ub = prob.ub(prob.int.ind < 0);
        ub(ub > 0) = 1;
        prob.ub(prob.int.ind < 0) = ub;
    end
end
   
%Check sense, add minus if maximization [I assume this is ok for non-convex problems too?]
if(prob.sense < 0)
    switch(prb)
        case {'LP','MILP','BILP'}
            prob.f = -prob.f;
        case 'QP'
            prob.H = -prob.H;
            prob.f = -prob.f;
        case {'UNO','NLS','NLP','MINLP'}
            prob.fun = @(x) -prob.fun(x);
            if(~isempty(prob.f))
                prob.f = @(x) -prob.f(x);
            end
            if(~isempty(prob.H))
               switch(nargin(prob.H))
                   case 1
                       prob.H = @(x) -prob.H(x); %with no lambda assume no constraints, minus is ok
                   case 3
                       prob.H = @(x,sigma,lambda) prob.H(x,-sigma,lambda); %with sigma we can invert the sign
                   otherwise
                       error('OPTI cannot modify the Hessian Callback in order to maximise the problem. Please manually reformulate your problem as a maximization one.');
               end
            end
    end
end

%Check if the problem was read via AMPL
if(~isempty(ampl.path))
    %If we are solving via SCIP, skip MATLAB callbacks (whitebox solver)
    if(any(strcmp(opts.solver,{'scip'})))
        ampl.useASL = true;
        ampl.writesol = false; %done internally within scip
        %Close asl interface if still open
        if(asl('isopen')), asl('close'); end
    else
        ampl.useASL = false;
        ampl.writesol = true;
    end
else
    ampl.useASL = false;
    ampl.writesol = false;
end
%Assign ampl structure
prob.ampl = ampl;

%Check for non-convex QP/QCQP
if(~isempty(strfind(prb,'QP')))
    try
       e = eig(prob.H); 
    catch %#ok<CTCH>
       e = eigs(prob.H); 
    end
    %Check for non-convex QP
    if(any(e < 0))
        if(strcmpi(opts.solver,'cplex') && ~isfield(opts.solverOpts,'solutiontarget'))
           opts.solverOpts.solutiontarget.Cur = 2; %allow indefinite
        elseif(warn)
            optiwarn('opti:nonconvexQP','QP objective appears non-convex, you may not obtain a globally optimal solution');
        end      
    end
    %Check for non-convex QCs
    if(~QCisconvex)
        if(strcmpi(opts.solver,'cplex'))
           opts.solverOpts.solutiontarget.Cur = 3; %allow indefinite
        elseif(warn)
            optiwarn('opti:nonconvexQC','QCQP constraint(s) appear(s) non-convex, you may not obtain a globally optimal solution');
        end      
    end
end

%Remove unused fields
if(isfield(prob,'probtype')), prob = rmfield(prob,'probtype'); end


function c = checkInt(c,ndec)
%Check and assign the Integer Constraints

if(isempty(c.int))
    c.int = struct('str',char('C'*ones(1,ndec)),'ind',zeros(1,ndec),'idx',[]);
    return;
end

if(~ischar(c.int) && ~isnumeric(c.int))
    error('The integer variable string must be a char array or double vector!');
end

if(ischar(c.int) && (length(c.int) ~= ndec))
    error('Integer Variable String is not the correct length! Expected 1 x %d',ndec);
end
if(isnumeric(c.int) && (length(c.int) > ndec))
    error('Integer Variable Index Vector is not the correct length! Expected MAX 1 x %d',ndec);
end

str = ones(1,ndec);
ind = zeros(1,ndec);

if(ischar(c.int))
    idx = []; j = 1;
    for i = 1:ndec
        switch(lower(c.int(i)))
            case 'c'
                str(i) = 'C';
                ind(i) = 0;
            case 'b'
                str(i) = 'B';
                ind(i) = -1;
            case 'i'
                str(i) = 'I';
                ind(i) = 1;
                idx(j) = i; j = j + 1; %#ok<AGROW>
            otherwise
                error('Unknown character %s in Integer Variable String!',c.int(i));
        end
    end
else
    if(any(c.int == 0))
        error('Indicies of integer variables must be >= 1')
    end
    if(any(c.int > ndec))
        error('An integer index is > ndec!');
    end
    str = char('C' * str); str(c.int) = 'I';
    ind(c.int) = 1;
    idx = c.int;
end

c.int = struct('str',char(str),'ind',ind,'idx',idx);


function [cA,cb,cAeq,cbeq,cru,crl,clb,cub,cqc,cqrl,cqru,csdp,cint,cnl,ccl,ccu,csos] = conUsed(c)
%Determine what constraints are not empty

if(isempty(c.A)); cA = 0; else cA = 1; end
if(isempty(c.b)); cb = 0; else cb = 1; end
if(isempty(c.Aeq)); cAeq = 0; else cAeq = 1; end
if(isempty(c.beq)); cbeq = 0; else cbeq = 1; end
if(isempty(c.ru)); cru = 0; else cru = 1; end
if(isempty(c.rl)); crl = 0; else crl = 1; end
if(isempty(c.lb)); clb = 0; else clb = 1; end
if(isempty(c.ub)); cub = 0; else cub = 1; end
if(isempty(c.Q)); cqc = 0; else cqc = 1; end
if(isempty(c.qrl)); cqrl = 0; else cqrl = 1; end
if(isempty(c.qru)); cqru = 0; else cqru = 1; end
if(isempty(c.sdcone)); csdp = 0; else csdp = 1; end
if(any(c.int.str ~= 'C')); cint = 1; else cint = 0; end
if(isempty(c.nlcon)); cnl = 0; else cnl = 1; end
if(isempty(c.cl)); ccl = 0; else ccl = 1; end
if(isempty(c.cu)); ccu = 0; else ccu = 1; end
if(isempty(c.sos) || ~isfield(c.sos,'type') || isempty(c.sos.type)); csos = 0; else csos = 1; end


function checkLP(prob)
%Check if we are solving an unconstrained LP
if(isempty(prob.H) && isempty(prob.fun) && ~prob.iscon)
    error('When solving an LP the problem must be constrained!');
end


function [prob,opts] = buildSLE(prob,opts)
%Build Problem for System of Linear Equations

prob.type = 'SLE';

%Check we have A + b + correct sizes
if(isempty(prob.A) || isempty(prob.b))
    error('You must supply both A + b to solve a SLE');
end
if(size(prob.A,1) ~= length(prob.b))
    error('Equation RHS vector b is the wrong size! Expected %d x 1',size(prob.A,1));
end

%AUTO solver - replace with best for problem type
if(strcmpi(opts.solver,'auto'))
    opts.solver = lower(checkSolver(['best_' prob.type]));
end

%MLDIVIDE solver
if(strcmpi(opts.solver,'mldivide'))
    opts.solver = 'matlab';
end

%no constraints
prob.iscon = 0; 



function [prob,opts] = exPrbOpts(varargin)
%Extract the problem and options from the supplied arguments to opti

switch(nargin)
    case 0
        optiprob;
        error('You cannot create an empty OPTI object');
    case 1 %opti(prob) or opti(optiObj)
        if(isempty(varargin{1}))
            error('You cannot create an empty OPTI object');
        elseif(isstruct(varargin{1}))
            prob = optiprob(varargin{1});
            opts = optiset(); %default opts
        elseif(isa(varargin{1},'opti'))
            error('opti(optiObj) is not implemented');
        elseif(ischar(varargin{1}))
            error('Unknown constructor calling form with argument ''%s''',varargin{1});
        else
            error('Unknown calling form for OPTI!');
        end
    case 2 %opti(prob,opts) OR opti('field',value) OR opti(optiObj,opts)
        if(isstruct(varargin{1}) && isstruct(varargin{2}))
            prob = optiprob(varargin{1});
            opts = optiset(varargin{2});
        elseif(ischar(varargin{1}))
            prob = optiprob(varargin{:});
            opts = optiset();
        elseif(isa(varargin{1},'opti'))
            if(isstruct(varargin{2}) && isfield(varargin{2},'solver'))
                prob = getProb(varargin{1});
                opts = optiset(varargin{2});
            else
                error('opti(optiObj,arg) is not implemented unless arg is an options structure');
            end
        else
            error('Unknown calling form for OPTI!');
        end
        
    otherwise   
        if(isa(varargin{1},'opti'))
            oprob = getProb(varargin{1});
        else
            oprob = [];
        end
        
%         try
            if(~isempty(oprob))
                prob = optiprob(oprob,varargin{2:end});
            else
                prob = optiprob(varargin{:});
            end
%         catch ME
%             throw(ME);
%         end
        if(~isempty(prob.opts))
            opts = prob.opts;
        else
            opts = optiset(); %default
        end
end
if(isfield(prob,'opts'))
    prob = rmfield(prob,'opts'); %don't keep a copy
end


function var = chkdouble(var,name,warn)
%Check if a variable is a double, if not, correct
if(~isa(var,'double'))
    if(warn)
        optiwarn('opti:notDouble','Variable %s was not a double, correcting: [double(%s)]',name,name);
    end
    var = double(var);
end

function isconvex = chkQC(Q,l,rl,ru,i,ndec,solver)
%Check a quadratic constraint for solver suitability
isconvex = true;
if((ndec ~= size(Q,1)) || (ndec ~= size(Q,2)))
    error('Constraint Q matrix in cell %d is the wrong size! Expected %d x %d',i,ndec,ndec);
end
if(ndec ~= size(l,1))
   error('Constraint l vector in column %d is the wrong size! Expected %d x 1',i,ndec);
end
if(~isscalar(rl))
   error('Constraint qrl in column %d is the wrong size! Expected 1 x 1 ',i);
end
if(~isscalar(ru))
   error('Constraint qru in column %d is the wrong size! Expected 1 x 1 ',i);
end
if(~any(strcmpi(solver,{'scip','ipopt','bonmin'}))) %allow scip or NLP solver to solve any QC constraint form
    %Check for equality
    if(rl == ru)
        error('Quadratic Constraint %d is an equality constraint. Please specify a global solver such as SCIP to solve this problem.\nAlternatively you may try IPOPT/BONMIN for a local solution.',i);
    end
    if(isinf(rl))
        chkQCConvex(Q,i,'upper bound constraint',solver);
    elseif(isinf(ru))
        chkQCConvex(-Q,i,'lower bound constraint',solver);
    elseif(~isinf(rl) && ~isinf(ru)) %bit of waste really...
        chkQCConvex(Q,i,'upper bound constraint',solver);
        chkQCConvex(-Q,i,'lower bound constraint',solver);
    else
        error('Quadratic Constraint %d has infinite lower and upper bounds!');
    end
end

function chkQCConvex(Q,i,str,solver)
try
   e = eig(Q); 
catch %#ok<CTCH>
   e = eigs(Q); 
end
if(any(e < 0)) %assuming symmetric...
    if(strcmpi(solver,'cplex'))
        error('Quadratic Constraint Q matrix in cell %d (%s) is not positive semi-definite! CPLEX only solves problems with non-convex objective terms. Please use a global solver such as SCIP to solve this problem.',i,str); 
    else
        error('Quadratic Constraint Q matrix in cell %d (%s) is not positive semi-definite! Please specify a global solver such as SCIP to solve this problem.',i,str);       
    end
end 

function sdout = chkSDCone(sdcone,i,ndec, warn)
%Check size, convert to sparse([C(:) A0(:) A1(:) ... ])
[m, n] = size(sdcone);
%If n = ndec+1, already in column format (or only 1x1 matrices, same diff)
if((n-1) == ndec)    
    %Check we can make a square matrix from number of rows (assume full symmetric)
    if(floor(sqrt(m)) ~= sqrt(m))
        error('Constraint Semidefinite Cone %d (assumed in column format [C(:) A0(:) ...] or [F0(:) F1(:) ...]) does not contain the correct number of rows to form a square matrix',i);
    end
    %All ok
    sdout = sparse(sdcone);
else
    %Check for full matrices [C A0 A1 ...]
    if(m*(ndec+1) ~= n)
        error('Constraint Semidefinite Cone %d (assumed in full matrix format [C A0 ...] or [F0 F1 ..]) does not contain the correct number of columns',i);
    end
    %Convert to sparse column format
    Aind = m;
    sdout = zeros(m^2,ndec+1);
    C = sdcone(:,1:m);
    sdout(:,1) = C(:);
    for i = 1:ndec
        A = sdcone(:,Aind+1:Aind+m);
        sdout(:,i+1) = A(:);
        Aind = Aind + m;
    end
    sdout = sparse(sdout);  
end
%Check symmetry
m = size(sdout,1);
for j = 1:ndec+1
    C = reshape(sdout(:,j),sqrt(m),sqrt(m));    
    if(abs(sum(sum(triu(C) - tril(C)'))) > 1e-6)
        %Force Symmetric (bad really)
        C = (C+C')./2;
        sdout(:,j) = C(:); %#ok<SPRIX>
        %Present Warning
        if(warn)
            if(j==1)
                optiwarn('opti:symm','Constraint Semidefinite Cone %d [matrix C (F0)] is not symmetric! Forcing to Symmetric using (C+C'')/2 but this may not be Intended.',i);
            else            
                optiwarn('opti:symm','Constraint Semidefinite Cone %d [matrix A%d (F%d)] is not symmetric! Forcing to Symmetric using (A+A'')/2 but this may not be Intended.',i,j-1,j-1);
            end
        end
    end    
end

