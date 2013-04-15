function plotBounds(lb,ub)
%PLOTBOUNDS Plot bounds on the current figure
%   plotBounds(lb,ub)

%   Copyright (C) 2011 Jonathan Currie (I2C2)

xl = xlim; yl = ylim;
hold on;

%Lower Bounds
if(~isempty(lb))
    patch([xl(1) xl(2) xl(2) xl(1)],[lb(2) lb(2) yl(1) yl(1)],'y','FaceAlpha',0.3)
    patch([lb(1) lb(1) xl(1) xl(1)],[yl(1) yl(2) yl(2) yl(1)],'y','FaceAlpha',0.3)
end

%Upper Bounds
if(~isempty(ub))
    patch([xl(1) xl(2) xl(2) xl(1)],[ub(2) ub(2) yl(2) yl(2)],'y','FaceAlpha',0.3)
    patch([ub(1) ub(1) xl(2) xl(2)],[yl(1) yl(2) yl(2) yl(1)],'y','FaceAlpha',0.3)
end

hold off;

end

