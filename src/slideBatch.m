clear; close all; clc;

%% 
% grid power prices for every hour, in cents per kWh
GridCost = [2.7; 2.4; 2.3; 2.3; 2.3; 2.5; 2.8; 3.4; 3.8; 5; 6.1; 6.8; 7.4; 
            8.2; 10; 10.9; 11.9; 10.1; 9.2; 7; 7; 5.2; 4.2; 3.5];
        
%% Job 1, Fixed nonDeferablePower
T = 24;
nonDeferLoad = zeros(T, 1);
mergeData
sss = size(LoadTotal);
sss = sss(2);
price = zeros(3, sss);

% Deferable Load Pattern Model
slidableLoads;
% Assume only one non preemptible job for now, dishwahser
job = clothesDryer;
deadline = job(1);
period = job(2);
execTime = job(3);
powerPerCycle = job(4);

slideDistance = execTime : T;
costBenifitForDiffSlideDis = zeros(size(slideDistance, 2), 1);
jjj = 1;


for slideDis = slideDistance
    for iii = 1 : sss
        nonDeferLoad = LoadTotal(:, iii);
        slide
        price(1, iii) = originalPrice;    
        price(2, iii) = cost;    %cost after optimization
        price(3, iii) = (originalPrice - cost) / originalPrice * 100;  %cost reduction
    end
    totalOriginalPrice = sum(price(1, :));
    totalOptimizedCost = sum(price(2, :));
    avgReduction = (totalOriginalPrice - totalOptimizedCost) / totalOriginalPrice * 100;
    costBenifitForDiffSlideDis(jjj, 1) = avgReduction;
    jjj = jjj + 1;
end


slideSimResultData = [slideDistance' costBenifitForDiffSlideDis];

plot(slideDistance', costBenifitForDiffSlideDis, 'r', 'LineWidth',2);
title('Average Electric Bill Cost Reduction(%) with Different Slide Distance');
xlabel('Slide Distance (h)');
ylabel('Cost Reduction (%) ');
grid
set(gcf, 'PaperPosition', [0 0 5 5]); %Position plot at left hand corner with width 5 and height 5.
set(gcf, 'PaperSize', [5 5]); %Set the paper to have width 5 and height 5.
saveas(gcf, '../simResults/slideBenefit', 'pdf') %Save figure

csvwrite('../simResults/slideSimResults.csv', slideSimResultData);