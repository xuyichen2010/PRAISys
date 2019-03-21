filename = 'bridgeTasks.xlsx';  % dinfo(K).name
num = readtable(filename);
save('bridgeTasks.mat','num');