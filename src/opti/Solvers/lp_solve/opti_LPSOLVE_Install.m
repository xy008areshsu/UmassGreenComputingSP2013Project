%% LP_SOLVE Install for OPTI Toolbox
% Copyright (C) 2012 Jonathan Currie (I2C2)

% This file will help you compile LP_SOLVE for use with MATLAB. 

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010

% To recompile you will need to get / do the following:

% 1) Get LP_SOLVE
% LP_SOLVE is available from
% http://sourceforge.net/projects/lpsolve/files/lpsolve/. Download the
% source (lp_solve_5.5.2.0_source.tar.gz) or later version.

% 2) Compile LP_SOLVE
% The supplied VS solution worked fine for me and only required upgrading
% to VS 2010. Open lib.sln in /lpsolve55, complete the project upgrade, and
% build the required lib (win32 or x64), ensuring you build a release! Copy
% the generated .lib file to the following folder:
%
%   OPTI/Solvers/lp_solve/Source/lib/win32 or win64
%
%   You will also need to copy the required header files from lp_solve_x.x
%   to the following folder:
%
%   OPTI/Solvers/lp_solve/Source/Include
%
%   - lp_Hash.h
%   - lp_lib.h
%   - lp_matrix.h
%   - lp_mipbb.h
%   - lp_SOS.h
%   - lp_types.h
%   - lp_utils.h

% 3) Get LP_SOLVE MEX Interface
% The LP_SOLVE MEX interface is available from the above link and is
% written by Peter Notebaert. Download the source
% (lp_solve_5.5.2.0_MATLAB_source.tar.gz) or later version. Copy the
% source files to the following folder:
%
%   OPTI/Solvers/lp_solve/Source
%
%   - lpsolve.c
%   - matlab.c

% Copy the header files to the following folder:
%
%   OPTI/Solvers/lp_solve/Source/Include
%
%   - lpsolvecaller.h
%   - matlab.h
%
% Note you DO NOT NEED the hash files or lp_explicit header.

% Make one change to matlab.h on line 12 to:
%
%   #if 1 (original = #if 0)
%
% Which will enable static linking (appears disabled by default)

% 4) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the LP_SOLVE MEX file. Once you have completed all 
% the above steps, simply run this file to compile LP_SOLVE! You MUST BE in 
% the base directory of OPTI!

clear lp_solve

% Get Arch Dependent Library Path
libdir = opti_GetLibPath();

fprintf('\n------------------------------------------------\n');
fprintf('LP_SOLVE MEX FILE INSTALL\n\n');

%Get LP_SOLVE Libraries
post = [' -IInclude -L' libdir ' -lliblpsolve55 -DMATLAB -DWIN32 -DLPSOLVEAPIFROMLIB -output lp_solve'];

%CD to Source Directory
cdir = cd;
cd 'Solvers/lp_solve/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims lpsolve.c matlab.c';
try
    eval([pre post])
    movefile(['lp_solve.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:lpsolve','Error Compiling LP_SOLVE!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');