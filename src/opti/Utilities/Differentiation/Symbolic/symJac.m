function [jac,symjac] = symJac(fun,ncol,tran)
%SYMJAC  Returns a Symbolically Differentiated Jacobian
%
%   jac = symJac(fun) uses the symbolic toolbox to automatically generate
%   the Jacobian of the function handle fun. You should supply the function
%   handle in the form @(x) x(1)^2 + x(2), noting x must be the only
%   variable used, and is indexed in the equation (no vector operations).
%
%   jac = symJac(fun,ncol) specifies the number of variables in the
%   equation, assuming consecutive ordering. Useful if a variable is not
%   specified in the original equation to pad the Jacobian with zeros.
%
%   jac = symJac(fun,ncol,tran) specifies to transpose (.') the generated
%   Jacobian prior to returning the function handle.

%   Copyright (C) 2011 Jonathan Currie (I2C2)

if(~isa(fun,'function_handle'))
    error('Fun should be a function handle!');
end
if(nargin(fun) > 1)
    error('Fun should only have one input argument (x)');
end
if(~checkSym())
    jac = []; symjac = [];
    return
end

if(~exist('ncol','var') || isempty(ncol))
    ncol = 0;
end
if(~exist('tran','var') || isempty(tran))
    tran = 0;
end

%Convert to a symbolic equation
[symfun,ind] = func2sym(fun);
ind = unique(ind);
%Check we have enough vars
if(ncol && (length(ind) ~= ncol))
    %Manually Generate Jacobian
    j = '';
    for i = 1:ncol
        j = [j diff(symfun,eval(['sym(''x' num2str(i) ''')']))]; %#ok<AGROW>
    end    
else
    %Calculate jacobian
    j = jacobian(symfun);
end
if(tran)
    j = j.';
end
symjac = j;
%Return to a function handle
jac = sym2func(j);


function havSym = checkSym()
c = ver('symbolic');
if(isempty(c))
    optiwarn('opti:sym','getSymJac requires the MATLAB Symbolic Toolbox');
    havSym = 0;
else
    havSym = 1;
end