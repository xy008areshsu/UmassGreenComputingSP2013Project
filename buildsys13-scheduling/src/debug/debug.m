run ../LP;
s1 = roundn(s, -1);
d1 = roundn(d, -1);
bool = (s1 == 0 | d1 == 0);
if bool ~= 1
fprintf('False\n');
else 
fprintf('True\n');
end
