%% CBC Install for OPTI Toolbox
% Copyright (C) 2012 Jonathan Currie (I2C2)

% This file will help you compile Coin-Or Branch and Cut for use with 
% MATLAB. 

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010

% To recompile you will need to get / do the following:

% 1) Get CBC
% CBC is available from https://projects.coin-or.org/Cbc. Download 
% the source.

% 2) Compile CBC
% The supplied VS solution worked fine for me. Open Cbc.sln in 
% /Cbc/MSVisualStudio/v10, then:
% a - Remove "virtual" from line 1844 in CbcModel.hpp
% b - build the required libs (win32 or x64), 
% ensuring you build a release! Copy the generated .lib files to the following 
% folder:
%
%   OPTI/Solvers/cbc/Source/lib/win32 or win64
%
%   - libCbc.lib
%   - libCgl.lib
%   - libOsi.lib
%   - libOsiCbc.lib
%   - libOsiClp.lib
%
%   You will also need to copy the required header files from Cbc/src to 
%   the following folder:
%
%   OPTI/Solvers/cbc/Source/Include/Cbc
%
%   Also copy the CGL header files from Cgl/src (+ few subfolders) to the 
%   following folder:
%
%   OPTI/Solvers/cbc/Source/Include/Cgl

%   Finally copy the OSI header files from Osi/src/Osi to the
%   following folder:
%
%   OPTI/Solvers/cbc/Source/Include/Osi

% 3) CBC MEX Interface
% The CBC MEX Interface is a simple MEX interface I wrote to use CBC.

% 4) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the CBC MEX file. Once you have completed all 
% the above steps, simply run this file to compile CBC! You MUST BE in 
% the base directory of OPTI!

clear cbc

% Get Arch Dependent Library Path
libdir = opti_GetLibPath();
% Dependency Paths
clpdir = '..\..\clp\Source\';

fprintf('\n------------------------------------------------\n');
fprintf('CBC MEX FILE INSTALL\n\n');

%Get CBC Libraries
post = [' -IInclude\Cbc -IInclude\Osi -IInclude\Cgl -L' libdir ' -llibCbc -llibCgl -llibOsi -llibOsiCbc -llibOsiClp -llibut'];
%Get CLP libraries
post = [post ' -I' clpdir 'Include -I' clpdir 'Include\Clp -I' clpdir 'Include\Coin'];
post = [post ' -L' clpdir libdir ' -llibClp -llibCoinUtils -DCOIN_MSVS -output cbc'];

%CD to Source Directory
cdir = cd;
cd 'Solvers/cbc/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims cbcmex.cpp';
try
    eval([pre post])
    movefile(['cbc.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:clp','Error Compiling CBC!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');
