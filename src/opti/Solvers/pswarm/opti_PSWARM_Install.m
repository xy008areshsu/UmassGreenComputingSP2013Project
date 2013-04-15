%% PSWARM Install for OPTI Toolbox
% Copyright (C) 2012 Jonathan Currie (I2C2)

% This file will help you compile PSwarm for use with MATLAB. 

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010
% - Intel Math Kernel Library

% To recompile you will need to get / do the following:

% 1) Get PSwarm
% PSwarm is available from http://www.norg.uminho.pt/aivaz/pswarm/. 
% Download PPSwarm_vxx.zip (C Version) and unzip to a suitable location.

% 2) Compile PSwarm
% The download contains multiple C files, however we will only be using a
% few to compile a static library. Note while the download includes a VS
% makefile, I have opted to build my own project:
%   a) Create a new VS2010 VC++ Win32 project, select Static Library and no
%   precompiled header.
%   b) From VS right click Source Files and goto Add -> Existing Item, and
%   add the following files from PPSwarm_vxxx/:
%       - mve_presolve.c
%       - mve_solver.c
%       - pattern.c
%       - pswarm.c
%   c) Right click the project in the solution explorer, and click
%   properties. Navigate to Configuration Properties -> C/C++ -> General
%   and under Additional Include Directories add the PPSwarm_vxx directory.
%   d) Navigate to C/C++ -> Preprocessor and under Preprocessor Definitions
%   add _CRT_SECURE_NO_WARNINGS and LINEAR.
%   d) A couple code changes are required in order to interface with OPTI:
%       - In pswarm.h add "int solveriters;" to the Stats structure on line
%         55.
%       - In pswarm.h change the define on line 62 to 
%         "#define SYS_RANDOM 1"
%       - In pswarm.c on line 666 add "stats.solveriters = iter;"
%   e) Create a new solution platform for x64 if required, ensure you are
%   building a 'Release', and build the project!
%   f) Copy the generated .lib file to the following folder:
%
%   OPTI/Solvers/pswarm/Source/lib/win32 or win64
%
%   And rename it to libpswarm.lib. 
%
%   g) Copy pswarm.h to the following folder:
%
%   OPTI/Solvers/pswarm/Source/Include

% 3) PSwarm MEX Interface
% The PSwarm MEX Interface is a simple MEX interface I wrote to use PSwarm. 

% 4) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the PSwarm MEX file. Once you have completed all the
% above steps, simply run this file to compile PSwarm! You MUST BE in the 
% base directory of OPTI!

clear pswarm

% Modify below function if it cannot find Intel MKL on your system.
mkl_link = opti_FindMKL();
% Get Arch Dependent Library Path
libdir = opti_GetLibPath();

fprintf('\n------------------------------------------------\n');
fprintf('PSwarm MEX FILE INSTALL\n\n');

%Get PSwarm Libraries
post = [' -IInclude -L' libdir ' -llibpswarm -llibut -output pswarm'];
%Get MKL Libraries (for BLAS)
post = [post mkl_link];

%CD to Source Directory
cdir = cd;
cd 'Solvers/pswarm/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims pswarmmex.c';
try
    eval([pre post])
    movefile(['pswarm.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:pswarm','Error Compiling PSwarm!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');