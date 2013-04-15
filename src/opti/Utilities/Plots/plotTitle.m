function plotTitle(prob,xb,dolog)
%PLOTTITLE Add Plot Title + Optimum to Current Axes
    
%   Copyright (C) 2011 Jonathan Currie (I2C2)

%Plot Optimum
hold on;
plot(xb(1),xb(2),'r.','markersize',20);

switch(lower(prob.type))
    case {'lp','bilp','milp','sdp'}
        fval = prob.f'*xb;
    case {'qp','qcqp','miqp','miqcqp'}
        if(triu(prob.H)==prob.H)
            H = prob.H+triu(prob.H,1)';
        elseif(tril(prob.H)==prob.H)
            H = prob.H+tril(prob.H,-1)';
        else
            H = prob.H;        
        end
        fval = 0.5*xb'*H*xb + prob.f'*xb;
    case {'uno','nlp','minlp'}
        fval = prob.fun(xb);
    case 'nls'
        if(nargin(prob.fun) == 2)
            fval = sum((prob.fun(xb,prob.xdata)-prob.ydata).^2);
        else
            fval = sum((prob.fun(xb)-prob.ydata).^2);
        end
end

%Title
if(~dolog)
    title([upper(prob.type) ' Plot - Min: ',sprintf('[%2.2g; %2.2g]',xb(1),xb(2)), '  Fval: ',num2str(fval)]);
else
    title([upper(prob.type) ' LOG Plot - Min: ',sprintf('[%2.2g; %2.2g]',xb(1),xb(2)), '  Fval: ',num2str(fval)]);
end
hold off; 