%% NOMAD Install for OPTI Toolbox

% This file will help you compile NOMAD for use with MATLAB. 

% My build platform:
% - Windows 7 SP1 x64
% - Visual Studio 2010

% The supplied MEX files will require the VC++ 2010 Runtime.


% To recompile you will need to get / do the following:

% 1) Get NOMAD
% NOMAD is available from http://www.gerad.ca/NOMAD/PHP_Forms/Download.php.
% Complete the download form then download the latest version. Once you
% have installed NOMAD, locate the /src/ directory.

% 2) Compile NOMAD
% NOMAD comes with a Visual Studio 2010 solution which works fine. The
% project nomad_lib creates the required static library, however to
% function with this interface Parameters.cpp and Parameters.hpp need to be
% replaced (custom code changes were made by the author for OPTI). Complete
% the following steps to compile libnomad:
%
%   a) From OPTI/Solvers/nomad/Source/Parameters.zip copy Parameters.cpp
%   and Parameters.hpp to the /src/ directory of NOMAD, replacing the
%   existing versions.
%   b) Open the VS solution from /src/VisualStudio2010/nomad.sln
%   c) In the Solution Explorer right click on nomad_lib and click
%   properties. Under General change the Configuration Type to:
%       Static Library (.lib)
%   and Whole Program Optimization to:
%       No Whole Program Optimization
%   d) In C/C++ -> Code Generation change the Runtime Library to
%   Multi-threaded DLL (/MD).
%   e) Create a new solution platform for x64 if required, ensure you are
%   building a 'Release', and build the project!
%   f) Copy the generated .lib file to the following folder:
%
%   OPTI/Solvers/nomad/Source/lib/win32 or win64
%
%   And rename it libnomad.lib.

% Next we need to copy all the required header files from /src/ to
%
%   OPTI/Solvers/nomad/Source/Include/
%

% 3) NOMAD MEX Interface
% % The NOMAD MEX Interface is a simple MEX interface I wrote to use NOMAD.
% Note the MEX interface contains two versions, a GERAD version (for the
% authors of NOMAD) and an OPTI version (for easier integration into this
% toolbox). By default the GERAD version is built, however to build the
% OPTI version simply add the preprocessor "OPTI_VERSION" to the compiler.

% 4) Compile the MEX File
% The code below will automatically include all required libraries and
% directories to build the NOMAD MEX file. Once you have completed all the
% above steps, simply run this file to compile NOMAD! You MUST BE in the 
% base directory of OPTI!

clear nomad

% Get Arch Dependent Library Path
libdir = opti_GetLibPath();

fprintf('\n------------------------------------------------\n');
fprintf('NOMAD MEX FILE INSTALL\n\n');

%Get NOMAD Libraries
post = [' -IInclude -L' libdir ' -llibnomad -llibut -output nomad -DOPTI_VERSION'];

%CD to Source Directory
cdir = cd;
cd 'Solvers/nomad/Source';

%Compile & Move
pre = 'mex -v -largeArrayDims nomadmex.cpp';
try
    eval([pre post])
    movefile(['nomad.' mexext],'../','f')
    fprintf('Done!\n');
catch ME
    cd(cdir);
    error('opti:nomad','Error Compiling NOMAD!\n%s',ME.message);
end
cd(cdir);
fprintf('------------------------------------------------\n');
