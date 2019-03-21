%Minimum working example of PRAISys
%Communication Sytstem

%%   Input charactersitcs
%Graph Display
%
%
%                           Transformer          
%                                |      
%                                |       
%                             Antenna          
%                             /      \
%                            /        \
%                           /          \ 
%            Central Office 1 --------- Central Office 2
%                            \         /
%                             \       /
%                              \     /
%                               \   /
%                        Central Office 3
%Assumption is that the recvoery of BS recovers 0.1% depend on the
%functioanlity of the power system

%
%BS stantds for Base Station
% run input file
run('Data_Power.m');

Antenna_Set = {};
Centraloffice_Set = {};
Router_Set = {};
Cellline_Set = {};

Num.Antenna=3;


xy=[6 0  %BS1
    7 0  %BS2
    8 1  %BS3
    8 2  %BS4
    9 0  %BS5
    3 8  %BS6
    6 9  %BS7
    6 1  %CO1
    6 2  %CO2
    6 3  %CO3
    6 4  %CO4
    6 5  %CO5
    6 6  %CO6
    6 7  %CO7
    6 8  %CO8
    7 1  %CO9
    7 2  %CO10
    7 3  %CO11
    7 4  %CO12
    7 5  %CO13
    7 6  %CO14
    7 7  %CO15
    7 8  %CO16
    7 9  %CO17
    8 0  %CO18
    8 3  %CO19
    8 4  %CO20
    8 5  %CO21
    ];

for i=1:Num.Antenna
    if i < 2
        Antenna_Set{i}=Antenna(i,xy(i,:),1,1);
        Bus_Set{length(Bus_Set) + 1} = Bus(length(Bus_Set) + 1, Branch_Set{1}.Location, Antenna_Set{i}.Location, 3);
        Antenna_Set{i}.Line = length(Bus_Set);
        Branch_Set{1}.Bus = [Branch_Set{1}.Bus, length(Bus_Set)];
    elseif i < 3
        Antenna_Set{i}=Antenna(i,xy(i,:),2,1);
        Bus_Set{length(Bus_Set) + 1} = Bus(length(Bus_Set) + 1, Branch_Set{13}.Location, Antenna_Set{i}.Location, 3);
        Antenna_Set{i}.Line = length(Bus_Set);
        Branch_Set{13}.Bus = [Branch_Set{13}.Bus, length(Bus_Set)];
    else
        Antenna_Set{i}=Antenna(i,xy(i,:),3,1);
        Bus_Set{length(Bus_Set) + 1} = Bus(length(Bus_Set) + 1, Branch_Set{25}.Location, Antenna_Set{i}.Location, 3);
        Antenna_Set{i}.Line = length(Bus_Set);
        Branch_Set{25}.Bus = [Branch_Set{25}.Bus, length(Bus_Set)];
    end
end

for i = 1:9
    if i < 4
        Centraloffice_Set{i} = Centraloffice(i, xy(i+7,:), 1,2);
        addCentraloffice(Antenna_Set{1}, i);
    elseif i < 7
        Centraloffice_Set{i} = Centraloffice(i, xy(i+7,:), 2,2);
        addCentraloffice(Antenna_Set{2}, i);
    elseif i < 10
        Centraloffice_Set{i} = Centraloffice(i, xy(i+7,:), 3,2);
        addCentraloffice(Antenna_Set{3}, i);
    elseif i < 13
        Centraloffice_Set{i} = Centraloffice(i, xy(i+7,:), 4,2);
        addCentraloffice(Antenna_Set{4}, i);
    elseif i < 16
        Centraloffice_Set{i} = Centraloffice(i, xy(i+7,:), 5,2);
        addCentraloffice(Antenna_Set{5}, i);
    elseif i < 19
        Centraloffice_Set{i} = Centraloffice(i, xy(i+7,:), 6,2);
        addCentraloffice(Antenna_Set{6}, i);
    else
        Centraloffice_Set{i} = Centraloffice(i, xy(i+7,:), 7,2);
        addCentraloffice(Antenna_Set{7}, i);
    end
end

for i = 1:length(Centraloffice_Set)
    Router_Set{i} = Router(i, Centraloffice_Set{i}.Location, 'Router_A',3);
    addRouter(Centraloffice_Set{i},i);
end

index = 1;
for i = 1:length(Antenna_Set)
    for j = 1:length(Antenna_Set{i}.Centraloffice)
        Cellline_Set{index} = Cellline(index, Antenna_Set{i}.Location, Centraloffice_Set{Antenna_Set{i}.Centraloffice(j)}.Location, 'Cellline_A',4);
        index = index + 1;
    end
end

for i = 1:length(Antenna_Set)
    for j = 1:length(Antenna_Set{i}.Centraloffice) - 1
        for k = j + 1:length(Antenna_Set{i}.Centraloffice)
            Cellline_Set{index} = Cellline(index, Centraloffice_Set{Antenna_Set{i}.Centraloffice(j)}.Location, Centraloffice_Set{Antenna_Set{i}.Centraloffice(k)}.Location, 'Cellline_A',4);
            index = index + 1;
        end
    end
end

clear xy Num i j k index;