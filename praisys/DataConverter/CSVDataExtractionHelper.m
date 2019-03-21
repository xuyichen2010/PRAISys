%By dePaul Miller
%Designed to work on the csv extraction
clear all
clc
formatSpec = '%s%s%s%s';
x = readtable('./sqlData/ExtractedIntersections.csv', 'Delimiter', ',', 'Format', formatSpec);
points1 = string(table2cell(x(1:height(x),3)));
points2 = string(table2cell(x(1:height(x),4)));
pointSet1 = [];
pointSet2 = [];
%have to have different sets of points depending on the number of
%MULTIPOINTS that occur when conducting the query
for i = 1:length(points1)
    points1(i) = replace(points1(i), "MULTIPOINT", "");
    points1(i) = replace(points1(i), "POINT", "");
    points1(i) = replace(points1(i), "(", "");
    points1(i) = replace(points1(i), ")", "");
    points1(i) = replace(points1(i), '"', "");
end

for i = 1:length(points2)
    points2(i) = replace(points2(i), "(", "");
    points2(i) = replace(points2(i), ")", "");
    points2(i) = replace(points2(i), '"', "");
end

for i = 1:length(points1)
    pointSet1 = [pointSet1; strsplit(points1(i))];
end

for i = 1:length(points2)
    if length(strsplit(points2(i)))<2
        pointSet2 = [pointSet2; ["",""]];
    else
        pointSet2 = [pointSet2; strsplit(points2(i))];
    end
end

points = [pointSet1(1:length(pointSet1),2:3),pointSet2];
cellX = table2cell(x);
finishedValue = [cellX(1:height(x),1:2),points];
finishedValue = cellstr(finishedValue);
finishedTable = cell2table(finishedValue, 'VariableNames', {'Road1' 'Road2' 'long1' 'lat1' 'long2' 'lat2'});
writetable(finishedTable, './inputData/FinishedExtractedIntersections.csv','Delimiter', ',');

%now working on all points

formatSpec = '%s%s%s';
x = readtable('./sqlData/allPointsPAHighway.csv', 'Delimiter', ',', 'Format', formatSpec);
points1 = string(table2cell(x(1:height(x),2)));
pointSet = [];

for i = 1:length(points1)
    points1(i) = replace(points1(i), "POINT", "");
    points1(i) = replace(points1(i), "(", "");
    points1(i) = replace(points1(i), ")", "");
    points1(i) = replace(points1(i), '"', "");
end

for i = 1:length(points1)
    pointSet = [pointSet; strsplit(points1(i))];
end


points = pointSet(1:length(pointSet),2:3);
cellX = table2cell(x);
finishedValue = [cellX(1:height(x),1),cellX(1:height(x),3),points];
finishedValue = cellstr(finishedValue);
finishedTable = cell2table(finishedValue, 'VariableNames', {'Road' 'Order' 'long' 'lat'});
writetable(finishedTable, './inputData/FinishedAllPoints.csv','Delimiter', ',');


