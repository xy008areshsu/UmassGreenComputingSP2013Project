%% MUMPS Install for OPTI Toolbox
% Copyright (C) 2011 Jonathan Currie (I2C2)

% This file will help you compile aMUltifrontal Massively Parallel sparse
% direct Solver (MUMPS) for use with MATLAB. 

% The supplied files and instructions are for compiling sequential double 
% precision MUMPS only.

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010
% - Intel Compiler XE (FORTRAN)
% - Intel Math Kernel Library

% To recompile you will need to get / do the following:

% 1) Get MUMPS
% MUMPS is available from http://graal.ens-lyon.fr/MUMPS/. You will need to
% register before you can download. We will create VS projects below.

% 2) Get WinMUMPS & Run It
% I used WinMUMPS (http://sourceforge.net/projects/winmumps/) to generate
% the Visual Studio project files for compiling MUMPS. You will need Python
% installed to run WinMUMPS (http://www.python.org/), I used v2.7.2 but any
% later version should work. Create a directory with MUMPS and WinMUMPS in it,
% and create a batch file in the same directory with the following:

% .\WinMumps-4.8\winmumps_generator.py --mumpsdir=.\MUMPS_4.10.0 --winmumps=. --visualstudio=9 --intelfortran=11 --symbols=FFT_BUILDSYSTEM_GENERATOR --metis

% Assuming your versions of WinMumps, MUMPS, Visual Studio, and Intel
% Fortran are all the same! Note VS 10 is not compatible, but generate v9.0
% and then use the upgrade wizard. Alternatively navigate to the directory
% at the command line and run the line above to generate the projects.

% 3) Compile MUMPS
% Open each of the following projects, change to Release win32/x64 and
% click Build the project. The .lib file will be automatically placed in
% the MUMPS/lib directory. VS 2010 will automatically upgrade the VC
% projects to 2010.
%
%   - dmumps_c.vcproj
%   - mumps_common_c.vcproj
%   - pord_c.vcproj
%   - libseq_c.vcproj
%   - dmumps_fortran.vfproj (FORTRAN)
%   - libseq_fortran.vfproj (FORTRAN)

% Once compiled place all six .lib files into the following folder:
%
%   OPTI/Solvers/mumps/Source/lib/win32 or win64

% Also copy the required header files from MUMPS_xxx/include to:
%
%   OPTI/Solvers/mumps/Source/Include
%
% Header files to copy will be all files starting with 'd' (double) and the
% general mumps header files (starting with 'm'). In my distribution there
% were 5 files copied.

% 4) Get & Compile METIS
% MUMPS requires the METIS library and I choose to compile this from
% source. You can download METIS from
% http://glaros.dtc.umn.edu/gkhome/metis/metis/download. I choose v4.0.3 as
% the latest stable release source distribution. Download and unzip the
% contents into a folder, and follow the instructions below:
%
%   a) Create a new VS2010 VC++ Win32 project, select Static Library and no
%   precompiled header.
%   b) From metis-xxx/Lib copy all .c and .h files into the VS project
%   directory (containing the solution file).
%   c) From VS right click Source Files and goto Add -> Existing Item, and
%   select all .c and .h METIS files.
%   d) Open metis.h and comment out line 21 (#include strings.h)
%   e) Open proto.h and uncomment line 435 (void GKfree...) - NOT SURE WHY THIS IS COMMENTED?!
%   f) Right click the project in the solution explorer, and click
%   properties. Navigate to Configuration Properties -> C/C++ -> General
%   and under Additional Include Directories add the project directory.
%   g) Navigate to C/C++ -> Preprocessor and under Preprocessor Definitions
%   add __STDC__ and __VC__.
%   h) Create a new solution platform for x64 if required, ensure you are
%   building a 'Release', and build the project!
%   i) Copy the generated .lib file to the following folder:
%
%   OPTI/Solvers/mumps/Source/lib/win32 or win64
%
%   And rename it to metis.lib.


%   metis.h REALTYPEWIDTH 64

%USE_GKREGEX


% 5) Get MUMPS MEX Interface
% Supplied with MUMPS in the MATLAB folder is mumpsmex.c. Copy this to the
% following folder:
%
%   OPTI/Solvers/mumps/Source 

% 6) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the MUMPS MEX file. Once you have completed all the
% above steps, simply run this file to compile MUMPS! You MUST BE in the 
% base directory of OPTI!

clear mumps

% Modify below function if it cannot find Intel MKL on your system.
[mkl_link,mkl_for_link] = opti_FindMKL();
% Get Arch Dependent Library Path
libdir = opti_GetLibPath();

fprintf('\n------------------------------------------------\n');
fprintf('MUMPS MEX FILE INSTALL\n\n');

%Get MUMPS Libraries
post = [' -IInclude -L' libdir ' -ldmumps_c -ldmumps_fortran -lpord_c -llibseq_c -llibseq_fortran -lmumps_common_c -lmetis -DMUMPS_ARITH=2'];
%Get Intel Fortran Libraries (for MUMPS build) & MKL Libraries (for BLAS)
post = [post mkl_link mkl_for_link];
%Common
post = [post ' -output mumps'];

%CD to Source Directory
cdir = cd;
cd 'Solvers/mumps/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims mumpsmex.c';
try
    eval([pre post])
    movefile(['mumps.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:mumps','Error Compiling MUMPS!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');


% Compilation Reference:
% https://projects.coin-or.org/Ipopt/wiki/CompilationHints
% WinMUMPS readme (readme.html)

% METIS Reference:
% “A Fast and Highly Quality Multilevel Scheme for Partitioning Irregular 
% Graphs”. George Karypis and Vipin Kumar. SIAM Journal on Scientific 
% Computing, Vol. 20, No. 1, pp. 359—392, 1999.