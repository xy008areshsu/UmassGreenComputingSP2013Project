%% SCIP Install for OPTI Toolbox
% Copyright (C) 2012 Jonathan Currie (I2C2)

% This file will help you compile Solving Constraint Integer Programs (SCIP) 
% for use with MATLAB. 

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010
% - Intel Compiler XE (FORTRAN)
% - Intel Math Kernel Library

% To recompile you will need to get / do the following:

% 0) Complete Compilation as per OPTI instructions for CLP, CBC, MUMPS, and
% IPOPT, in that order.

% 1) Get SCIP & SoPlex
% SCIP is available from http://scip.zib.de/. Ensure you download the SCIP
% optimization suite, which includes SoPlex. We will create the VS projects 
% below.

% 2) Compile SoPlex
% SoPlex does not come with a Visual Studio project, so we will have to
% build one from scratch. Complete the following steps:
%
%   a) Create a new VS2010 VC++ Win32 project, select Static Library and no
%   precompiled header.
%   b) Right click the project in the solution explorer and click Add ->
%   Existing Item. Select all .cpp and .h files in the soplex-xxx/src
%   folder.
%   c) Right click the project in the solution explorer and click
%   Properties. Navigate to C/C++ -> Preprocessor and under Preprocessor 
%   Definitions add _CRT_SECURE_NO_WARNINGS.
%   d) The generated .lib can be quite large if you leave global
%   optimization on, so under General -> Whole Program Optimization you may
%   like to switch this to No Whole Program Optimization.
%   e) Create a new solution platform for x64 if required, ensure you are
%   building a 'Release', and build the project!
%   f) Copy the generated .lib file to the following folder:
%
%   OPTI/Solvers/scip/Source/lib/win32 or win64
%
%   And rename it to libsoplex.lib.
%
%   Next we need to copy the required header files. Copy spxdefines.h to 
%
%   OPTI/Solvers/scip/Source/Include 

% 2) Compile SCIP
% As with SoPlex, SCIP does not come with a Visual Studio Project, so we
% will build one from scratch. The easiest way to do this is to use the
% 'Visual Studio Project Builder', supplied with OPTI. This routine
% automatically creates a VS2010 project based on the directory structure
% in the solver. Complete the following steps:
%
%   a) Using the VS Builder call the following function in MATLAB
%         VS_WriteProj(sdir,'libscip')
%      where sdir is the full path to the scip-xxx/src/ directory.
%   b) Open the generated VS project located in scip-xxx/libscip.
%   c) Not all source files are required, so we are going to remove the
%   ones we don't need. Remove all the source files listed below from the
%   project:
%       - nlpi/exprinterpret_none.cpp
%       - nlpi_ipopt_dummy.c
%       - nlpi/nlpi_xyz.cpp
%       - scip/lpi_none.c
%       - scip/lpi_clp.cpp
%       - scip/lpi_cpx.cpp
%       - scip/lpi_grb.cpp
%       - scip/lpi_msk.cpp
%       - scip/lpi_qso.cpp
%       - scip/lpi_spx121.cpp
%       - scip/lpi_spx132.cpp
%       - scip/lpi_xprs.cpp
%       - scip/sorttpl.c
%   c2) Versions including and prior to 3.0.1 require line 2905 in
%   cons_soc.c to be changed to "if( lhscount >= nquadvars - 1 )"
%   d) Right click the project in the solution explorer and click
%   Properties. Navigatee to C/C++ -> Preprocessor and under Preprocessor
%   Definitions add the following:
%       - NO_RAND_R
%       - NO_SIGACTION
%       - NO_STRERROR_R
%       - NO_STRTOK_R
%       - _CRT_SECURE_NO_WARNINGS
%       - NO_NEXTAFTER  (ONLY if building an x64 build)
%       - ROUNDING_MS
%       - NPARASCIP
%   e) Navigate to C/C++ -> Advanced and under Compile As select Compile as
%   C++ Code (/TP)
%   f) Navigate to C/C++ -> General and under Additional Include
%   Directories add the following directories:
%       - soplex-xxx/src    [SOPLEX]
%       - src/LingAlg       [IPOPT]
%       - src/Algorithm     [IPOPT]
%       - src/Interfaces    [IPOPT]
%       - src/Common        [IPOPT]
%       - CppAD-xxxx        [CppAD top directory]
%   f2) You may need to run CMake over the CppAD directory to generate the
%   required configure.hpp file.
%   g) In IpTypes.hpp (IPOPT\src\common\) comment out the following line:
%       typedef FORTRAN_INTEGER_TYPE ipfint;
%   h) The generated .lib can be quite large if you leave global
%   optimization on, so under General -> Whole Program Optimization you may
%   like to switch this to No Whole Program Optimization.
%   i) Due to the way we have created the project the header files cannot
%   be found. Perform a find and replace on the CURRENT PROJECT of the
%   following terms:
%       - FIND #include "tclique/       REPLACE #include "../tclique/
%       - FIND #include "blockmemshell/ REPLACE #include "../blockmemshell/
%       - FIND #include <blockmemshell/ REPLACE #include <../blockmemshell/
%       - FIND #include "scip/          REPLACE #include "../scip/
%       - FIND #include "nlpi/          REPLACE #include "../nlpi/
%       - FIND #include "objscip/       REPLACE #include "../objscip/
%       - FIND #include "xml/           REPLACE #include "../xml/
%       - FIND #include "dijkstra/      REPLACE #include "../dijkstra/
%   j) Create a new solution platform for x64 if required, ensure you are
%   building a 'Release', and build the project!
%   k) Copy the generated .lib file to the following folder:
%
%   OPTI/Solvers/scip/Source/lib/win32 or win64
%
%   And rename it to libscip.lib.

% Next we need to copy all the required header files. Copy the header files
% (and folders) of the following folders:
%   - blockmemshell
%   - nlpi
%   - objscip
%   - scip
%   - cppad (just configure.hpp)
% to 
%
%   OPTI/Solvers/scip/Source/Include

% 4) MEX Interface
% The MEX interface supplied with SCIP (at the time of this development)
% was quite basic, thus has been updated for use with OPTI. Therefore I
% suggest you use the version supplied with OPTI.

% 5) ASL Interface
% If you wish to be able to solve AMPL .nl models using this interface, you
% can enable this functionality below with "haveASL". However you will need
% to complete building the ASL library, as detailed in Utilities/File
% IO/opti_AMPL_Install.m. Also ensure reader_nl.c and .h are placed in
% scip/Source/AMPL/. Note a bug exists in v3.0.1, so ensure the latest
% release is used.

% 6) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the SCIP MEX file. Once you have completed all the
% above steps, simply run this file to compile SCIP! You MUST BE in the 
% base directory of OPTI!

clear scip

% Modify below function if it cannot find Intel MKL on your system.
[mkl_link,mkl_for_link] = opti_FindMKL();
% Get Arch Dependent Library Path
libdir = opti_GetLibPath();
% Dependency Paths
ipoptdir = '..\..\ipopt\Source\';
mumpsdir = '..\..\mumps\Source\';
asldir = '..\..\..\Utilities\File IO\Source\';

% Switch to Enable Linking against MathWorks libmwma57.dll
haveMA57 = true;
% Switch to Enable AMPL ASL linking
haveASL = true;

fprintf('\n------------------------------------------------\n');
fprintf('SCIP MEX FILE INSTALL\n\n');
   
%Get IPOPT Libraries
if(haveMA57)
    post = [' -IInclude -I..\..\ipopt\Source\Include\Common\ -L' ipoptdir libdir ' -llibIpoptMA57 -llibmwma57']; 
else
    post = [' -IInclude -I..\..\ipopt\Source\Include\Common\ -L' ipoptdir libdir ' -llibIpopt']; 
end
%Get ASL libraries
if(haveASL)
   post = [post ' -I"' asldir 'Include" -L"' asldir libdir(1:end-1) '" -llibasl -DHAVE_ASL'];
end
%Get MUMPS Libraries
post = [post ' -I' mumpsdir 'Include -L' mumpsdir libdir '-ldmumps_c -ldmumps_fortran -llibseq_c -llibseq_fortran -lmetis -lmumps_common_c -lpord_c'];
%Get Intel Fortran Libraries (for MUMPS build) & MKL Libraries (for BLAS)
post = [post mkl_link mkl_for_link];
%Get SCIP Includes and Libraries
post = [post ' -IInclude -IInclude/nlpi -IInclude/blockmemshell -L' libdir ' -llibscip -llibsoplex -llibut -output scip'];
   
%CD to Source Directory
cdir = cd;
cd 'Solvers/scip/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims scipmex.cpp scipeventmex.cpp scipnlmex.cpp';
if(haveASL)
    pre = [pre ' AMPL/reader_nl.c']; %include Stefan's ASL reader   
end
try
    eval([pre post])
    movefile(['scip.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:scip','Error Compiling SCIP!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');
