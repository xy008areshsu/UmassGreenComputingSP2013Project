function str = opti_PreReqCheck(verb)
%Check for VC++ 2010 on x86 and x64 systems

if(nargin < 1)
    verb = 1;
end

ROOTKEY = 'HKEY_LOCAL_MACHINE';
KEY32 = 'SOFTWARE\Microsoft\VisualStudio\10.0\VC\';
KEY64 = 'SOFTWARE\Wow6432Node\Microsoft\VisualStudio\10.0\VC\';


mver = ver('MATLAB');

if(verb), fprintf('- Checking operating system...\n'); end
switch(mexext)
    case 'mexw32'
        if(verb), fprintf('MATLAB %s 32bit (Windows x86) detected\n',mver.Release); end
        m = 1;
    case 'mexw64'
        if(verb), fprintf('MATLAB %s 64bit (Windows x64) detected\n',mver.Release); end
        m = 2;
    otherwise
        error('OPTI Toolbox is compiled only for Windows systems - sorry!');
end

if(verb), fprintf('\n- Checking for required pre-requisites...\n'); end

%If mexw32 - could be 32bit windows or 64bit windows with 32bit matlab,
%must check both!
str = [];

switch(m)
    case 1
        %Check 32bit Location, Redist
        try
            if(winqueryreg(ROOTKEY,[KEY32 'VCRedist\x86'],'Installed'))
                str = 'VC++ 2010 x86 Redistributable (Win32) Found';
            end
        catch %#ok<*CTCH>
            %Check 32bit Location, Runtime
            try
                if(winqueryreg(ROOTKEY,[KEY32 'Runtimes\x86'],'Installed'))
                    str = 'VC++ 2010 x86 Runtime (Win32) Found';
                end
            catch
                %Check 64bit Location, Redist
                try
                    if(winqueryreg(ROOTKEY,[KEY64 'VCRedist\x86'],'Installed'))
                        str = 'VC++ 2010 x86 Redistributable (Win64) Found';
                    end
                catch
                    %Check 64bit Location, Runtime
                    try
                        if(winqueryreg(ROOTKEY,[KEY64 'Runtimes\x86'],'Installed'))
                            str = 'VC++ 2010 x86 Redistributable (Win64) Found';
                        end
                    catch
                        error(prereqerror('x86'));
                    end
                end
            end
        end                                    
    case 2
        %Check Redist
        try
            if(winqueryreg(ROOTKEY,[KEY64 'VCRedist\x64'],'Installed'))
                str = 'VC++ 2010 x64 Redistributable Found';
            end
        catch
            %Check Runtime
            try
                if(winqueryreg(ROOTKEY,[KEY64 'Runtimes\x64'],'Installed'))
                    str = 'VC++ 2010 x64 Runtime Found';
                end                
            catch
                error(prereqerror('x64'));
            end            
        end
end

if(isempty(str))
    error('Could not determine the required pre-requisites, ensure you are running Windows x86 or x64!');
else
    if(verb), fprintf('%s\n',str); end
end


function str = prereqerror(build)

switch(build)
    case 'x64'
        l = 'http://www.microsoft.com/download/en/details.aspx?id=14632';
    otherwise
        l = 'http://www.microsoft.com/download/en/details.aspx?id=5555';
end

str = [sprintf(['Cannot find Microsoft VC++ 2010 ' build ' Redistributable!\n\n'])...
	   sprintf('Please close MATLAB and download the redistributable from Microsoft:\n')...
       l...
       sprintf('\n\nThen reinstall OPTI Toolbox!')];
   
   
   
   
   
