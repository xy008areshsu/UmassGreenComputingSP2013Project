function plotObj(prob,xb,scale,dolog)
%PLOTOBJ Plot the objective function contour
%   plotObj(prob,xb,scale,dolog)

%   Copyright (C) 2011 Jonathan Currie (I2C2)

%Paper Plot Check
ad = getappdata(0);
if(isfield(ad,'paperplot') && ad.paperplot == 1), pp = 1; else pp = 0; end

%Contour Colour
dkg = [0.4 0.4 0.4];

%Detail based on problem type
switch(lower(prob.type))
    case {'lp','milp','bilp'}
        n = 5;
    case {'qp','qcqp','miqp','miqcqp','sdp','misdp'}
        n = 30;
    case {'nls','uno','nlp','minlp'}
        n = 50;
    otherwise
        n = 50;
end

%Generate Grid
[x1,x2] = meshgrid(linspace(xb(1)-scale,xb(1)+scale,n),linspace(xb(2)-scale,xb(2)+scale,n));
nox = size(x1);
noy = size(x2);
obj = zeros(nox(1),noy(2));
%Get Objective
switch(upper(prob.type))
    case {'LP','BILP','MILP','SDP','MISDP'}
        fun = @(x) prob.f'*x;
    case {'QP','QCQP','MIQP','MIQCQP'}
        fun = @(x) 0.5*x'*prob.H*x + prob.f'*x;
    case {'UNO','NLP','MINLP'}
        fun = prob.fun;
    case {'NLS'}
        if(nargin(prob.fun) == 2)
            fun = @(x) sum((prob.fun(x,prob.xdata)-prob.ydata).^2);
        else
            fun = @(x) sum((prob.fun(x)-prob.ydata).^2);
        end
end
%Create Objective Surface
for n = 1:nox(1)
    for m = 1:noy(2)
        x = [x1(n,m) x2(n,m)]';
        obj(n,m) = fun(x);
    end
end
%Do Log Plot if asked
if(dolog)
    obj = log(obj);
end
%Draw Contour Plot
clf;
[hc,hl] = contour(x1,x2,obj,':','color',dkg);
th = clabel(hc,hl);
%See if we are plotting for a paper
if(pp)
    set(th,'FontSize',15);
end
hold on;
%Plot Minimum Contour
fval = fun(xb);
contour(x1,x2,obj,':','color',dkg,'levellist',fval);
if(pp)
    xlabel('x_1','FontSize',15); ylabel('x_2','FontSize',15);
    set(gca,'FontSize',15,'LineWidth',1.5);
else
    xlabel('x_1'); ylabel('x_2');
end

%Plot Optimum + Title
plotTitle(prob,xb,dolog);
hold off;
end

