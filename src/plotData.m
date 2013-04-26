%% ===============Plot Power Prediction per hour===========================
% Currently using HARD CODED power prediction, change to ML later!!!!!!!!!!
figure;
hours = 0: 23;
p1 = area(hours, Load);
grid;
title('Power Prediction Per Hour in kWh.');
xlabel('hours');
ylabel('power(kWh)');
set(p1, 'FaceColor', [1 0 0]);
%set(p1, 'Color', 'red', 'LineWidth', 3);


%% ================Plot LP Battery Scheduling ===========================
figure;
pp = p + s;
pp = pp + d;
p1 = area(hours, pp);
set(p1, 'FaceColor', [1 0 0]);
hold on
plot(hours, s, 'g-', 'LineWidth',2);
p1 = area(hours, d);
set(p1, 'FaceColor', [0 0 1]);
plot(hours, Load1, 'k--','LineWidth',2);
grid;
set(gca,'Layer','top')
[AX, H1, H2] = plotyy(hours, Green, hours, GridCost); 
set(H1, 'Color', 'g','LineStyle','--', 'LineWidth',2);
set(H2, 'Color', 'c','LineStyle','--', 'LineWidth',2);
title('LP Battery Scheduling.');
xlabel('Hours')
set(get(AX(1),'Ylabel'),'String','Power(kW)') 
set(get(AX(2),'Ylabel'),'String','Price(cents/kWh)') 
legend('Grid Power Consumption','Battery Charge','Battery Dischage',...
       'Loads', 'Solar Available', 'Grid Power Cost','Location', 'SouthOutside');
    
%% ================Plot LP Battery Solar Scheduling =====================
figure;
hold on;
 
plot(hours, BattGreen1, 'g-','LineWidth',2);
plot(hours, LoadGreen1, 'g-.','LineWidth',2);
plot(hours, NetGreen1, 'g.','LineWidth',2);
plot(hours, BattGrid1, 'b-','LineWidth',2);
plot(hours, LoadBatt1, 'b--','LineWidth',2);
plot(hours, LoadGrid1, 'r-','LineWidth',2);
plot(hours, Load1, 'k--','LineWidth',2);
grid;
[AX, H1, H2] = plotyy(hours, Green, hours, GridCost); 
set(H1, 'Color', 'g','LineStyle','--', 'LineWidth',2);
set(H2, 'Color', 'c','LineStyle','--', 'LineWidth',2);
title('LP Battery Solar Non Deferable Scheduling.');
xlabel('Hours')
set(get(AX(1),'Ylabel'),'String','Power(kW)') 
set(get(AX(2),'Ylabel'),'String','Price(cents/kWh)') 

legend('Solar for Battery Charge', 'Solar for Load', 'Solar for NetMetering',...
       'Grid for Batterty Charge', 'Batterty for Load', 'Grid for Load',...
       'Loads','Solar Available', 'Grid Power Cost', 'Location',  'SouthOutside');
%% ============Plot LP Battery Solar Deferable Scheduling =================
figure;
hold on;
 
plot(hours, BattGreen2, 'g-','LineWidth',2);
plot(hours, LoadGreen2, 'g-.','LineWidth',2);
plot(hours, NetGreen2, 'g.','LineWidth',2);
plot(hours, BattGrid2, 'b-','LineWidth',2);
plot(hours, LoadBatt2, 'b--','LineWidth',2);
plot(hours, LoadGrid2, 'r-','LineWidth',2);
plot(hours, Load2, 'k--','LineWidth',2);
grid;
[AX, H1, H2] = plotyy(hours, Green, hours, GridCost); 
set(H1, 'Color', 'g','LineStyle','--', 'LineWidth',2);
set(H2, 'Color', 'c','LineStyle','--', 'LineWidth',2);
title('LP Battery Solar  Deferable Scheduling.');
xlabel('Hours')
set(get(AX(1),'Ylabel'),'String','Power(kW)') 
set(get(AX(2),'Ylabel'),'String','Price(cents/kWh)') 

legend('Solar for Battery Charge', 'Solar for Load', 'Solar for NetMetering',...
       'Grid for Batterty Charge', 'Batterty for Load', 'Grid for Load',...
       'TotalLoad','Solar Available', 'Grid Power Cost', 'Location',  'SouthOutside');
   
figure
hold on;
plot(hours, preemptibleLoadsSchedule(:,1), 'r-', 'LineWidth',2);
plot(hours, preemptibleLoadsSchedule(:,2), 'g-','LineWidth',2);
plot(hours, nonPreemptibleLoadsSchedule, 'b-', 'LineWidth',2);
grid
title('LP Battery Solar Deferable WorkLoad Scheduling.');
xlabel('Hours')
legend('nonPreemptibleLoadsSchedule','1st preemptibleLoadsSchedule', '2nd preemptibleLoadsSchedule',...
       'Location',  'SouthOutside');
