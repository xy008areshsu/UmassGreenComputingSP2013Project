function [f,ind] = func2sym(fun)
%FUNC2SYM  Convert a function handle to symbolic variable equation
%
%   f = func2sym(fun) converts the function handle into a string, then
%   replaces any x(1) to x1, x(2) to x2, etc, and returns it as a symbolic
%   equation.
%
%   [f,ind] = func2sym(fun) returns the indices of the symbolic variable x
%   used in the equation.

%   Copyright (C) 2011 Jonathan Currie (I2C2)

str = func2str(fun);
k = strfind(str,'x(');
len = length(k);
ind = zeros(len,1);

%Determine X Indicies in order
for i = 1:len
    ind(i) = readX(str,k(i));
end

%Start building symbolic string
start = findBrac(str,1); %get first bracket @(x)
f = '';
for i = 1:len
    f = [f str(start+1:k(i)) num2str(ind(i))]; %#ok<AGROW>
    start = findBrac(str,k(i));
end
f = sym([f str(start+1:end)]);


function ind = readX(str,k)
start = k+2; %skip x(
stop = findBrac(str,start)-1;
ind = str2double(str(start:stop));

function ind = findBrac(str,k)
for i = 0:length(str)
    if(str(k+i) == ')')
        ind = k+i;
        break
    end
end