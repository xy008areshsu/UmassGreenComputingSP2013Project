function options = nloptset(varargin)
%NLOPTSET  Create or alter the options for Optimization with NLOPT
%
% options = nloptset('param1',value1,'param2',value2,...) creates an NLOPT
% options structure with the parameters 'param' set to their corresponding
% values in 'value'. Parameters not specified will be set to the NLOPT
% default.
%
% options = nloptset(oldopts,'param1',value1,...) creates a copy of the old
% options 'oldopts' and then fills in (or writes over) the parameters
% specified by 'param' and 'value'.
%
% options = nloptset() creates an options structure with all fields set to
% NLOPTSET defaults.
%
% nloptset() prints a list of all possible fields and their function.

%   Copyright (C) 2011 Jonathan Currie (I2C2)

% Print out possible values of properties.
if (nargin == 0) && (nargout == 0)
    printfields();
    return
end

%Names and Defaults
Names = {'algorithm';'subalgorithm';'subtolrfun';'subtolafun';'submaxfeval';'submaxtime'};
Defaults = {'LN_AUGLAG';'LN_PRAXIS';1e-6;1e-6;1.5e3;1e3};         

%Collect Sizes and lowercase matches         
m = size(Names,1); numberargs = nargin;
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
    case {'algorithm','subalgorithm'} % string
        if(ischar(value))
            nloptSolver(value);
            valid = true; 
        else
            valid = false; errmsg = sprintf('Parameter %s should be a char array',field);
        end     
    case {'subtolrfun','subtolafun','submaxfeval','submaxtime'}
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
    ME = MException('nloptset:FieldError',errmsg);
    throwAsCaller(ME);
end


function printfields()
%Print out fields with defaults

fprintf('         algorithm: [ NLOPT Algorithm String ] \n');
fprintf('      subalgorithm: [ Suboptimizer NLOPT Algorithm String ] \n');
fprintf('        subtolrfun: [ Suboptimizer Relative Function Tolerance {1e-6} ] \n');
fprintf('        subtolafun: [ Suboptimizer Absolute Function Tolerance {1e-6} ] \n');
fprintf('       submaxfeval: [ Suboptimizer Maximum Function Evaluations {1.5e3} ] \n');
fprintf('        submaxtime: [ Suboptimizer Maximum Evaluation Time {1e3s} ] \n');

