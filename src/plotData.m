%% ===============Plot Power Prediction per hour===========================
% Currently using HARD CODED power prediction, change to ML later!!!!!!!!!!
figure;
hours = 1: 24;
p1 = plot(hours, Load);
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
plot(hours, Load, '-yo',... 
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
    
%% ================Plot Solar Smart Charge Scheduling =====================
figure;
plot(hours, BattGreen, 'gx','LineWidth',2);
hold on;
plot(hours, LoadGreen, 'go','LineWidth',2);
hold on;
plot(hours, NetGreen, 'g--','LineWidth',2);
hold on;
plot(hours, BattGrid, 'bx','LineWidth',2);
hold on;
plot(hours, LoadBatt, 'bo','LineWidth',2);
hold on;
plot(hours, LoadGrid, 'r','LineWidth',2);
hold on;
plot(hours, Load, '-yo',... 
                          'LineWidth',2,...
                          'MarkerEdgeColor','k',...
                          'MarkerFaceColor',[.49 1 .63],...
                          'MarkerSize',10);
grid;
title('Smart Charge Scheduling with Solar Energy.');
xlabel('Hours')
ylabel('Power(kWh)')
legend('Solar for Battery Charge', 'Solar for Load', 'Solar for NetMetering',...
       'Grid for Batterty Charge', 'Batterty for Load', 'Grid for Load',...
       'Work Load Prediction','Location', 'SouthOutside');