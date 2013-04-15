%% LEVMAR Install for OPTI Toolbox
% Copyright (C) 2012 Jonathan Currie (I2C2)

% This file will help you compile Levenberg-Marquardt in C/C++ (LEVMAR) for 
% use with MATLAB. 

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010
% - Intel Math Kernel Library

% To recompile you will need to get / do the following:

% 1) Get LEVMAR
% LEVMAR is available from http://www.ics.forth.gr/~lourakis/levmar/. We 
% will create the VS project below.

% 2) Compile LEVMAR
% LEVMAR does not come with a VS studio solution so we will need to create
% one from scratch. Follow the instructions below:
%
%   a) Create a new VS2010 VC++ Win32 project, select Static Library and no
%   precompiled header.
%   b) From VS right click Source Files and goto Add -> Existing Item, and
%   select all .c and .h LEVMAR files EXCEPT the following
%       - any files ending in _core (these are implicitly included)
%       - expfit.c
%   c) Create a new solution platform for x64 if required, ensure you are
%   building a 'Release', and build the project!
%   d) Copy the generated .lib file to the following folder:
%
%   OPTI/Solvers/levmar/Source/lib/win32 or win64
%
%   And rename it to liblevmar.lib
%
%   Also copy levmar.h to:
%
%   OPTI/Solvers/levmar/Source/Include

% 3) MEX Interface
% I have heavily modified the levmar supplied MEX interface thus I suggest
% you use my version, levmarmex.c, included as part of this distribution.
% This will also maintain compatibility with OPTI.

% 4) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the LEVMAR MEX file. Once you have completed all the
% above steps, simply run this file to compile LEVMAR! You MUST BE in the 
% base directory of OPTI!

clear levmar

% Modify below function if it cannot find Intel MKL on your system.
mkl_link = opti_FindMKL();
% Get Arch Dependent Library Path
libdir = opti_GetLibPath();

fprintf('\n------------------------------------------------\n');
fprintf('LEVMAR MEX FILE INSTALL\n\n');

%Get LEVMAR Libraries
post = [' -IInclude -L' libdir ' -lliblevmar'];
%Get MKL Libraries (for BLAS & LAPACK)
post = [post mkl_link];
%Common outputs
post = [post ' -output levmar'];

%CD to Source Directory
cdir = cd;
cd 'Solvers/levmar/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims levmarmex.c';
try
    eval([pre post])
    movefile(['levmar.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:levmar','Error Compiling LEVMAR!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');
