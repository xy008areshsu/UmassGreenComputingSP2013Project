function level = dispLevel(disp_str)
%DISPLEVEL  Convert String display format to numerical

if(isnumeric(disp_str))
    level = disp_str;
end

switch(disp_str)
    case 'off'
        level = 0;
    case 'final'
        level = 1;
    case 'iter'
        level = 2;
end

end

