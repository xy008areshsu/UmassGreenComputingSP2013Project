function [ powerPerInterval ] = hardCodedPower( fileName, numOfTimeInterval )
%HARDCODEDPOWER Hard Coded power prediction per time interval in kWh

    power = loadPowerData(fileName);
    powerPerInterval = zeros(numOfTimeInterval,1);
    stepSize = size(power) / numOfTimeInterval;
    stepSize = int64(stepSize(1));
    for i = 1 : numOfTimeInterval - 1
        powerPerInterval(i) = sum(power(stepSize * (i - 1) + 1 : stepSize * i)) / stepSize;
    end
    powerPerInterval(numOfTimeInterval) = sum(power((stepSize * 23 + 1: end))) / stepSize;
    powerPerInterval = powerPerInterval ./ 1000;    % convert to kw
end

