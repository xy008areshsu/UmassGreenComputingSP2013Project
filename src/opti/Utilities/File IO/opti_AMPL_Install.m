%% AMPL Install for OPTI Toolbox
% Supplied binaries are built from Netlib's AMPL Solver Library Interface

%   Copyright (C) 2011 Jonathan Currie (I2C2)

% This file will help you compile AMPL Solver Library (ASL) for use with 
% MATLAB.

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010

% The supplied MEX files will require the VC++ 2010 Runtime.

% 1) Get AMPL Solver Library
% The generic NL reader for AMPL is available free from Netlib 
% (http://www.netlib.org/ampl/solvers/). You will need to download all .c
% and .h as well as .hd files. Note this is not the AMPL engine
% (www.ampl.com) which is a commerical product, but code to allow people to
% connect their solvers to AMPL.

% 2) Compile AMPL Solver Library
% I had to make a number of changes to the code in order to compile ASL
% using VS2010. Complete the following steps to compile ASL:
%
%   a) Create a new VS Win32 static library project
%   b) Add .c files listed in makefile.vc to the project
%   c) Remove sprintf.c, and add printf.c
%   d) Add all .h files, plus stdio1.h and arith.h (rename from .h0)
%   e) In arith.h uncomment the define "IEEE_8087"
%   f) Under the above define, add (without quotes) "#define Arith_Kind_ASL 1"
%   g) Comment out the line "AllocConsole()" in stderr.c [line 56]
%   h) Comment out the line "exit(n)" in mainexit.c (this stops MATLAB 
%   crashing on an ASL error) [line 62]
%   i) To prevent Matlab crashing on a bad NL file comment all code under
%   the if(n_con < 0 || ...) statement on line 260 in jac0dim.c. Add return 
%   NULL; so instead of exiting, our MEX file can determine this as a bad file.
%   j) Add the preprocessor definition _CRT_SECURE_NO_WARNINGS
% 	h) Copy the generated library to
%
%   OPTI/Utilities/File IO/Source/lib/win32 or win64
%
%   And rename it to libasl.lib. 
%
%   Also copy all header files to the include directory as per the above
%   path.

% 3) MEX Interface
% The Read MEX Interface is a simple MEX interface I wrote to use the AMPL 
% File IO and Eval routines.

% 4) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the MEX file. Once you have completed all 
% the above steps, simply run this file to compile! You MUST BE in 
% the base directory of OPTI!

clear asl

% Get Arch Dependent Library Path
libdir = opti_GetLibPath();

fprintf('\n------------------------------------------------\n');
fprintf('AMPL MEX FILE INSTALL\n\n');

post = [' -IInclude -L' libdir ' -llibasl -output asl'];

%CD to Source Directory
cdir = cd;
cd 'Utilities/File IO/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims amplmex.c';
try
    eval([pre post])
     movefile(['asl.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:ampl','Error Compiling AMPL!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');
