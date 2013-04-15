%% GLPK Install for OPTI Toolbox
% Copyright (C) 2012 Jonathan Currie (I2C2)

% This file will help you compile GNU Linear Programming Kit (GLPK) for use 
% with MATLAB. 

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010

% To recompile you will need to get / do the following:

% 1) Get GLPK
% GLPK is available from http://www.gnu.org/software/glpk/glpk.html. We 
% will create VS projects below.

% 2) Compile GLPK
% While GLPK comes with batch files to compile GLPK, I found problems when
% trying to compile win32 on x64, thus I created my own VS solution. This
% is easy, just follow the steps below:
%
%   a) Create a new VS2010 VC++ Win32 project, select Static Library and no
%   precompiled header.
%   b) From glpk-xxx/src copy all .c and .h files into the VS project
%   directory (containing the solution file).
%   c) From glpk-xxx/src copy the folders amd and colamd to the VS project
%   directory.
%   d) From VS right click Source Files and goto Add -> Existing Item, and
%   select all .c and .h GLPK files.
%   e) Repeat the above for all .c and .h files in /amd, /colamd, /zlib and
%   /minisat.
%   f) Right click the project in the solution explorer, and click
%   properties. Navigate to Configuration Properties -> C/C++ -> General
%   and under Additional Include Directories add the project directory.
%   g) Navigate to C/C++ -> Preprocessor and under Preprocessor Definitions
%   add _CRT_SECURE_NO_WARNINGS.
%   h) Change lines 28 and 29 in glpmat.c to remove the folders from the
%   paths. e.g. amd/amd.h to amd.h. Do the same in glpapi19.c line 26, and
%   glpenv07.c line 547.
%   i) Create a new solution platform for x64 if required, ensure you are
%   building a 'Release', and build the project!
%   j) Copy the generated .lib file to the following folder:
%
%   OPTI/Solvers/glpk/Source/lib/win32 or win64
%
%   And rename it to glpk.lib
%
%   Also copy glpk.h from glpk-xxx/include to:
%
%   OPTI/Solvers/glpk/Source/Include

% 3) Get GLPKMEX
% GLPKMEX is a MEX interface to GLPK by Nicolo Giorgetti, and is used
% within OPTI to interface to GLPK. It is available from
% http://glpkmex.sourceforge.net/. Unzip the source files and copy
% glpkcc.cpp to:
%
%   OPTI/Solvers/glpk/Source

% Note I have made the following changes to the GLPKMEX file in the 
% supplied version:
% - Added Ctrl-C detection within print handler
% - Added drawnow to enable iteration by iteration printing
% - Changed the internal function description to be called 'glpk'

% 4) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the GLPK MEX file. Once you have completed all the
% above steps, simply run this file to compile GLPK! You MUST BE in the 
% base directory of OPTI!

clear glpk

% Get Arch Dependent Library Path
libdir = opti_GetLibPath();

fprintf('\n------------------------------------------------\n');
fprintf('GLPK MEX FILE INSTALL\n\n');

%Get GLPK Libraries
post = [' -IInclude -L' libdir ' -lglpk -llibut -output glpk'];

%CD to Source Directory
cdir = cd;
cd 'Solvers/glpk/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims glpkcc.cpp';
try
    eval([pre post])
    movefile(['glpk.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:glpk','Error Compiling GLPK!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');



