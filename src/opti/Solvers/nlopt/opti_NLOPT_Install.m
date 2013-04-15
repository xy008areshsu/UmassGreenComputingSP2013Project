%% NLOPT Install for OPTI Toolbox
% Copyright (C) 2012 Jonathan Currie (I2C2)

% This file will help you compile NonLinear OPTimization (NLOPT) for use 
% with MATLAB. 

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010

% To recompile you will need to get / do the following:

% 1) Get NLOPT
% NLOPT is available from http://ab-initio.mit.edu/wiki/index.php/NLopt. 
% Download the source.

% 2) Compile NLOPT
% NLOPT does not come with a VS studio solution so we will need to create
% one from scratch. Follow the instructions below:
%
%   a) Create a new VS2010 VC++ Win32 project, select Static Library and no
%   precompiled header.
%   b) From nlopt-xxx/* we will copy all .c, .cpp, .h and .hpp files into
%   the VS project directory. This will save us having to add all the
%   include directories, etc. Note you do not need the files from
%   nlopt-xxx/octave.
%   c) From VS right click Source Files and goto Add -> Existing Item, and
%   select all .c, .cpp and .h files APART FROM the following:
%       - tst.cpp
%       - testros.cpp
%       - testfun.h
%       - redblack_test.c
%       - DIRparallel.c (didn't seem to compile...)
%   d) A default config.h has not been supplied (and I'm guessing only gets
%   made in Linux versions) so I've made one up based on the template. Copy
%   the supplied config.h from:
%       OPTI/Solvers/nlopt/Source/Include
%   To the project directory.
%   e) The solver ISRES.c uses the math function 'sqrt' but the compiler
%   cannot determine which overloaded version to use. For each line below,
%   type cast the integer n to double (i.e. (double)n ):
%       - 92, 93, 119, 235, 261
%   e) Right click the project in the solution explorer, and click
%   properties. Navigate to Configuration Properties -> C/C++ -> General
%   and under Additional Include Directories add the project directory.
%   f) Navigate to C/C++ -> Code Generation and under Runtime Library 
%   select Multi-threaded DLL (/MD).
%   g) Navigate to C/C++ -> Advanced and under Compile As change to
%   "Compile as C++ Code (/TP)". This is required as the file extension is
%   .c, but we are compiling C++ code.
%   h) If you enable Whole Program Optimization (C/C++ -> Optimization)
%   nlopt.lib takes a LONG time to link, so if you are making frequent 
%   changes to the MEX interface consider specifying Whole Program 
%   Optimization as No.
%   i) Create a new solution platform for x64 if required, ensure you are
%   building a 'Release', and build the project!
%   j) Rename the generated .lib to libnlopt.lib and copy to the following 
%   folder:
%
%   OPTI/Solvers/nlopt/Source/lib/win32 or win64
%
%   You will also need to copy the required header file, nlopt.h, from
%   nlopt-xxx/api to the following folder:
%
%   OPTI/Solvers/nlopt/Source/Include

% 3) NLOPT MEX Interface
% The NLOPT MEX Interface was written by Steven Johnson and is located in
% the octave folder (nlopt_optimize-mex.c) HOWEVER in its original form it
% was not compatible with OPTI (due to the method of adding nonlinear
% constraints cell by cell), as well as the file name caused compile
% problems (no '-' allowed for MEX). Therefore I have modified the
% MEX interface and included is nlopt_optimize_mex.c which you will need to
% use for compatibility with OPTI. You will need to however copy
% nlopt_optimize_usage.h from nlopt-xxx/octave to:
%
%   OPTI/Solvers/nlopt/Source/Include

% 4) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the NLOPT MEX file. Once you have completed all 
% the above steps, simply run this file to compile NLOPT! You MUST BE in 
% the base directory of OPTI!

clear nlopt

% Get Arch Dependent Library Path
libdir = opti_GetLibPath();

fprintf('\n------------------------------------------------\n');
fprintf('NLOPT MEX FILE INSTALL\n\n');

%Get NLOPT Libraries
post = [' -IInclude -L' libdir ' -llibnlopt -llibut -output nlopt'];

%CD to Source Directory
cdir = cd;
cd 'Solvers/nlopt/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims nloptmex.c';
try
    eval([pre post])
    movefile(['nlopt.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:nlopt','Error Compiling NLOPT!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');
