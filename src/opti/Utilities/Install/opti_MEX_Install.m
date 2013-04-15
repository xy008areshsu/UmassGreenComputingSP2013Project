%% OPTI MEX Install Script

% This file enables me to quickly rebuild all solvers - it is not intended
% to be called by the user!

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010
% - Intel Compiler XE v12 (FORTRAN)
% - Intel Math Kernel Library 10.3

% YOU MUST BE IN THE BASE DIRECTORY OF THE OPTI TOOLBOX!

%% -- Solvers --
%% BONMIN
opti_BONMIN_Install

%% CBC
opti_CBC_Install

%% CLP
opti_CLP_Install

%% CSDP
opti_CSDP_Install

%% DSDP
opti_DSDP_Install

%% FILTERSD
opti_FILTERSD_Install

%% GLPK
opti_GLPK_Install

%% HYBRJ
opti_HYBRJ_Install

%% IPOPT
opti_IPOPT_Install

%% L-BFGS-B
opti_LBFGSB_Install

%% LEVMAR
opti_LEVMAR_Install

%% LMDER
opti_LMDER_Install

%% LP_SOLVE
opti_LPSOLVE_Install

%% M1QN3
opti_M1QN3_Install

%% MKL TR NLS
opti_MKLTRNLS_Install

%% MUMPS
opti_MUMPS_Install

%% NL2SOL
opti_NL2SOL_Install

%% NLOPT
opti_NLOPT_Install

%% NOMAD
opti_NOMAD_Install

%% OOQP
opti_OOQP_Install

%% PSWARM
opti_PSWARM_Install

%% QSOPT
opti_QSOPT_Install

%% SCIP
opti_SCIP_Install


%% -- Utilities --
%% MKL JAC
opti_MKLJAC_Install

%% CoinUtils
opti_COINUTILS_Install

%% AMPL
opti_AMPL_Install