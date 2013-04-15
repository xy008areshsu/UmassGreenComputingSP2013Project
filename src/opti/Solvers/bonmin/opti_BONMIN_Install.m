%% BONMIN Install for OPTI Toolbox
% Copyright (C) 2012 Jonathan Currie (I2C2)

% NOTE BONMIN HAS NOT BEEN UPDATED TO USE CBC v2.7.8 THUS THIS SCRIPT LINKS
% AGAINST CBC v2.7.7 (24/12/12) [BONMIN.mex WILL REPORT USING CBC V2.7.8 FOR NOW]

% NOTE - From OPTI v1.73 BONMIN is now dynamically linked against CPLEX
% v12.5.0. This step is optional, and requires the user to have CPLEX
% installed and licensed on their system, as well as the same version. Two
% mex files will be created, one with Cplex and one without, as Cplex must
% be present to load the Cplex version, even if not used.


% This file will help you compile Basic Open-source Nonlinear Mixed INteger
% programming (BONMIN) for use with MATLAB. 

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010
% - Intel Compiler XE (FORTRAN)
% - Intel Math Kernel Library

% To recompile you will need to get / do the following:

% 0) Complete Compilation as per OPTI instructions for CLP, CBC, MUMPS, and
% IPOPT, in that order.

% 1) Get BONMIN
% BONMIN is available from http://www.coin-or.org/Bonmin/. Download 
% the source. 

% 2) Compile BONMIN
% The latest distribution did not have a Visual Studio solution so I had to
% manually make one. I copied the /bonmin directory structure, and manually
% add all files, and header file locations. There a couple points to
% remember though:
%
%   a) Remove the following cpp and hpp files from the project:
%       - BonCurvatureEstimator
%       - BonCurvBranchingSolver
%   b) In IpTypes.hpp comment the line 
%       - typedef FORTRAN_INTEGER_TYPE ipfint;
%   c) Remove AMPL and Filter folders from the source tree.
%   d) In C/C++ -> Code Generation change the Runtime Library to
%   Multi-threaded DLL (/MD).
%   e) If you want to include CPLEX has a MILP solver you will need to add
%   the following to C++ -> Preprocessor -> Preproccesor Definitions:
%       COIN_HAS_CPX
%   and add the CPLEX include directory (containing cplex.h) to C++ ->
%   General -> Additional Include Directoties.
%   f) Add the following preprocessor definitions (as in step e):
%       _CRT_SECURE_NO_WARNINGS
%   f) Change Configuration Properties -> General -> Whole Program
%   Optimization to No Whole Program Optimization.
%   g) Create a new solution platform for x64 if required, ensure you are
%   building a 'Release', and build the project!
%   h) Copy the generated .lib file to the following folder:
%
%   OPTI/Solvers/bonmin/Source/lib/win32 or win64
%
%   And rename it libBonmin.lib [libBonminCplex.lib with CPLEX]
%
%   Note expect to see a lot of warnings regarding conversion of int to
%   bool. These can be ignored as they are performance only warnings.

% Next we need to copy all the required header files (there are a few!). I
% simply copied all header files from the following folders into an
% equivalent directory structure in OPTI:
%   - Algorithms
%   - Algorithms/OaGenerators
%   - CbcBonmin
%   - Interfaces

% 3) OSI CPLEX Interface
% If you decide to include CPLEX as an MILP solver you will need to also
% build libOsiCplx, which is not included in the CBC MS Visual Studio
% project list. Simple create a new C++ Win32 static library project in
% Visual Studio, then and add OsiCpxSolverInterface.cpp (and .hpp) to it.
% You will need to add the Cplex, Osi/src/Osi and CoinUtils/src directories
% to the additional include directories list. Build the required library 
% (Win32 or x64) and copy to the following folder:
%
%   OPTI/Solvers/bonmin/Source/lib/win32 or win64
%
%   And rename it libOsiCplx.lib

% 4) BONMIN MEX Interface
% The BONMIN MEX Interface is based primarily on Peter Carbonetto's MEX
% Interface to IPOPT, with a few small changes I have made to enable use 
% with BONMIN. Notable changes include changes to the options + extra class
% methods in matlabprogram.

% 5) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the BONMIN MEX file. Once you have completed all 
% the above steps, simply run this file to compile BONMIN! You MUST BE in 
% the base directory of OPTI!

clear bonmin bonminCplex

% Switch to Enable Linking against CPLEX dll
haveCPLEX = true;
% Switch to Enable Linking against MathWorks libmwma57.dll
haveMA57 = true;

% Modify below function if it cannot find Intel MKL on your system.
[mkl_link,mkl_for_link] = opti_FindMKL();
% Get Arch Dependent Library Path
libdir = opti_GetLibPath();
% Dependency Paths
clpdir = '..\..\clp\Source\';
cbcdir = '..\..\cbc\Source\';
mumpsdir = '..\..\mumps\Source\';
ipoptdir = '..\..\ipopt\Source\';

fprintf('\n------------------------------------------------\n');
fprintf('BONMIN MEX FILE INSTALL\n\n');

%Get CBC & CGL Libraries
post = [' -I' cbcdir 'Include\Cbc -I' cbcdir 'Include\Osi -I' cbcdir 'Include\Cgl '];
post = [post ' -L' cbcdir libdir ' -llibCbc277 -llibCgl -llibOsi -llibOsiCbc -llibOsiClp -llibut'];
%Get CLP & COINUTILS libraries
post = [post ' -I' clpdir 'Include -I' clpdir 'Include\Clp -I' clpdir 'Include\Coin'];
post = [post ' -L' clpdir libdir ' -llibClp -llibCoinUtils'];
%Get MUMPS Libraries
post = [post ' -I' mumpsdir '\Include -L' mumpsdir libdir ' -ldmumps_c -ldmumps_fortran -llibseq_c -llibseq_fortran -lmetis -lmumps_common_c -lpord_c'];
%Get Intel Fortran Libraries (for MUMPS build) & MKL Libraries (for BLAS)
post = [post mkl_link mkl_for_link];
%Get IPOPT libraries
post = [post ' -I' ipoptdir 'Include\Common -I' ipoptdir 'Include\Interfaces -I' ipoptdir 'Include\LinAlg'];
if(haveMA57)
    post = [post ' -L' ipoptdir libdir ' -llibIpoptMA57 -llibmwma57 -DhaveMA57'];
else
    post = [post ' -L' ipoptdir libdir ' -llibIpopt'];
end
%Get BONMIN Includes
post = [post ' -IInclude -IInclude/Interfaces -IInclude/CbcBonmin -IInclude/Algorithms -IInclude/Algorithms/OaGenerators']; 
%Output Common
post = [post ' -L' libdir ' -llibbonmin -output bonmin'];

%CD to Source Directory
cdir = cd;
cd 'Solvers/bonmin/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims bonminmex.cpp iterate.cpp options.cpp bonminoptions.cpp matlabinfo.cpp callbackfunctions.cpp matlabexception.cpp matlabfunctionhandle.cpp matlabprogram.cpp matlabjournal.cpp sparsematrix.cpp';
try
    eval([pre post])
    movefile(['bonmin.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:bonmin','Error Compiling BONMIN!\n%s',ME.message);
end

%BUILD CPLEX BONMIN VERSION
if(haveCPLEX)
    % Modify below function it it cannot find IBM ILOG CPLEX on your system
    [CPLX_link] = opti_FindCplex();
    post = [post CPLX_link ' -llibOsiCplx -DHAVE_CPLEX' ];
    % Include BONMIN build with CPLEX
    post = regexprep(post,' -llibbonmin -output bonmin',' -llibbonminCplex -output bonminCplex');
    
    %Compile & Move
    pre = 'mex -v -largeArrayDims bonminmex.cpp iterate.cpp options.cpp bonminoptions.cpp matlabinfo.cpp callbackfunctions.cpp matlabexception.cpp matlabfunctionhandle.cpp matlabprogram.cpp matlabjournal.cpp sparsematrix.cpp';
    try
        eval([pre post])
        movefile(['bonminCplex.' mexext],'../','f')
        fprintf('Done!\n');
    catch ME
        cd(cdir);
        error('opti:bonmin','Error Compiling BONMIN CPLEX Version!\n%s',ME.message);
    end
end

cd(cdir);
fprintf('------------------------------------------------\n');
