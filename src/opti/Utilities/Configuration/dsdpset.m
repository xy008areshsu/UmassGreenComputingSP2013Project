function options = dsdpset(varargin)
%DSDPSET  Create or alter the options for Optimization with DSDP
%
% options = dsdpset('param1',value1,'param2',value2,...) creates an DSDP
% options structure with the parameters 'param' set to their corresponding
% values in 'value'. Parameters not specified will be set to the DSDP
% default.
%
% options = dsdpset(oldopts,'param1',value1,...) creates a copy of the old
% options 'oldopts' and then fills in (or writes over) the parameters
% specified by 'param' and 'value'.
%
% options = dsdpset() creates an options structure with all fields set to
% dsdpset defaults.
%
% dsdpset() prints a list of all possible fields and their function.
%
% See supplied DSDP Documentation for further details of these options.

%   Copyright (C) 2013 Jonathan Currie (I2C2)

% Print out possible values of properties.
numberargs = nargin;
if (nargin == 0) && (nargout == 0)
    printfields();
    return
end
%Names and Defaults
Names = {'drho';'rpos';'r0';'penalty';'rho';'dbound';'gaptol';'rtol';'mu0';'maxtrust';'steptol';'ptol';'pnormtol';'reuse';'zbar';'dlbound';'ybound';'fixed'};
Defaults = {1;0;-1;1e8;5;1e20;1e-7;1e-6;-1;1e10;0.05;1e-4;1e30;4;[];[];[];[]};        

%Collect Sizes and lowercase matches         
m = size(Names,1); 
%Create structure with all names and default values
st = [Names,Defaults]'; options = struct(st{:});

% Check we have char or structure input. If structure, insert arguments
i = 1;
while i <= numberargs
    arg = varargin{i};
    if ischar(arg)
        break;
    end
    if ~isempty(arg)
        if ~isa(arg,'struct')
            error('An argument was supplied that wasn''t a string or struct!');
        end
        for j = 1:m
            if any(strcmp(fieldnames(arg),Names{j,:}))
                val = arg.(Names{j,:});
            else
                val = [];
            end
            if ~isempty(val)
                checkfield(Names{j,:},val);
                options.(Names{j,:}) = val;
            end
        end
    end
    i = i + 1;
end

%Check we have even number of args left
if rem(numberargs-i+1,2) ~= 0
    error('You do not have a value specified for each field!');
end

%Go through each argument pair and assign to correct field
expectval = 0; %first arg is a name
while i <= numberargs
    arg = varargin{i};

    switch(expectval)
        case 0 %field
            if ~ischar(arg)
                error('Expected field name to be a string! - Argument %d',i);
            end
            j = find(strcmp(arg,Names) == 1);
            if isempty(j)  % if no matches
                error('Unrecognised parameter %s',arg);
            elseif(length(j) > 1)
                error('Ambiguous parameter %s',arg);
            end
            expectval = 1; %next arg is a value
        case 1
            checkfield(Names{j,:},lower(arg));
            options.(Names{j,:}) = lower(arg);
            expectval = 0;
    end
    i = i + 1;
end

if expectval %fallen off end somehow
    error('Missing value for %s',arg);
end



function checkfield(field,value)
%Check a field contains correct data type

if isempty(value)
    return % empty matrix is always valid
end

switch lower(field)
    %Scalar numeric
    case {'drho','rpos','r0','penalty','rho','dbound','gaptol','rtol','mu0','maxtrust','steptol','ptol','pnormtol','reuse','zbar','dlbound','ybound'}
        if(isscalar(value) && isnumeric(value))
            valid = true;
        else
            valid = false; errmsg = sprintf('Parameter %s should be a scalar double',field);
        end
        
    otherwise  
        valid = false;
        errmsg = sprintf('Unrecognized parameter name ''%s''.', field);
end

if valid 
    return;
else %error
    ME = MException('dsdpset:FieldError',errmsg);
    throwAsCaller(ME);
end


function printfields()
%Print out fields with defaults
fprintf('          rpos: [ Use Penalty Parameter to enforce Feasibility {0}, 1 ] \n');
fprintf('          drho: [ Use Dynamic Strategy to choose Rho: {1}, 0 ] \n');
fprintf('            r0: [ Set initial value for variable r in Dual {-1} ] \n');
fprintf('       penalty: [ Penalty Parameter Gamma {1e8} \n');
fprintf('           rho: [ Potential Parmater: {5} ] \n');
fprintf('           mu0: [ Barrier Parameter: {-1} ] \n');
fprintf('          rtol: [ Classify Dual as feasible if r is less than this tolerance: {1e-6} ] \n');
fprintf('          ptol: [ Classify Primal as feasible if infeasibility is less than this tolerance: {1e-4} ] \n');
fprintf('      maxtrust: [ Maximum Trust Radius on Step Direction: {1e10} ] \n');
fprintf('        gaptol: [ Convergence Gap Tolerance: {1e-7} ] \n');
fprintf('       steptol: [ Terminate solver if step length in Dual is below this tolerance: {0.05} ] \n');
fprintf('        dbound: [ Terminate solver if Dual Objective greater than this Value {1e20} ] \n');
fprintf('      pnormtol: [ Terminate the solver when duality gap is sufficiently small and pnorm is less than this quantity: {1e30} ] \n');
fprintf('         reuse: [ Number of times the Hessian of the Barrier Function will be reused {4} ] \n');
fprintf('          zbar: [ Upper bound on objective value at the solution {[]} ] \n');
fprintf('       dlbound: [ Lower bound on dual value {[]} ] \n');
fprintf('        ybound: [ Bound on the dual variables y {[]} ] \n');
fprintf('         fixed: [ Matrix of fixed variables, column 1 variable indices, column 2, fixed values {[]} ] \n');
fprintf('\n');
