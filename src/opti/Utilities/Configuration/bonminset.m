function options = bonminset(varargin)
%BONMINSET  Create or alter the options for Optimization with BONMIN
%
% options = bonminset('param1',value1,'param2',value2,...) creates an IPOPT
% options structure with the parameters 'param' set to their corresponding
% values in 'value'. Parameters not specified will be set to the IPOPT
% default.
%
% options = bonminset(oldopts,'param1',value1,...) creates a copy of the old
% options 'oldopts' and then fills in (or writes over) the parameters
% specified by 'param' and 'value'.
%
% options = bonminset() creates an options structure with all fields set to
% bonminset defaults.
%
% bonminset() prints a list of all possible fields and their function.
%
% See supplied BONMIN and IPOPT Documentation for further details of these options.

%   Copyright (C) 2011 Jonathan Currie (I2C2)

% Print out possible values of properties.
if (nargin == 0) && (nargout == 0)
    printfields();
    return
end

%Number args in
numberargs = nargin;

%Names and Defaults
Names = {'algorithm','var_lin','cons_lin','allowable_fraction_gap','allowable_gap','cutoff','cutoff_decr','enable_dynamic_nlp','iteration_limit',...
         'nlp_failure_behavior','node_comparison','num_cut_passes','num_cut_passes_at_root',...
         'number_before_trust','number_strong_branch','solution_limit','sos_constraints','tree_search_strategy',...
         'variable_selection','feasibility_pump_objective_norm','heuristic_RINS','heuristic_dive_MIP_fractional',...
         'heuristic_dive_MIP_vectorLength','heuristic_dive_fractional','heuristic_dive_vectorLength',...
         'heuristic_feasibility_pump','pump_for_minlp','candidate_sort_criterion','maxmin_crit_have_sol',...
         'maxmin_crit_no_sol','min_number_strong_branch','number_before_trust_list','number_look_ahead',...
         'number_strong_branch_root','setup_pseudo_frac','coeff_var_threshold','dynamic_def_cutoff_decr','first_perc_for_cutoff_decr',...
         'max_consecutive_infeasible','num_resolve_at_infeasibles',...
         'num_resolve_at_node','num_resolve_at_root','second_perc_for_cutoff_decr','milp_solver','milp_strategy','bb_log_interval',...
         'bb_log_level','lp_log_level','milp_log_level','nlp_log_level','nlp_log_at_root','oa_log_frequency','oa_log_level',...
         'max_consecutive_failures','max_random_point_radius','num_retry_unsolved_random_point','random_point_perturbation_interval',...
         'random_point_type','warm_start'}';
Defaults = {'B-BB',NaN,NaN,0,0,1e100,1e-5,'no',2^31-1,'stop','best-bound',1,20,8,20,2^31-1,'enable','probed-dive','osi-strong',1,'no',...
            'yes','no','no','no','no','no','best-ps-cost',0.1,0.7,0,0,0,2^31-1,0.5,0.1,'no',-0.02,0,0,0,0,-0.05,'Cbc_D','find_good_sol',...
            100,1,0,0,0,0,100,1,10,100000,0,1,'Jon','none'}';  
%Get IPOPT Defaults if required
if(nargin == 2 && strcmpi(varargin{2},'noipopt'))
    numberargs = 1;
else
    iset = ipoptset('bonmin');       
    Names = [Names;fieldnames(iset)];
    Defaults = [Defaults;struct2cell(iset)];
end

%Collect Sizes and lowercase matches         
m = size(Names,1); 
%Create structure with all names and default values
st = [Names,Defaults]'; options = struct(st{:});

% Check we have char or structure input. If structure, insert arguments
i = 1;
while i <= numberargs
    arg = varargin{i};
    if ischar(arg)
        break;
    end
    if ~isempty(arg)
        if ~isa(arg,'struct')
            error('An argument was supplied that wasn''t a string or struct!');
        end
        for j = 1:m
            if any(strcmp(fieldnames(arg),Names{j,:}))
                val = arg.(Names{j,:});
            else
                val = [];
            end
            if ~isempty(val)
                checkfield(Names{j,:},val);
                options.(Names{j,:}) = val;
            end
        end
    end
    i = i + 1;
end

%Check we have even number of args left
if rem(numberargs-i+1,2) ~= 0
    error('You do not have a value specified for each field!');
end

%Go through each argument pair and assign to correct field
expectval = 0; %first arg is a name
while i <= numberargs
    arg = varargin{i};

    switch(expectval)
        case 0 %field
            if ~ischar(arg)
                error('Expected field name to be a string! - Argument %d',i);
            end
            j = find(strcmp(arg,Names) == 1);
            if isempty(j)  % if no matches
                error('Unrecognised parameter %s',arg);
            elseif(length(j) > 1)
                error('Ambiguous parameter %s',arg);
            end
            expectval = 1; %next arg is a value
        case 1
            checkfield(Names{j,:},lower(arg));
            options.(Names{j,:}) = lower(arg);
            expectval = 0;
    end
    i = i + 1;
end

if expectval %fallen off end somehow
    error('Missing value for %s',arg);
end



function checkfield(field,value)
%Check a field contains correct data type

if isempty(value)
    return % empty matrix is always valid
end

switch lower(field)
    %numeric
    case {'var_lin','cons_lin','allowable_fraction_gap','allowable_gap','cutoff','cutoff_decr',...
          'iteration_limit','num_cut_passes','num_cut_passes_at_root','number_before_trust',...
          'number_strong_branch','solution_limit','feasibility_pump_objective_norm','maxmin_crit_have_sol',...
          'maxmin_crit_no_sol','min_number_strong_branch','number_before_trust_list','number_look_ahead',...
          'number_strong_branch_root','setup_pseudo_frac','coeff_var_threshold','first_perc_for_cutoff_decr',...
          'max_consecutive_infeasible','num_resolve_at_infeasibles','num_resolve_at_node','num_resolve_at_root',...
          'second_perc_for_cutoff_decr','bb_log_interval','bb_log_level','lp_log_level','milp_log_level',...
          'nlp_log_level','nlp_log_at_root','oa_log_frequency','oa_log_level','max_consecutive_failures',...
          'max_random_point_radius','num_retry_unsolved_random_point','random_point_perturbation_interval'}
        if(isnumeric(value))
            valid = true;
        else
            valid = false; errmsg = sprintf('Parameter %s should be a double vector',field);
        end
    %char array
    case {'nlp_failure_behavior','node_comparison','sos_constraints',...
          'tree_search_strategy','variable_selection','heuristic_rins','heuristic_dive_mip_fractional',...
         'heuristic_dive_mip_vectorlength','heuristic_dive_fractional','heuristic_dive_vectorlength',...
         'heuristic_feasibility_pump','pump_for_minlp','candidate_sort_criterion','dynamic_def_cutoff_decr',...
         'milp_solver','milp_strategy','random_point_type','warm_start'}
        if(ischar(value))
            valid = true; 
        else
            valid = false; errmsg = sprintf('Parameter %s should be a char array',field);
        end     
    %algorithm
    case 'algorithm'
        va = {'B-BB','B-OA','B-QG','B-Hyb','B-Ecp','B-iFP'};
        if(any(ismember(lower(va),lower(value))))
            valid = true;
        else
            valid = false;
            errmsg = sprintf('Unrecognized BONMIN algorithm choice. Valid options are: ''%s''',va{1});
            for i = 2:length(va)-1
                errmsg = sprintf('%s, ''%s''',errmsg,va{i});
            end
            errmsg = sprintf('%s or ''%s''.',errmsg,va{end});
        end
    %options which crash (fow now hopefully!)
    case 'enable_dynamic_nlp'
        if(strcmpi(value,'no'))
            valid = true;
        else
            valid = false;
            errmsg = 'Currently enable_dynamic_nlp set to ''yes'' crashes BONMIN via the MATLAB interface';
        end
    otherwise  
        %try for ipoptset arg
        iset = ipoptset(field,value);
        if(~isempty(iset))
            valid = true;
        else
            %otherwise error
            valid = false;
            errmsg = sprintf('Unrecognized parameter name ''%s''.', field);
        end
end

if valid 
    return;
else %error
    ME = MException('bonminset:FieldError',errmsg);
    throwAsCaller(ME);
end

function printfields()
%Print out fields with defaults
fprintf('  BONMIN GENERAL SETTINGS:\n');
fprintf('                       algorithm: [ MIP Algorithm: {''B-BB''}, ''B-OA'', ''B-QG'', ''B-Hyb'', ''B-Ecp'', ''B-iFP'' ] \n');
fprintf('                         var_lin: [ Decision Variable Linearity (0 - Nonlinear, 1 - Linear) {zeros(n,1)} ] \n');
fprintf('                        cons_lin: [ Constraint Linearity (0 - Nonlinear, 1 - Linear) {zeros(m,1)} ] \n');

fprintf('\n  BONMIN BRANCH & BOUND SETTINGS:\n');
fprintf('          allowable_fraction_gap: [ Value of Relative Gap when algorithm stops {0} ] \n');
fprintf('                   allowable_gap: [ Value of Absolute Gap when algorithm stops {0} ] \n');
fprintf('                          cutoff: [ The algorithm will only look for values better than cutoff {1e100} ] \n');
fprintf('                     cutoff_decr: [ Amount by which cutoff is decremented below a new best upper bound {1e-5} ] \n');
fprintf('              enable_dynamic_nlp: [ Enable dynamic linear and quadratic rows addition in NLP ''yes'', {''no''} ] \n');
fprintf('                 iteration_limit: [ Cumulated maximum number of iterations in the algorithm to process continuous relaxations {2^31-1} ] \n');
fprintf('            nlp_failure_behavior: [ Action to take when an NLP is unsolved by IPOPT {''stop''}, ''fathom'' ] \n');
fprintf('                 node_comparison: [ Node selection strategy {''best-bound''}, ''depth-first'', ''breadth-first'', ''dynamic'', ''best-guess'' ] \n');
fprintf('                  num_cut_passes: [ Maximum number of cut passes at regular nodes {1} ] \n');
fprintf('          num_cut_passes_at_root: [ Maximum number of cut passes at root node {20} ] \n');
fprintf('             number_before_trust: [ Number of branches on a variable before its pseudo costs are to be believed in dynamic strong branching {8} ] \n');
fprintf('            number_strong_branch: [ Maximum number of variables considered for strong branching {20} ] \n');
fprintf('                  solution_limit: [ Abort after this many integer feasible solutions have been found (or 0 to deactivate) {2^31-1} ] \n');
fprintf('                 sos_constraints: [ Activate SOS Type 1 constraints {''enable''}, ''disable'' ] \n');
fprintf('            tree_search_strategy: [ Tree traversing strategy {''probed-dive''}, ''top-node'', ''dive'', ''dfs-dive'', ''dfs-dive-dynamic'' ] \n');
fprintf('              variable_selection: [ Variable selection strategy {''osi-strong''}, ''most-fractional'', ''reliability-branching'', ''qp-strong-branching'', ''lp-strong-branching'', ''nlp-strong-branching'', ''osi-simple'', ''strong-branching'', ''random'' ] \n');

fprintf('\n  BONMIN MINLP HEURISTIC SETTINGS:\n');
fprintf(' feasibility_pump_objective_norm: [ Norm of feasibility pump objective norm {1}, 2 ] \n');
fprintf('                  heuristic_RINS: [ Use RINS heuristic {''no''}, ''yes'' ] \n');
fprintf('   heuristic_dive_MIP_fractional: [ Use Dive MIP fractional heuristic {''no''}, ''yes'' ] \n');
fprintf(' heuristic_dive_MIP_vectorLength: [ Use Dive MIP vectorLength heuristic {''no''}, ''yes'' ] \n');
fprintf('       heuristic_dive_fractional: [ Use Dive fractional heuristic {''yes''}, ''no'' ] \n');
fprintf('     heuristic_dive_vectorLength: [ Use Dive vectorLength heuristic {''yes''}, ''no'' ] \n');
fprintf('      heuristic_feasibility_pump: [ Use feasibility pump heuristic {''no''}, ''yes'' ] \n');
fprintf('                  pump_for_minlp: [ Use FP for MINLP {''no''}, ''yes'' ] \n');

fprintf('\n  BONMIN NON-CONVEX PROBLEM SETTINGS:\n');
fprintf('             coeff_var_threshold: [ Coefficient of variation threshold (for dynamic definition of cutoff_decr) {0.1} ] \n');
fprintf('         dynamic_def_cutoff_decr: [ Define cutoff_decr dynamically? {''no''}, ''yes'' ] \n');
fprintf('      first_perc_for_cutoff_decr: [ Percentage used when the coeff of variance is smaller than the threshold, to compute cutoff_decr dynamically {-0.02} ] \n');
fprintf('      max_consecutive_infeasible: [ Maximum number of consecutive infeasible subproblems before aborting a branch {0} ] \n');
fprintf('      num_resolve_at_infeasibles: [ Number of tries to resolve an infeasible node (other than the root) of the tree with different starting points {0} ] \n');
fprintf('             num_resolve_at_node: [ Number of tries to resolve a node (other than the root) of the tree with different starting points (like multi-start) {0} ] \n');
fprintf('             num_resolve_at_root: [ Number of tries to resolve the root node with different starting points {0} ] \n');
fprintf('     second_perc_for_cutoff_decr: [ Percentage used when the coeff of variance is greater than the threshold, to compute cutoff_decr dynamically {-0.05} ] \n');

fprintf('\n  BONMIN NLP SOLUTION ROBUSTNESS SETTINGS:\n');
fprintf('        max_consecutive_failures: [ Number of consecutive unsolved problems before aborting a branch of the tree {10} ] \n');
fprintf('         max_random_point_radius: [ Max value for coordinate of a random point {100000} ] \n');
fprintf(' num_retry_unsolved_random_point: [ Number of times that the algorithm will try to resolve an unsolved NLP with a random starting point (with new point) {0} ] \n');
fprintf('random_point_perturbation_interval: [ Amount by which starting point is perturbed when choosing a random point {1} ] \n');
fprintf('               random_point_type: [ Random starting point method {''Jon''}, ''Andreas'', ''Claudia'' ] \n');
fprintf('                      warm_start: [ Warm start method {''none''}, ''fake_basis'', ''optimum'', ''interior'' ] \n');

fprintf('\n  BONMIN STRONG BRANCHING SETTINGS:\n');
fprintf('        candidate_sort_criterion: [ Criterion used to choose candidates in strong-branching {''best-ps-cost''}, ''worst-ps-cost'', ''most-fractional'', ''least-fractional'' ] \n')
fprintf('            maxmin_crit_have_sol: [ Weight towards minimum of lower and upper branching estimates when a solution has been found {0.1} ] \n')
fprintf('              maxmin_crit_no_sol: [ Weight towards minimum of lower and upper branching estimates when no solution has been found {0.7} ] \n')
fprintf('        min_number_strong_branch: [ Minimum number of variables for strong branching (overriding trust) {0} ] \n')
fprintf('        number_before_trust_list: [ Number of branches on a variable vbefore its pseudo costs are to be believed during setup of strong branching list {0} ] \n')
fprintf('               number_look_ahead: [ Limit of look-ahead strong-branching trials {0} ] \n')
fprintf('       number_strong_branch_root: [ Maximum number of variables considered for strong branching at root node {2^31-1} ] \n')
fprintf('               setup_pseudo_frac: [ Proportion of strong branching list that has to be taken from most integer infeasible list {0.5} ] \n')

fprintf('\n  BONMIN MILP SOLVER SETTINGS:\n');
fprintf('                     milp_solver: [ Subsolver to solve MILP problems in OA decompositions {''Cbc_D''}, ''Cplex'' (must be installed on your PC) ] \n');
fprintf('                   milp_strategy: [ MILP solving strategy {''find_good_sol''}, ''solve_to_optimality'' ] \n');

fprintf('\n  BONMIN OUPUT AND LOG LEVEL SETTINGS:\n');
fprintf('                 bb_log_interval: [ Interval at which node level output is printed (number of nodes) {100} ] \n');
fprintf('                    bb_log_level: [ Level of branch and bound log detail (0-5) {1} ] \n');
fprintf('                    lp_log_level: [ Level of LP solver log detail (0-4) {0} ] \n');
fprintf('                  milp_log_level: [ Level of MILP solver log detail (0-4) {0} ] \n');
fprintf('                   nlp_log_level: [ Level of NLP solver log detail (0-2) {0} ] \n');
fprintf('                 nlp_log_at_root: [ Level of NLP solver log detail at root node (0-12) {0} ] \n');
fprintf('                oa_log_frequency: [ Frequency (in seconds) of OA log messages  {100} ] \n');
fprintf('                    oa_log_level: [ Level of OA decomposition log detail (0-2) {1} ] \n');

fprintf('\n  IPOPT (RELAXED SOLVER) SETTINGS:\n');
ipoptset('bonmin');

