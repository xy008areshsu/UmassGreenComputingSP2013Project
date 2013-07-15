
        
%% =========Convert Non Preemptible Loads into Non Deferable Loads=========
% Try every possible time scheduling for Non Preemptible Loads, converting
% into Non Deferable Loads
nonDeferLoadChoice = zeros(T, slideDis - execTime + 1);
costs = zeros(slideDis - execTime + 1, 1);
powerPerInterval = powerPerCycle / execTime;

% Solve each possible non preemtible laods scheduling
for i = T - slideDis + 1: T - execTime + 1
    nonDeferLoadChoice(:, i - T + slideDis) = mergeNonPreemtibleToNonDefer(nonDeferLoad, powerPerInterval, i, execTime);
    costs(i-T + slideDis) = sum(nonDeferLoadChoice(:, i - T + slideDis) .* GridCost);
end

% Get the minimum cost for these schedulings
[cost, minIndex ] = min(costs);
cost = cost / 100;

%% =======================Plot Results and Write to File===================
nonDerPrice = sum(nonDeferLoad.*GridCost) / 100;
dyerPrice = (powerPerCycle * GridCost(17)) / 100;
originalPrice = nonDerPrice + dyerPrice;
% fprintf('The Electricity Bill without Smart Charge per Day is: $%f\n', originalPrice);
% fprintf('The Electricity Bill with Smart Charge Solar-Battery per Day is: $%f\n', cost);
% fprintf('Total cost reduction is: %f%%\n', (originalPrice - cost) / originalPrice * 100);

