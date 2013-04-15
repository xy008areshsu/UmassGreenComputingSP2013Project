function plotIntCon(prob)
%PLOTINTCON Plot Integer Constraints on the current figure
%   plotIntCon(prob)

%   Copyright (C) 2011 Jonathan Currie (I2C2)

xl = round(xlim); yl = round(ylim);
hold on;

%Get Problem Components
if(~isempty(prob.rl))
    [A,b,Aeq,beq] = row2gen(prob.A,prob.rl,prob.ru);
else
    A = prob.A; b = prob.b;
    Aeq = prob.Aeq; beq = prob.beq;
end
Q = prob.Q; l = prob.l; qrl = prob.qrl; qru = prob.qru;
if(isempty(prob.lb)), lb = -Inf; else lb = prob.lb; end
if(isempty(prob.ub)), ub = Inf; else ub = prob.ub; end

%Generate Grid and check for binary constraints
if(prob.int.ind(1) == -1)
    x = 0:1;
else
    try
        x = (floor(xl(1))+1):(ceil(xl(2))-1);
    catch ME
        optiwarn('opti:plotint',['Could not plot integer constraints due to plotting error: ' ME.message]);
        return;
    end
end
if(prob.int.ind(2) == -1)
    y = 0:1;
else
    try
        y = (floor(yl(1))+1):(ceil(yl(2))-1);
    catch ME
        optiwarn('opti:plotint',['Could not plot integer constraints due to plotting error: ' ME.message]);
        return;
    end
end
[X,Y] = meshgrid(x,y);

%Check for row nonlinear constraints
if(~isempty(prob.cl))
    prob = nrow2mix(prob);
end

%Work out feasible integer points
idx = zeros(numel(X),1); Xv = X(:); Yv = Y(:);  
for i=1:numel(X)
    xy = [Xv(i), Yv(i)]';
    if(~isempty(prob.A))
        idx(i) = all(b >= A*xy) && all(xy >= lb) && all(xy <= ub);  
    else
        idx(i) = all(xy >= lb) && all(xy <= ub);  
    end
    if(~isempty(Aeq))
        idx(i) = idx(i) && (abs(Aeq*xy-beq) < 1e-6);
    end
    if(~isempty(Q))
        for n = 1:prob.sizes.nqc
            if(iscell(Q))
                nQ = Q{n}; nl = l(:,n); nrl = qrl(n); nru = qru(n);
            else
                nQ = Q; nl = l; nrl = qrl; nru = qru;
            end
            if(~isinf(nru))
                qu = all(xy'*nQ*xy + nl'*xy <= nru);
            else
                qu = true;
            end
            if(~isinf(nrl))
                ql = all(xy'*-nQ*xy - nl'*xy <= -nrl);
            else
                ql = true;
            end
            idx(i) = idx(i) && ql && qu;
        end
    end
    if(~isempty(prob.nle))
        vals = prob.nlcon(xy);
        leI = find(prob.nle == -1);
        geI = find(prob.nle == 1); 
        eqI = find(prob.nle == 0);
        nlrhs = prob.nlrhs;
        idx(i) = idx(i) && all(vals(leI) <= nlrhs(leI)) && all(vals(geI) >= nlrhs(geI)) && all(abs(vals(eqI)-nlrhs(eqI)) < 1e-6);
    end
end
%Plot points
idx = logical(idx);
plot(X(idx),Y(idx),'bo','markerface','b');
plot(X(~idx),Y(~idx),'bo');

hold off;

end

