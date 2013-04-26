function [ newNonDeferLoad ] = mergeNonPreemtibleToNonDefer( nonDeferLoad, powerPerInterval, startTime, execTime )
%MERGENONPREEMTIBLETONONDEFER Summary of this function goes here
%   Detailed explanation goes here
    newNonDeferLoad = nonDeferLoad;
    for i = startTime : startTime + execTime - 1
        newNonDeferLoad(i) = newNonDeferLoad(i) + powerPerInterval;
    end
        
end

