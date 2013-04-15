function options = ipoptset(varargin)
%IPOPTSET  Create or alter the options for Optimization with IPOPT
%
% options = ipoptset('param1',value1,'param2',value2,...) creates an IPOPT
% options structure with the parameters 'param' set to their corresponding
% values in 'value'. Parameters not specified will be set to the IPOPT
% default.
%
% options = ipoptset(oldopts,'param1',value1,...) creates a copy of the old
% options 'oldopts' and then fills in (or writes over) the parameters
% specified by 'param' and 'value'.
%
% options = ipoptset() creates an options structure with all fields set to
% IPOPTSET defaults.
%
% ipoptset() prints a list of all possible fields and their function.
%
% See supplied IPOPT Documentation for further details of these options.

%   Copyright (C) 2011 Jonathan Currie (I2C2)

% Print out possible values of properties.
mode = 'ipopt';
numberargs = nargin;
if (nargin == 0) && (nargout == 0)
    printfields();
    return
elseif(nargin == 1) && (strcmp(varargin{1},'bonmin'))    
    if(nargout == 0)
        printfields('bonmin');
        return;        
    else
        mode = 'bonmin';
        numberargs = 0;
    end
end
%Names and Defaults
Names = {'nlp_scaling_method';'jac_c_constant';'jac_d_constant';...
         'hessian_constant';'mehrotra_algorithm';'mu_strategy';'mu_oracle';'mu_target';'max_soc';'hessian_approximation';...
         'limited_memory_max_history';'derivative_test';'linear_solver'};
Defaults = {'gradient-based';'no';'no';'no';'no';'adaptive';'quality-function';0;4;'exact';6;'none';'ma57'};        

%Collect Sizes and lowercase matches         
m = size(Names,1); 
%Create structure with all names and default values
st = [Names,Defaults]'; options = struct(st{:});
%Modify defaults if setting up for BONMIN
if(strcmp(mode,'bonmin'))
    options.mu_oracle = 'probing';
end

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
    case {'print_level','tol','max_iter','max_cpu_time','mu_target','max_soc','limited_memory_max_history'}
        if(isscalar(value) && isnumeric(value))
            valid = true;
        else
            valid = false; errmsg = sprintf('Parameter %s should be a scalar double',field);
        end
    %yes / no char
    case {'jac_c_constant','jac_d_constant','hessian_constant','mehrotra_algorithm'}
        if(ischar(value) && (strcmp(value,'yes') || strcmp(value,'no')))
            valid = true;
        else
            valid = false; errmsg = sprintf('Parameter %s should be ''yes'' or ''no''',field);
        end
    %char array
    case {'mu_strategy','mu_oracle','hessian_approximation','derivative_test','nlp_scaling_method'}
        if(ischar(value))
            valid = true; 
        else
            valid = false; errmsg = sprintf('Parameter %s should be a char array',field);
        end   
    %linear solver
    case 'linear_solver'
        if(ischar(value) && any(strcmpi(value,{'ma57','mumps'})))
            valid = true;
        else
            valid = false; errmsg = 'Linear_Solver must be selected as either MA57 or MUMPS';
        end
        
    otherwise  
        valid = false;
        errmsg = sprintf('Unrecognized parameter name ''%s''.', field);
end

if valid 
    return;
else %error
    ME = MException('nloptset:FieldError',errmsg);
    throwAsCaller(ME);
end


function printfields(mode)
%Print out fields with defaults
if(~nargin)
    mode = 'ipopt';
end
if(strcmpi(mode,'bonmin')), sp = '     '; else sp = ''; end
fprintf('%s         nlp_scaling_method: [ Scaling Technique: {''gradient-based''}, ''none''  ] \n',sp);
fprintf('%s             jac_c_constant: [ Indicates Linear Equality Constraints: {''no''}, ''yes''] \n',sp);
fprintf('%s             jac_d_constant: [ Indicates Linear Inequality Constraints: {''no''}, ''yes'' ] \n',sp);
fprintf('%s           hessian_constant: [ Indicates Quadratic Problem: {''no''}, ''yes'' ] \n',sp);
fprintf('%s         mehrotra_algorithm: [ Use Mehrotra''s Algorithm (LP or QP): {''no''}, ''yes'' ] \n',sp);
fprintf('%s                mu_strategy: [ Update Strategy for Barrier Parameter: {''adaptive''}, ''monotone'' ] \n',sp);
if(strcmpi(mode,'bonmin'))
    fprintf('%s                  mu_oracle: [ Oracle for New Parameter in Adaptive Strategy: ''quality-function'', {''probing''}, ''loqo'' ] \n',sp);
else
    fprintf('%s                  mu_oracle: [ Oracle for New Parameter in Adaptive Strategy: {''quality-function''}, ''probing'', ''loqo'' ] \n',sp);
end
fprintf('%s                  mu_target: [ Desired Value of Complementarity {0} ] \n',sp);
fprintf('%s                    max_soc: [ Maximum Number of Second Order Correction Steps: {4} ] \n',sp);
fprintf('%s      hessian_approximation: [ Indicates Hessian Information to Use: {''exact''}, ''limited-memory'' ] \n',sp);
fprintf('%s limited_memory_max_history: [ Maximum History for LBFGS Updates {6} ] \n',sp);
fprintf('%s            derivative_test: [ Enable Derivative Checker: {''none''}, ''first-order'', ''second-order'', ''only-second-order'' ] \n',sp);
fprintf('%s              linear_solver: [ Internal Linear System Solver {''MA57''}, ''MUMPS'' ] \n',sp);
fprintf('\n');
