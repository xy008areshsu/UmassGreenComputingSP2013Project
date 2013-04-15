function options = csdpset(varargin)
%CSDPSET  Create or alter the options for Optimization with CSDP
%
% options = csdpset('param1',value1,'param2',value2,...) creates an CSDP
% options structure with the parameters 'param' set to their corresponding
% values in 'value'. Parameters not specified will be set to the CSDP
% default.
%
% options = csdpset(oldopts,'param1',value1,...) creates a copy of the old
% options 'oldopts' and then fills in (or writes over) the parameters
% specified by 'param' and 'value'.
%
% options = csdpset() creates an options structure with all fields set to
% csdpset defaults.
%
% csdpset() prints a list of all possible fields and their function.
%
% See supplied CSDP Documentation for further details of these options.

%   Copyright (C) 2013 Jonathan Currie (I2C2)

% Print out possible values of properties.
numberargs = nargin;
if (nargin == 0) && (nargout == 0)
    printfields();
    return
end
%Names and Defaults
Names = {'axtol';'atytol';'objtol';'pinftol';'dinftol';'minstepfrac';'maxstepfrac';'minstepp';'minstepd';'usexzgap';'tweakgap';'affine';'perturbobj';'fastmode';'objconstant';'writeprob';'writesol'};
Defaults = {1e-8,1e-8,1e-8,1e8,1e8,0.9,0.97,1e-8,1e-8,1,0,0,1,0,0,[],[]}';        

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
    case {'axtol';'atytol';'objtol';'pinftol';'dinftol';'minstepfrac';'maxstepfrac';'minstepp';'minstepd';'usexzgap';'tweakgap';'affine';'perturbobj';'fastmode';'objconstant'}
        if(isscalar(value) && isnumeric(value))
            valid = true;
        else
            valid = false; errmsg = sprintf('Parameter %s should be a scalar double',field);
        end
        
    %String
    case {'writeprob','writesol'}
        if(ischar(value))
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
    ME = MException('csdpset:FieldError',errmsg);
    throwAsCaller(ME);
end


function printfields()
%Print out fields with defaults
fprintf('         axtol: [ Primal Feasibility Tolerance: {1e-8} ] \n');
fprintf('        atytol: [ Dual Feasibility Tolerance: {1e-8} ] \n');
fprintf('        objtol: [ Relative Duality Gap Tolerance: {1e-8} ] \n');
fprintf('       pinftol: [ Primal Infeasibility Tolerance: {1e8} \n');
fprintf('       dinftol: [ Dual Infeasibility Tolerance: {1e8} ] \n');
fprintf('   minstepfrac: [ Minimum step fraction to edge of feasible region: {0.9} ] \n');
fprintf('   maxstepfrac: [ Maximum step fraction to edge of feasible region: {0.97} ] \n');
fprintf('      minstepp: [ Primal line search minimum step size before failure: {1e-8} ] \n');
fprintf('      minstepd: [ Dual line search minimum step size before failure: {1e-8} ] \n');
fprintf('      usexzgap: [ Use objective function duality gap instead of tr(XZ) gap: {1}, 0 ] \n');
fprintf('      tweakgap: [ Attempt to fix negative duality gaps if usexzgap = 0: {0}, 1 ] \n');
fprintf('        affine: [ Only take primal-dual affine steps (do not use barrier term): {0}, 1 ] \n');
fprintf('    perturbobj: [ Level of objective function perturbation (useful in unbounded problems): {1.0} ] \n');
fprintf('      fastmode: [ Sacrifice accuracy for faster execution: {0}, 1 ] \n');
fprintf('   objconstant: [ Constant value to add to the objective: {0.0} ] \n');
fprintf('     writeprob: [ Filename (including path) to write the entered problem to in SDPA sparse format: {[]} ] \n');
fprintf('      writesol: [ Filename (including path) to write the solution to in SDPA sparse format: {[]} ] \n');
fprintf('\n');
