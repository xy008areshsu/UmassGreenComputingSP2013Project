%% ===============Plot Power Prediction per hour===========================
% Currently using HARD CODED power prediction, change to ML later!!!!!!!!!!
figure;
hours = 1: 24;
p1 = plot(hours, powerPredict);
grid;
title('Power Prediction Per Hour in kWh.');
xlabel('hours');
ylabel('power(kWh)');
set(p1, 'Color', 'red', 'LineWidth', 3);


%% ================Plot Smart Change Scheduling ===========================
figure;
plot(hours, s, 'g','LineWidth',2);
hold on;
plot(hours, d, 'b','LineWidth',2);
hold on;
plot(hours, p, 'r','LineWidth',2);
hold on;
plot(hours, powerPredict, '-yo',... 
                          'LineWidth',2,...
                          'MarkerEdgeColor','k',...
                          'MarkerFaceColor',[.49 1 .63],...
                          'MarkerSize',10);
grid;
title('Smart Charge Scheduling.');
xlabel('Hours')
ylabel('Power(kWh)')
legend('Battery Charge', 'Battery Dischage', 'Grid Power Consumption',...
       'Power Prediction', 'Location', 'SouthOutside');
    
