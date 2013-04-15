function varargout = optiBench(varargin)
%OPTIBENCH  Benchmark a problem type against all available solvers
%
%   optiBench(type) runs all available solvers for a given problem type 
%   (e.g. LP, MILP) against all test problems.
%
%   optiBench(type,no) specifies the maximum number of test problems to 
%   run. If empty the default is used.
%
%   optiBench(type,no,plot) specifies whether to plot the results as well.

%   Copyright (C) 2011 Jonathan Currie (I2C2)

if(isempty(varargin)), prob = 'LP'; else prob = varargin{1}; end
if(nargin > 1), testNo = varargin{2}; else testNo = []; end
if(nargin > 2), doPlot = varargin{3}; else doPlot = 1; end

tol = 1e-4; %'solved' tolerance

switch(lower(prob))
    case {'lp','milp','bilp','qp','sdp','nlp','nls'}
        str = upper(prob);
    otherwise
        error('Unknown (or unimplemented) problem type: %s',prob);
end

%Get all available solvers
if(strcmpi(prob,'nlp'))
    solvers = {'IPOPT','MATLAB','FILTERSD','NLOPT'};
elseif(strcmpi(prob,'lp'))
    solvers = checkSolver(str);
    ind = strcmpi(solvers,'SEDUMI'); 
    solvers(ind) = []; %no good with neq = nvar
else
    solvers = checkSolver(str);
end
n = length(solvers);
%Preallocate
times = cell(n,1);
res = cell(n,1);

%Run Benchmarks
cancel = 0;
h = waitbar(0,['Solver: ' upper(solvers{1})],'name',['OPTI Benchmark: ' upper(prob)],'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
wbar.h = h; wbar.n = n;
for i = 1:n    
    %Check Cancel
    if getappdata(h,'canceling')
        cancel = 1;
        break;
    end      
    wbar.x0 = (i-1)/n;
    try
        [times{i},res{i}] = testSolver(prob,solvers{i},testNo,wbar);  
    catch ME
        error(['Error testing ' solvers{i} ': ' ME.message]);
    end
    waitbar(i/n,h,['Solver: ' upper(solvers{min(n,i+1)})]);
end
delete(h);

if(~cancel)
    fprintf('\n');
    fprintf(['OPTI ' upper(prob) ' BENCHMARK\n']);
    %Draw Table
    for j = 1:length(res{i}.sol)
        fprintf('\nProblem %d:\n',j);
        fprintf('--------------------------------------------------\n');
        fprintf('  Solver    Status      Fval           Acc        Time\n');
        for i = 1:n
            fprintf('%8s    %4s    %+12.4f    %10.3e   %1.4fs\n',solvers{i},status(res{i}.ok(j)),res{i}.fval(j),res{i}.acc(j),times{i}(j));
        end
    end
    %Draw Summary
    fprintf('--------------------------------------------------\n');
    fprintf('%s Benchmark Summary:\n',upper(prob));
    fprintf('--------------------------------------------------\n');   
    fprintf('  Solver       Problems Solved      Total Time\n');
    for j = 1:length(solvers)
        acc = res{j}.acc; ind = isinf(acc);
        noProbs = length(acc);
        if(any(ind))
            acc(ind) = 1;
        end
        noSolved = sum(acc < tol);        
        totTime = sum(times{j});
        
        fprintf('%8s    %3d  /%3d  [%6.2f%%]      %2.4fs\n',solvers{j},noSolved,noProbs,noSolved/noProbs*100,totTime);
    end
    fprintf('--------------------------------------------------\n'); 
    if(doPlot)
        bench_plot(times,res,solvers,prob);
    end    
    if(nargout > 2)
        varargout{1} = times;
        varargout{2} = res;
        varargout{3} = solvers;
    end
else
    fprintf('\nCancelled!\n');
end



function msg = status(ok)

if(ok)
    msg = 'OK';
else
    msg = 'FAIL';
end
        
    