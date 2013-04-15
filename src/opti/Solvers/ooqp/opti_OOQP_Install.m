%% OOQP Install for OPTI Toolbox
% Copyright (C) 2012 Jonathan Currie (I2C2)

% This file will help you compile Objective Orientated Quadratic
% Programming (OOQP) for use with MATLAB. 

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010
% - Intel Compiler XE (FORTRAN)
% - Intel Math Kernel Library

% To recompile you will need to get / do the following:

% 1) Get OOQP
% OOQP is available from http://pages.cs.wisc.edu/~swright/ooqp/. You will 
% need to register before you can download. We will create the VS project 
% below.

% 2) Compile OOQP
% I am not 100% sure on what files are and aren't required, so the best
% idea is to compile everything, then when we link the MEX file, it will
% only copy the required code! OOQP did not appear to come with Visual
% Studio projects, so we will have to build one from scratch. Complete the
% following steps:
%
%   a) Create a new VS2010 VC++ Win32 project, select Static Library and no
%   precompiled header.
%   b) From OOQP-xxx/src/* we will copy all .c and .h files into the VS 
%   project directory. This will save having to add all the include
%   directories, etc. Note you do not need the files in src/Ampl/,
%   src/PetscLinearAlgebra/, src/QpExample/, src/LinearSolvers/Ma57Solver/
%   and src/Mex/.
%   c) From VS right click Source Files and goto Add -> Existing Item, and
%   select all .c and .h files APART FROM the following:
%       - QpGenSparseOblio.c
%       - QpGenSparseSuperLu.c
%       - All files with "Driver" in them, e.g. HuberGondzioDriver.c
%       - All files with "Petsc" in them, e.g. cQpBoundPetsc.c
%   d1) If you are going to compile with MA27 and Intel Fortran you
%   will need to rename the MA27 function calls. Open Ma27Solver.h and on
%   lines 16, 18, 26, and 35 rename the ma27 function calls as below:
%       - ma27id_  becomes  MA27ID
%       - ma27ad_  becomes  MA27AD, and so forth for ma27bd_ and ma27cd_.
%   You will also need to rename them in Ma27Solver.c so you may like to do
%   a find and replace on each one.
%   d2) If you are going to compile with my PARDISO interface, add both
%   .cpp files from Source/Pardiso Addin/ to the project and make sure you 
%   add Intel MKL libraries to the include path.
%   e) Right click the project in the solution explorer, and click
%   properties. Navigate to Configuration Properties -> C/C++ -> General
%   and under Additional Include Directories add the project directory.
%   f) Navigate to C/C++ -> Preprocessor and under Preprocessor Definitions
%   add _CRT_SECURE_NO_WARNINGS.
%   g) Navigate to C/C++ -> Code Generation and under Enable C++ Exceptions
%   change to "Yes with Extern C Functions (/EHs)". Also ensure the Runtime
%   Library is selected as Multi-threaded DLL (/MD).
%   h) Navigate to C/C++ -> Advanced and under Compile As change to
%   "Compile as C++ Code (/TP)". This is required as the file extension is
%   .c, but we are compiling C++ code.
%   i) Create a new solution platform for x64 if required, ensure you are
%   building a 'Release', and build the project!
%   j) Copy the generated .lib file to the following folder:
%
%   OPTI/Solvers/ooqp/Source/lib/win32 or win64
%
%   And rename it to ooqp.lib.
%
%   Note there should be less than 6 warnings and no errors when compiling,
%   with the only noticeable warning saying double gmu has been declared
%   twice (not a big problem). The others are for x64 size_t to int loss of 
%   data etc etc.

% Next we need to copy all the required header files. I went through one by
% one adding what was needed, so have a look in the supplied
% ooqp/Source/Include folder for the required header files. OOQP has quite
% a few so I decided it was best not to copy them all (as they are
% certainly not all required!).

% 3) Get & Compile MA27 (Optional - only required if not using Intel MKL
% PARDISO)
% MA27 is a linear solver from the Harwell Subroutine Library Archives, and
% is available from http://www.hsl.rl.ac.uk/archive/hslarchive.html. You
% will need to register to download. Make sure you download the double
% precision version! You will receive a single .f FORTRAN source file so
% follow the steps below to compile the library:
%   a) Create a new VS2010 Visual Fortran Static Library project.
%   b) Copy the FORTRAN file you downloaded (I called mine ma27.f) to the
%   project directory.
%   c) From the solution explorer right click Source Files and goto Add ->
%   Exisiting Item, and add your .f file.
%   d) Right click the project in the solution explorer, and click
%   properties. Navigate to Configuration Properties -> Fortran ->
%   Libraries and under Runtime Library change it to "Multithreaded DLL".
%   e) Create a new solution platform for x64 if required, ensure you are
%   building a 'Release', and build the project!
%   f) Copy the generated .lib file to the following folder:
%
%   OPTI/Solvers/ooqp/Source/lib/win32 or win64
%
%   And rename it to ma27.lib. 

% 4) MEX Interface
% I found the supplied MEX interface compiled fine, but returned incorrect
% results, which I attributed to perhaps a change in the sparse matrix
% indexing in Matlab. Therefore I have re-written this interface, and I
% suggest you use the supplied ooqp_mex.cpp, rather than the OOQP
% distribution version. You will however need to copy mexUtility.h to
%
%   OPTI/Solvers/ooqp/Source/Include
%
% and mexUtility.c to 
%
%   OPTI/Solvers/ooqp/Source
%
% renaming it to mexUtility.cpp.

% 5) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the OOQP MEX file. Once you have completed all the
% above steps, simply run this file to compile OOQP! You MUST BE in the 
% base directory of OPTI!

clear ooqp

% Modify below function if it cannot find Intel MKL on your system.
[mkl_link,mkl_for_link] = opti_FindMKL();
% Get Arch Dependent Library Path
libdir = opti_GetLibPath();

fprintf('\n------------------------------------------------\n');
fprintf('OOQP MEX FILE INSTALL\n\n');

%Get OOQP Libraries
post = [' -IInclude -L' libdir ' -looqp -output ooqp'];
%Uncomment if you are using MA27
% post = [post ' -lma27 -DUSE_MA27'];
%Get Intel Fortran Libraries (for MA27 build if required) & MKL Libraries (for BLAS)
post = [post mkl_link mkl_for_link];

%CD to Source Directory
cdir = cd;
cd 'Solvers/ooqp/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims ooqp_mex.cpp';
try
    eval([pre post])
    movefile(['ooqp.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:ooqp','Error Compiling OOQP!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');
