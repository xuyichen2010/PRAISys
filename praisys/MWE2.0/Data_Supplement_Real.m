clear all;
clc;

num = xlsread('RoadNode.xlsx');
latitude = num(:,2)';
longtitude = num(:,3)';

clear num txt raw i;
run('read_links.m');
run('Input_Real.m');


for i = 1:length(Road_Set)
    Road_Set{i}.Start_Location = [latitude(Road_Set{i}.Start_Node), longtitude(Road_Set{i}.Start_Node)];
    Road_Set{i}.End_Location = [latitude(Road_Set{i}.End_Node), longtitude(Road_Set{i}.End_Node)];
end

priority = 1;
change = 1;
prev = inf;

while change ~= 0
    index = [];
    max = -1;
    change = 0;
    for i = 1:length(Bridge_Set)
        if Bridge_Set{i}.Traffic >= max && Bridge_Set{i}.Traffic < prev
            if Bridge_Set{i}.Traffic > max
                index = i;
            else
                index = [index, i];
            end
            max = Bridge_Set{i}.Traffic;
            change = 1;
        end
    end
    
    for i = 1:length(index)
        Bridge_Set{index(i)}.Priority = priority;
    end
    priority = priority + 1;
    prev = max;
end

Trans_Priority = priority - 1;

for i = 1:length(Road_Set)
    if isempty(Road_Set{i}.Bridge_Carr)
        Road_Set{i}.Priority = priority - 1;
    else
        tmp = -1;
        for j = 1:length(Road_Set{i}.Bridge_Carr)
            if Bridge_Set{Road_Set{i}.Bridge_Carr(j)}.Priority >= max
                tmp = Bridge_Set{Road_Set{i}.Bridge_Carr(j)}.Priority;
            end
        end
        Road_Set{i}.Priority = tmp;
    end
    
    for j = 1:length(Road_Set{i}.TrafficLight)
        TrafficLight_Set{Road_Set{i}.TrafficLight(j)}.Priority = Road_Set{i}.Priority;
    end
end

priority = 1;
change = 1;
prev = inf;

while change ~= 0
    index = [];
    max = -1;
    change = 0;
    for i = 1:length(Bus_Set)
        if Bus_Set{i}.Capacity >= max && Bus_Set{i}.Capacity < prev
            if Bus_Set{i}.Capacity > max
                index = i;
            else
                index = [index, i];
            end
            max = Bus_Set{i}.Capacity;
            change = 1;
        end
    end
    
    for i = 1:length(index)
        Bus_Set{index(i)}.Priority = priority;
        if ~isempty(Bus_Set{index(i)}.Generator)
            temp = extractAfter(Bus_Set{index(i)}.Generator, 9);
            temp = str2num(temp);
            Generator_Set{temp}.Priority = priority;
        end
        for j = 1:length(Bus_Set{index(i)}.Branch)
            Branch_Set{Bus_Set{index(i)}.Branch(j)}.Priority = priority;
        end
    end
    priority = priority + 1;
    prev = max;
end

Power_Priority = priority - 1;

for i = 1:length(CommunicationTower_Set)
    CommunicationTower_Set{i}.Priority = 1;
end

for i = 1:length(Centraloffice_Set)
    Centraloffice_Set{i}.Priority = 2;
end

for i = 1:length(Antenna_Set)
    Antenna_Set{i}.Priority = 3;
end

Comm_Priority = 3;

for i = 1:length(Bridge_Set)
    tmp = rand(i);
    if tmp < 0.3
        Bridge_Set{i}.Recovery = [30,5];
    else
        Bridge_Set{i}.Recovery = [20,5];
    end
end

for i = 1:length(Road_Set)
    tmp = rand(i);
    if tmp < 0.3
        Road_Set{i}.Recovery = [25,4];
    else
        Road_Set{i}.Recovery = [18,3];
    end
end


clear i j index max prev priority temp change tmp latitude longtitude;


