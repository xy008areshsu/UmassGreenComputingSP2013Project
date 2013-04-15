%% IPOPT Install for OPTI Toolbox
% Copyright (C) 2012 Jonathan Currie (I2C2)

% This file will help you compile Interior Point OPTimizer (IPOPT) for use 
% with MATLAB. 

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010
% - Intel Compiler XE (FORTRAN)
% - Intel Math Kernel Library

% NOTE - From OPTI v1.71 IPOPT is now dynamically linked against the
% MathWorks supplied libmwma57.dll (HSL MA57). This step is optional
% as we are also compiling MUMPS. Alternatively you can skip MUMPS, 
% and just use MA57! Also be aware libmwma57.dll does not play well
% on unconstrained problems due in part to missing MeTiS, thus the 
% ma57 pivot order option is overidden automatically.

% To recompile you will need to get / do the following:

% 1) Get IPOPT
% IPOPT is available from http://www.coin-or.org/download/source/Ipopt/.
% Download the latest version of the source.

% 2) Compile IPOPT
% IPOPT is supplied with projects for VS 10.0 and VS 8.0 with Intel Fortran
% Compiler. However you won't need the Fortran libraries if you use the
% MUMPS solver and Intel MKL - meaning we only have to compile libIpopt.
% From Ipopt/MSVisualStudio/v8-fort open IpOpt-vc10.sln in VS 2010 and 
% complete the following steps to compile libIpopt:
%
%   a) In the solution explorer right click on IpOpt-vc10 and goto
%   Configuration Properties -> C/C++ -> General and in Additional Include
%   Directories add the MUMPS includes (see the help file 
%   opti_MUMPS_Install.m for details on getting MUMPS):
%    - MUMPS_xxx\include
%    - MUMPS_xxx\libseq
%   and unzip OPTI\solvers\ipopt\source\lib\libmwma57.zip and include the 
%   directory (contains the HSL config for MA57).
%   b) Under General change the Configuration Type to:
%       Static Library (.lib)
%   and Whole Program Optimization to:
%       No Whole Program Optimization
%   c) In C/C++ -> Code Generation change the Runtime Library to
%   Multi-threaded DLL (/MD). This step is needed to match the same setting
%   in the MUMPS and METIS libraries (you can't mix them).
%   d) In config.h change line 4 to:
%       #define COIN_HAS_METIS 1
%   and line 7 to:
%       #define COIN_HAS_MUMPS 1
%   and line 9 to:
%       #define COIN_HAS_HSL 1
%   and line 13 to:
%       #undef HAVE_LINEARSOLVERLOADER
%   and line 16 to:
%       #undef HAVE_PARDISO
%   e) Replace the following files found in in Ipopt/src/Algorithm/LinearSolvers:
%    - IpMa57TSolverInterface.cpp
%    - IpMa57TSolverInterface.h
%   with those found from libmwma57.zip (ensure Visual Studio picks up the change)
%   f) If you are building a x64 build add the following preprocessor
%   definition "WIN64" (C/C++ -> Preprocessor -> Preprocessor Definitions)
%   g) Create a new solution platform for x64 if required, ensure you are
%   building a 'Release', and build the project!
%   h) Copy the generated .lib file to the following folder:
%
%   OPTI/Solvers/ipopt/Source/lib/win32 or win64
%
%   And rename it libIpopt.lib.

% Next we need to copy all the required header files (there are a few!).
% From Ipopt/src/Common copy all header files to:
%
%   OPTI/Solvers/ipopt/Source/Include/Common
%
% From Ipopt/src/Interfaces copy all header files to:
%
%   OPTI/Solvers/ipopt/Source/Include/Interfaces
%
% From Ipopt/src/Algorithm copy all header files to:
%
%   OPTI/Solvers/ipopt/Source/Include/Algorithm
%
% From Ipopt/src/LinAlg copy the following header files to:
%
%   OPTI/Solvers/ipopt/Source/Include/LinAlg
%
% All header files from IpMatrix.h to IpZeroMatrix.h.
% Also from Ipopt-xxx/BuildTools/headers copy all header files to:
%
%   OPTI/Solvers/ipopt/Source/Include/BuildTools

% One final change is required to the copied IpTypes.hpp, comment the
% following line (if an error is reported - depends on HSL config):
%   typedef FORTRAN_INTEGER_TYPE ipfint;

% 3) Complete MUMPS Compilation
% Supplied with this toolbox is the MUMPS linear system solver and METIS
% libraries. These are required when linking IPOPT so make sure you have
% built these first! See opti_MUMPS_Install.m in Solvers/mumps for more
% information.

% 4) libmwma57 Compilation
% As MathWorks only supply a dll, I have manually created an import library
% for libmwma57.dll, so we can link against it. The project and source for
% this is included in libmwma57.zip. It is optional to recompile this, as I
% have included compiled libraries for you!

% 5) IPOPT MEX Interface
% Supplied with the IPOPT source is a MEX interface by Dr. Peter Carbonetto.
% This is in Ipopt/contrib/MatlabInterface/src. However I have modified
% parts of this interface, so you must use the version supplied with OPTI.

% 6) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the IPOPT MEX file. Once you have completed all the
% above steps, simply run this file to compile IPOPT! You MUST BE in the 
% base directory of OPTI!

clear ipopt

% Modify below function if it cannot find Intel MKL on your system.
[mkl_link,mkl_for_link] = opti_FindMKL();
% Get Arch Dependent Library Path
libdir = opti_GetLibPath();
% Dependency Paths
mumpsdir = '..\..\mumps\Source\';

% Switch to Enable Linking against MathWorks libmwma57.dll
haveMA57 = true;

fprintf('\n------------------------------------------------\n');
fprintf('IPOPT MEX FILE INSTALL\n\n');

%Get IPOPT Libraries
post = ' -IInclude -IInclude/Common -IInclude/BuildTools -IInclude/Interfaces -IInclude/LinAlg -IInclude/LinAlg/TMatrices -IInclude/Algorithm ';
if(haveMA57)
    post = [post ' -L' libdir ' -llibIpoptMA57 -llibmwma57 -DhaveMA57'];
else
    post = [post ' -L' libdir ' -llibIpopt'];
end
%Get MUMPS Libraries
post = [post ' -I' mumpsdir '\Include -L' mumpsdir libdir '-ldmumps_c -ldmumps_fortran -llibseq_c -llibseq_fortran -lmetis -lmumps_common_c -lpord_c'];
%Get Intel Fortran Libraries (for MUMPS build) & MKL Libraries (for BLAS)
post = [post mkl_link mkl_for_link];

%Common Args
post = [post ' -output ipopt'];   

%CD to Source Directory
cdir = cd;
cd 'Solvers/ipopt/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims matlabexception.cpp matlabfunctionhandle.cpp matlabjournal.cpp iterate.cpp ipoptoptions.cpp options.cpp sparsematrix.cpp callbackfunctions.cpp matlabinfo.cpp matlabprogram.cpp ipopt.cpp';
try
    eval([pre post])
    movefile(['ipopt.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:ipopt','Error Compiling IPOPT!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');