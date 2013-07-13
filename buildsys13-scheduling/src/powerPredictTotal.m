function [ power ] = powerPredictTotal( ~ )
%POWERPREDICTTOTAL Summary of this function goes here
%   Detailed explanation goes here

list = dir('data');
list = list(3 : end);

s = size(list);
s = s(1);
filenames = cell(s,1);
power = zeros(s, 86400);
for i = 1 : s
    filenames(i) = {strcat('./data/', list(i).name)};
end
filenames = char(filenames);

for i = 1 : s
    power(i, :) = powerPreProcess(strtrim(filenames(i, :)))';
end

power = power';

end

