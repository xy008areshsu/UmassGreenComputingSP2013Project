%% QSOPT Install for OPTI Toolbox
% Copyright (C) 2012 Jonathan Currie (I2C2)

% This file will help you compile QSOPT for use with MATLAB. 

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010

% To recompile you will need to get / do the following:


% 1) Get QSOPT
% QSOPT is currently a closed source project so you may not be able to
% obtain the source. If you do, instructions are below how to create a VS
% project. Note this is a complex task as the source is not setup for MSVS.
% Check http://www2.isye.gatech.edu/~wcook/qsopt/ for project information.

% 2) Compile QSOPT
% As stated above this is a complex task, and I may not have remembered all
% steps I undertook to compile QSOPT! However follow along and see how it
% goes:
%
%   a) Create a new VS2010 VC++ Win32 project, select Static Library and no
%   precompiled header.
%   b) From qsopt and qsopt/iqsutil copy all .c and .h files into the VS 
%   project directory (containing the solution file).
%   c) From VS right click Source Files and goto Add -> Existing Item, and
%   select all .c and .h QSOPT files apart from:
%       - ftest.c
%       - group.c
%   d) Right click the project in the solution explorer, and click
%   properties. Navigate to Configuration Properties -> C/C++ -> General
%   and under Additional Include Directories add the project directory.
%   e) Navigate to C/C++ -> Preprocessor and under Preprocessor Definitions
%   add _CRT_SECURE_NO_WARNINGS.
%   f) Navigate to C/C++ -> Advanced and under Compile As change to
%   "Compile as C++ Code (/TP)". This is required as the file extension is
%   .c, but we are compiling C++ code (not strictly correct... although the
%   library uses function overloading..?).
%   g) In qsopt.h on line 12 replace it with (we are building a static lib):
%       #define QSLIB_INTERFACE 

%   You might like to try a compile now to see the errors we are now going
%   to fix (there are a few)

%   h) In symtab.h the C++ keyword 'namespace' has been used as a field in 
%   the structure on line 20. This is also used widely through symtab.c.
%   Best to do a find and replace and change it to 'nameSpace'.
%   i) In symtab.c the C++ keyword 'new' has been used as a variable on
%   line 525. Do another find and replace to change it to 'New'.
%   j) In rawlp.h the C++ keyword 'this' has been used as a field in the
%   structure on line 89. This is also widely used through rawlp.h, as well
%   as in another structure in presolve.c on line 68 and this file as well.
%   Best to do another find and replace to change it to 'index'.
%   k) In lpdata.c on line 421 cast the lp->reporter.dest object to (FILE*)
%   l) In priority.c the unions on lines 86, 101, 109 are all missing the
%   type name. Change them to 'ILLpriority::ILLpri_data'.
%   m) In iqsutil.h on line 843 the return type of void* does not work when
%   supplied a char* pointer. As this is always the case, cast the return
%   pointer to (char*).
%   n) In mps.c on lines 165, 172 and 204 the enum sec should be cast to
%   its data type, e.g. (ILLmps_section)sec.
%   o) In write_lp.c on line 91, the sprintf command with %n is no longer
%   valid. Instead change to 'len = sprintf(line->p, "%g", v);'.
%   p) In pivot.c on line 181 the define 'PRICE_DSTEEP1' is unknown. I have
%   guessed this should be QS_PRICE_DSTEEP, so change accordingly.
%   q) In pivot.c on line 212 the function is missing the second argument.
%   I have guessed this should be the tolerance, so change to
%   'ILLfct_dphaseI_simple_update (lp, lp->tol->dfeas_tol);'.
%   r) In pivot.c on lines 202, 204 and 213 the functions all return an
%   argument called rval, however these functions are defined as returning
%   void. Once again guessing here, delete the return values on all the
%   above lines, and comment the ILL_CLEANUP_IF lines on 203 and 205. 

%   And that should be all the errors! If not you may have to go hunting as
%   I did...

%   s) Create a new solution platform for x64 if required, ensure you are
%   building a 'Release', and build the project!
%   t) Copy the generated .lib file to the following folder:
%
%   OPTI/Solvers/qsopt/Source/lib/win32 or win64
%
%   And rename it to QSopt.lib
%
%   Also copy qsopt.h from qsopt/ to:
%
%   OPTI/Solvers/qsopt/Source/Include

% 3) QSOPT MEX Interface
% The QSOPT MEX Interface is a simple MEX interface I wrote to use QSOPT.

% 4) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the QSOPT MEX file. Once you have completed all 
% the above steps, simply run this file to compile QSOPT! You MUST BE in 
% the base directory of OPTI!

clear qsopt

% Get Arch Dependent Library Path
libdir = opti_GetLibPath();

fprintf('\n------------------------------------------------\n');
fprintf('QSOPT MEX FILE INSTALL\n\n');

%Get QSOPT Libraries
post = [' -IInclude -L' libdir ' -lQSopt -output qsopt'];

%CD to Source Directory
cdir = cd;
cd 'Solvers/qsopt/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims qsoptmex.cpp';
try
    eval([pre post])
    movefile(['qsopt.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:qsopt','Error Compiling QSOPT!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');



