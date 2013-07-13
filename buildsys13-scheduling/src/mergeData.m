T = 24;
list = dir('../dataset/');
list = list(3 : end);

s = size(list);
s = s(1);
filenames = cell(s,1);
LoadTotal = zeros(T, s);
for i = 1 : s
    filenames(i) = {strcat('../dataset/', list(i).name)};

end
filenames = char(filenames);
for i = 1 : s
    LoadTotal(:, i) = load(strtrim(filenames(i, :)));
end