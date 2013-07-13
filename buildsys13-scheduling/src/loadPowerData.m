function [ rawPower ] = loadPowerData( fileName )
%LOADPOWERDATA: Read original mixed-data-typed csv file into a file only
%with grid power of entire house

    rawPower = csvread(fileName, 0, 1);
    index = (rawPower(:, 1) == 1);
    rawPower = rawPower(index, :);
    rawPower = rawPower(:, 3);
 
end

