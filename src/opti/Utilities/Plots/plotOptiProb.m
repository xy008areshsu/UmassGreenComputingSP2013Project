function plotOptiProb(prob,xb,scale,dolog)
%PLOTOPTIPROB Plot opti problem optimization surface with constraints
%
%   plotOptiProb(prob,xb,scale) plots a contour plot of the optimization
%   surface where prob is an optiprob structure. xb is the solution vector, 
%   and scale zooms the plot.

%   Copyright (C) 2011 Jonathan Currie (I2C2)

ptypes = {'LP','BILP','MILP','QP','QCQP','MIQP','MIQCQP','SDP','MISDP','NLS','UNO','NLP','MINLP'};

%Check we have a 'plottable' problem
if(~any(strcmpi(prob.type,ptypes)))
    error('A Problem of type ''%s'' cannot be plotted!',prob.type);
end

%Generate Objective Contour Plot
plotObj(prob,xb,scale,dolog)

%Plot Linear Constraints
if(~isempty(prob.rl))
    [A,b,Aeq,beq] = row2gen(prob.A,prob.rl,prob.ru);
    plotLinCon(A,b,Aeq,beq);
else
    plotLinCon(prob.A,prob.b,prob.Aeq,prob.beq);
end

%Plot Bounds
if(~strcmpi(prob.type,'bilp'))
    plotBounds(prob.lb,prob.ub);
end

%Plot Quadratic Constraints
if(prob.sizes.nqc)
    plotQuadCon(prob.Q,prob.l,prob.qrl,prob.qru);
end

%Plot Semidefinite Constraints
if(prob.sizes.nsdcone)
    plotSDCon(prob.sdcone);
end
    
%Plot Nonlinear Constraints
if(~isempty(prob.nle) || ~isempty(prob.cl))
    plotNonlinCon(prob);
end

%Check for Integer Constraints
if(any(prob.int.ind))
    plotIntCon(prob);
    plotTitle(prob,xb,dolog);
end

%Check if Data Fitting Problem
if(~isempty(prob.ydata))
    plotDataFit(prob,xb);
end
