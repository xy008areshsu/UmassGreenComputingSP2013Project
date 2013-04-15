function opti_Install
%% Installation File for OPTI

% In order to run this tool, please run this file to setup the required
% directories. You MUST be in the current directory of this file!

%   Copyright (C) 2012 Jonathan Currie (I2C2)

cpath = cd;
try
    cd('Utilities');
catch %#ok<CTCH>
    error('You don''t appear to be in the OPTI Toolbox directory');
end
%Get current versions    
cur_ver = optiver();

fprintf('\n------------------------------------------------\n')
fprintf(['  INSTALLING OPTI TOOLBOX ver ' sprintf('%1.2f',cur_ver) '\n\n'])

%Perform pre-req check
cd Install
opti_PreReqCheck();
cd(cpath);

%Uninstall previous versions
fprintf('\n- Checking for previous versions of OPTI Toolbox...\n');
no = opti_Uninstall('opti_Install.m',0);
if(no < 1)
    fprintf('Could not find a previous installation of OPTI Toolbox\n');
else
    fprintf('Successfully uninstalled previous version(s) of OPTI Toolbox\n');
end

%Add toolbox path to MATLAB
fprintf('\n- Adding OPTI Paths to MATLAB Search Path...');
genp = genpath(cd);
genp = regexp(genp,';','split');
%Folders to exclude from adding to Matlab path
i = 1;
rInd{:,:,i} = strfind(genp,'distribution'); i = i + 1;
rInd{:,:,i} = strfind(genp,'vti_cnf'); i = i + 1;
rInd{:,:,i} = strfind(genp,'vti_pvt'); i = i + 1;
rInd{:,:,i} = strfind(genp,'Source'); i = i + 1;
ind = NaN(length(rInd{1}),1);
%Track indices of paths to remove from list
for i = 1:length(rInd{1})
    for j = 1:size(rInd,3)
        if(any(rInd{j}{i}))
            ind(i) = 1;
        end
    end
end

%Remove paths from above and add to matlab path
genp(ind == 1) = [];
addpath(genp{:});
rehash
fprintf('Done\n\n');
in = input('- Would You Like To Save the Path Changes? (Recommended) (y/n): ','s');
if(strcmpi(in,'y'))
    try
        savepath;
    catch %#ok<CTCH>
        warning('opti:install',['It appears you do not have administrator rights on your computer to save the Matlab path. '...
                                'In order to run OPTI Toolbox you will need to install it each time you wish to use it. To fix '...
                                'this please contact your system administrator to obtain administrator rights.']);
    end
end

%Post Install Test if requested
in = input('\n- Would You Like To Run Post Installation Tests? (Recommended) (y/n): ','s');
if(strcmpi(in,'y'))
    opti_Install_Test(1);
end

%Launch Help Browser [no longer works in R2012b]
web('Opti_Main.html','-helpbrowser');

%Finished
fprintf('\n\nOPTI Toolbox Installation Complete!\n');
disp('------------------------------------------------')

fprintf('\n\nYou now have the following solvers available to use:\n');
checkSolver;


function no = opti_Uninstall(token,del)

%Check nargin in, default don't delete
if(nargin < 2 || isempty(del))
    del = 0;
end

%Check if we have anything to remove
paths = which(token,'-all');
len = length(paths);
if(~len) %should always be at least 1 if we are in correct directory
    error('Expected to find "%s" in the current directory - please ensure you are in the OPTI Toolbox directory');        
elseif(len == 1)
    %if len == 1, either we are in the correct folder with nothing to remove, or we are in the
    %wrong folder and there are files to remove, check CD
    if(any(strfind(paths{1},cd)))
        no = 0;
        return;
    else
        error('Expected to find "%s" in the current directory - please ensure you are in the OPTI Toolbox directory');
    end    
else %old ones to remove
    
    %Remove each folder found, and all subdirs under
    for n = 2:len
        %Absolute path to remove
        removeP = paths{n};
        %Search backwards for first file separator (we don't want the filename)
        for j = length(removeP):-1:1
            if(removeP(j) == filesep)
                break;
            end
        end
        removeP = removeP(1:max(j-1,1));        

        %Everything is lowercase to aid matching
        lrpath = lower(removeP);
        opath = regexp(lower(path),';','split');

        %Find & Remove Matching Paths
        no = 0;
        for i = 1:length(opath)
            %If we find it in the current path string, remove it
            fnd = strfind(opath{i},lrpath);        
            if(~isempty(fnd))  
                rmpath(opath{i});
                no = no + 1;
            end
        end
        
        %Check we aren't removing our development version
        rehash;
        if(isdir([removeP filesep 'Testing'])) %is this robust enough?
            fprintf('Found development version in "%s", skipping.\n',removeP);
            return;
        end

        %If delete is specified, also delete the directory
        if(del)
            stat = recycle; recycle('on'); %turn on recycling
            rmdir(removeP,'s'); %not sure if we dont have permissions here
            recycle(stat); %restore to original
        end
    end    
end

