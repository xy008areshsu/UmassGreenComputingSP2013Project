function options = optiset(varargin)
%OPTISET  Create or alter the options for Optimization with OPTI
%
% options = optiset('param1',value1,'param2',value2,...) creates an OPTI
% options structure with the parameters 'param' set to their corresponding
% values in 'value'. Parameters not specified will be set to the OPTI
% default.
%
% options = optiset(oldopts,'param1',value1,...) creates a copy of the old
% options 'oldopts' and then fills in (or writes over) the parameters
% specified by 'param' and 'value'.
%
% options = optiset() creates an options structure with all fields set to
% OPTI defaults.
%
% optiset() prints a list of all possible fields and their function.

%   Copyright (C) 2011 Jonathan Currie (I2C2)

% Print out possible values of properties.
if (nargin == 0) && (nargout == 0)
    printfields();
    return
end

%Names and Defaults
Names = {'solver';'maxiter';'maxfeval';'maxnodes';'maxtime';'tolrfun';'tolafun';'tolint';'solverOpts';'iterfun';'warnings';'display'};
Defaults = {'auto';1500;1e4;1e4;1000;1e-7;1e-7;1e-5;[];[];'critical';'off'};         

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
                val = checkfield(Names{j,:},val);
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
            j = find(strcmpi(arg,Names) == 1);
            if isempty(j)  % if no matches
                error('Unrecognised parameter %s',arg);
            elseif(length(j) > 1)
                error('Ambiguous parameter %s',arg);
            end
            expectval = 1; %next arg is a value
        case 1
            if(~isempty(arg))
                arg = checkfield(Names{j,:},lower(arg));
                options.(Names{j,:}) = lower(arg);
            end
            expectval = 0;
    end
    i = i + 1;
end

if expectval %fallen off end somehow
    error('Missing value for %s',arg);
end



function rval = checkfield(field,value)
%Check a field contains correct data type

if isempty(value)
    return % empty matrix is always valid
end

switch lower(field)
    case 'solver' % string
        if(ischar(value))
            valid = checkSolver(value,1); %will throw an error if doesn't exist
        else
            valid = false; errmsg = sprintf('Parameter %s should be a char array',field);
        end
    case 'solveropts' %struct
        if(isstruct(value))
            valid = true;
        else
            valid = false; errmsg = sprintf('Parameter %s should be a structure',field);
        end  
    case 'warnings' %string
        if(ischar(value) && any(strcmp(value,{'on','critical','off','all','none'})))
            valid = true;
            if(strcmpi(value,'on'))
                value = 'all';
            elseif(strcmpi(value,'off'))
                value = 'none';
            end
        else
            valid = false; errmsg = sprintf('Parameter %s should be a char array with string ''on'', ''critical'', or ''off''',field);
        end
    case {'maxiter','maxfeval','maxtime','maxnodes'} %double scalar
        if(isscalar(value) && isnumeric(value))
            valid = true;
        else
            valid = false; errmsg = sprintf('Parameter %s should be a double scalar',field);
        end     
        
    case {'tolafun','tolrfun','tolint'} %double scalar
        if(isscalar(value) && isnumeric(value) && (value > eps) && (value < 1))
            valid = true;
        else
            valid = false; errmsg = sprintf('Parameter %s should be a double scalar eps < tol < 1',field);
        end 
        
    case 'display' %string
        switch(lower(value))
            case {'off','iter','final'}
                valid = true;
            otherwise
                valid = false;
                errmsg = sprintf('Parameter %s should be ''off'', ''iter'' or ''final'' ',field);
        end
   case 'iterfun'
        if(isa(value,'function_handle'))
            valid = true;
        else
            valid = false; errmsg = sprintf('Parameter %s should be a function handle',field);
        end  
        
    otherwise  
        valid = false;
        errmsg = sprintf('Unrecognized parameter name ''%s''.', field);
end
rval = value;
if valid 
    return;
else %error
    ME = MException('optiset:FieldError',errmsg);
    throwAsCaller(ME);
end


function printfields()
%Print out fields with defaults

solvers = [{'AUTO'} checkSolver('all')];
len = length(solvers);
str = '';
for i = 1:len
    if(i < len)
        str = [str solvers{i} ', ']; %#ok<AGROW>
    else
        str = [str solvers{i}]; %#ok<AGROW>
    end
end   
str = regexprep(str,'AUTO','{AUTO}');

fprintf('\n OPTISET Fields:\n');
fprintf(['            solver: [ ' str ' ] \n']);
fprintf('           maxiter: [ Maximum Solver Iterations {1.5e3} ] \n');
fprintf('          maxfeval: [ Maximum Function Evaluations {1e4} ] \n');
fprintf('          maxnodes: [ Maximum Integer Solver Nodes {1e4} ] \n');
fprintf('           maxtime: [ Maximum Solver Evaluation Time {1e3s} ] \n');
fprintf('           tolrfun: [ Relative Function Tolerance {1e-7} ] \n');
fprintf('           tolafun: [ Absolute Function Tolerance {1e-7} ] \n');
fprintf('            tolint: [ Absolute Integer Tolerance {1e-5} ] \n');
fprintf('        solverOpts: [ Solver Specific Options Structure ] \n');
fprintf('           iterfun: [ Iteration Callback Function, stop = iterfun(iter,fval,x) {} ] \n');
fprintf('          warnings: [ ''all'' or {''critical''} or ''none'' ] \n');
fprintf('           display: [ {''off''}, ''iter'', ''final'' ] \n');

