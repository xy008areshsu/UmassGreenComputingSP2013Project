function [ power ] = powerPreProcess( filename )
%POWERPROCESS Summary of this function goes here
%   Detailed explanation goes here

rawPower = csvread(filename, 0, 1);
index = (rawPower(:, 1) == 1);
rawPower = rawPower(index, :);
rawPower = [rawPower(:, 2), rawPower(:, 3)];

rawPower = int64(rawPower);
first = rawPower(1,1);
rawPower(:, 1) = (rawPower(:, 1) - first) + 1;
index = rawPower(:, 1);

power = zeros(86400, 1);

for i = 1 : size(rawPower)
    power(rawPower(i, 1), 2) = rawPower(i , 2);
end

power = power(:, 2);
indexOfZero = (power == 0);
indexOfZero = find(indexOfZero);

for i = 1 : (size(power) - size(rawPower)) / 100
    power(indexOfZero) = power(indexOfZero - 1);
end

end

