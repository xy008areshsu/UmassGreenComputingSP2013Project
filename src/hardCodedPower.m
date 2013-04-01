function [ powerPerHour ] = hardCodedPower( fileName, numOfTimeInterval )
%HARDCODEDPOWER Summary of this function goes here
% This value is ABSURD, check with professor!!!!!!!!!!!!!!!!!!!
% This value is ABSURD, check with professor!!!!!!!!!!!!!!!!!!!
% This value is ABSURD, check with professor!!!!!!!!!!!!!!!!!!!
% This value is ABSURD, check with professor!!!!!!!!!!!!!!!!!!!
% This value is ABSURD, check with professor!!!!!!!!!!!!!!!!!!!
% This value is ABSURD, check with professor!!!!!!!!!!!!!!!!!!!
    power = load(fileName);
    powerPerHour = zeros(numOfTimeInterval,1);
    for i = 1 : numOfTimeInterval - 1
        powerPerHour(i) = sum(power((3600 * (i - 1) + 1 : 3600 * i), 2));
    end
    powerPerHour(numOfTimeInterval) = sum(power((3600 * 23 + 1: end), 2));
    powerPerHour = powerPerHour ./ 1000;    % convert to kw
end

