powerPerHour = zeros(23,1);
for i = 1 : 23
powerPerHour(i) = sum(power((3600 * (i - 1) + i : 3600 * i), 2));
end