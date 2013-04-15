function f = sym2func(fun)
%SYM2FUNC  Convert a symbolic variable equation to function handle
%
%   f = sym2func(fun) converts the symbolic equation into a string, then
%   replaces any x1 to x(1), x2 to x(2), etc, and returns it as a function
%   handle suitable for standard evaluation.

%   Copyright (C) 2011 Jonathan Currie (I2C2)

str = char(fun);
%Remove 'matrix' if is found
k = strfind(str,'matrix');
if(k)
    str = str(k+7:end-1);
end
%Ensure we have right size
[r,c] = size(fun);
if(c==1 && r > 1)
    str = regexprep(str,',',';'); %force column
elseif(c>1 && r>1)
    str = regexprep(str,'],','];'); %keep matrix
end
k = strfind(str,'x');
len = length(k);
ind = zeros(len,1);

%Determine X Indicies in order
for i = 1:len
    ind(i) = readX(str,k(i));
end

%Remove duplicates
ind = unique(ind);
ind = sort(ind,'descend'); %go from largest to smallest to avoid x10, x1 problems
len = length(ind);

%Find and replace
for i = 1:len
    str = regexprep(str,['x' num2str(ind(i))],['x(' num2str(ind(i)) ')']);
end

%Build function handle
f = eval(['@(x) ' str]);


function ind = readX(str,k)
start = k+1; %skip x
if(start > length(str)), ind = 1; return; end;
stop = findEnd(str,start)-1;
ind = str2double(str(start:stop));

function ind = findEnd(str,k)
for i = 0:length(str)
    val = double(str(k+i));
    if(val < 48 || val > 57)
        ind = k+i;
        break
    end
end