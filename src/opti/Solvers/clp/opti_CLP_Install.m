%% CLP Install for OPTI Toolbox
% Copyright (C) 2012 Jonathan Currie (I2C2)

% This file will help you compile Coin-Or Linear Programming for use with 
% MATLAB. 

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010

% The supplied MEX files will require the VC++ 2010 Runtime.


% To recompile you will need to get / do the following:

% 1) Get CLP
% CLP is available from http://www.coin-or.org/projects/Clp.xml. Download 
% the source.

% 2) Compile CLP & COIN Utils
% The supplied VS solution worked fine for me. Open Clp.sln in 
% /Clp/MSVisualStudio/v10 and build the required libs (win32 or x64), 
% ensuring you build a release! Copy the generated .lib files to the 
% following folder:
%
%   OPTI/Solvers/clp/Source/lib/win32 or win64
%
%   - libClp.lib
%   - libCoinUtils.lib
%
%   You will also need to copy the required header files from Clp/src to 
%   the following folder:
%
%   OPTI/Solvers/clp/Source/Include/Clp
%
%   All header files starting with 'Clp' (excluding Clp_C_Interface.hpp) +
%   config_clp_default.h

%   Also copy the COIN header files from CoinUtils/src to the following
%   folder:
%
%   OPTI/Solvers/clp/Source/Include/Coin
%
%   All header files including config_coinutils_default.h

%   Finally copy the config header files from BuildTools/headers to the
%   following folder:
%
%   OPTI/Solvers/clp/Source/Include

% 3) CLP MEX Interface
% The CLP MEX Interface is a simple MEX interface I wrote to use CLP.

% 4) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the CLP MEX file. Once you have completed all 
% the above steps, simply run this file to compile CLP! You MUST BE in 
% the base directory of OPTI!

clear clp

% Get Arch Dependent Library Path
libdir = opti_GetLibPath();

fprintf('\n------------------------------------------------\n');
fprintf('CLP MEX FILE INSTALL\n\n');

%Get CLP Libraries
post = [' -IInclude -IInclude/Clp -IInclude/Coin -L' libdir ' -llibClp -llibCoinUtils -llibut -DCOIN_MSVS -output clp'];

%CD to Source Directory
cdir = cd;
cd 'Solvers/clp/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims clpmex.cpp';
try
    eval([pre post])
     movefile(['clp.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:clp','Error Compiling CLP!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');
