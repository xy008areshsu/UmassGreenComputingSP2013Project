function plotDataFit(prob,xb)
%PLOTDATAFIT Add new Plot with Data + Fit

%   Copyright (C) 2011 Jonathan Currie (I2C2)
    
if(~isempty(prob.xdata))
    if(length(prob.xdata) ~= length(prob.ydata))
        optiwarn('opti:dfit','Cannot plot data fit as xdata and ydata are not the same length!');
    end    
    %Plot Fit
    figure(2);
    %Generate Smooth Data
    x = linspace(prob.xdata(1),prob.xdata(end),1e3);
    y = prob.fun(xb,x);
    plot(prob.xdata,prob.ydata,'o',x,y);
    title(['NLS Curve Fit - SSE: ' num2str(sum((prob.fun(xb,prob.xdata)-prob.ydata).^2))]);
    xlabel('x'); ylabel('y');
    legend('Original Data','NLS Fit');
end


