% clear all;
% clc;

Power = {{}, {}, {}, {},{}};
Comm = {{}, {}, {}, {}, {}, {}};
Trans = {{}, {}, {}, {}, {}};
Power_Resource = [];
Comm_Resource = [];
Trans_Resource = [];

%% INPUTS
% System_Dependent_Factor: restoration delaying factor due to system interdepedencies
% on trnasportation functionality for transporting crews and materials.
% this factor will be multiplied to the sampled restoration durations. 
% The value of 1.2 can be adjusted later. 
System_Dependent_Factor = 1.2;

% ResilienceMetricChoice: user's choice of resilience metric 
% 1. RessilienceMetric = 1 as resilience index (Reed et al. 2009)
% 2. RessilienceMetric = 2 as resilience loss (Sun et al. 2018)
% 3. RessilienceMetric = 3 as rapidity (Sun et al. 2018) 
% Reed et al. (2009) "Methodology for Assessing the Resilience of
% Networked Infrastructure", IEEE SYSTEMS JOURNAL, VOL. 3, NO. 2,
% 174-180.  https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=4912342
% Sun et al. (2018) "Resilience metrics and measurement methods
% for transportation infrastructure: the state of the art". 
% Sustainable and Resilient Infrastructure, DOI: 10.1080/23789689.2018.1448663.
ResilienceMetricChoice = 1;

% % choose functionality metrics
% Power_Func_Num = 3;
% Trans_Func_Num = 3;
% Comm_Func_Num = 3;

% choice of link direction
% LinkDirectionChoice = 1: direction in the network graph 
% LinkDirectionChoice = 2; unidirection in the network graph
LinkDirectionChoice = 2; 



%% others
Dictionary = containers.Map('KeyType','char','ValueType','any');

Neighborhood = {};

fid = fopen('Input.txt', 'r');
line = fgetl(fid);

while ischar(line)
    try
        tmp = strsplit(line);
        if ~strcmp(tmp(1), '#')
            if strcmp(tmp(1), 'Data')
                pow_check = containers.Map('KeyType','char','ValueType','int32');
                
                antenna_check = containers.Map('KeyType','int32','ValueType','int32');
                centraloffice_check = containers.Map('KeyType','char','ValueType','int32');
                communicationtower_check = containers.Map('KeyType','char','ValueType','int32');
                comm_check = {antenna_check, centraloffice_check, communicationtower_check};
                
                bridge_check = containers.Map('KeyType','char','ValueType','int32');
                trafficlight_check = containers.Map('KeyType','char','ValueType','int32');
                road_check = containers.Map('KeyType','char','ValueType','int32');
                trans_check = {bridge_check, trafficlight_check, road_check};
                
                try
                    if length(tmp) == 1
                        fprintf('ERROR: Missing Data input\n');
                        return
                    else
                        for i = 2:length(tmp)
                            [Power, Trans, Comm, Neighborhood] = Library.readInput(char(tmp(i)), pow_check, comm_check, trans_check, Power, Trans, Comm, Dictionary, Neighborhood);

                        end

                    end
                catch exception
                    msg = getReport(exception, 'basic');
                    disp(msg);
                    return;
                end
            end
            
            if strcmp(tmp(1), 'System')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Active System input\n');
                    return
                else
                    system = {};
                    index = 1;
                    for i = 2:length(tmp)
                        system{index} = char(tmp(i));
                        index = index + 1;
                    end
                    [active_power, active_trans, active_comm] =  Library.ActiveSystem(system);
                end
            end
            
            if strcmp(tmp(1), 'Map')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Map input\n');
                    return
                else
                    load(char(tmp(2)));
                end
            end
            
            if strcmp(tmp(1), 'Nsamples')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Number Of Sample input\n');
                    return
                else
                    Nsamples = str2num(char(tmp(2)));
                end
            end
            
            if strcmp(tmp(1), 'NRun')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Number Of Run input\n');
                    return
                else
                    NRun = str2num(char(tmp(2)));
                end
            end
            
            if strcmp(tmp(1), 'Profile_Num')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Scheduler Model input\n');
                    return
                else
                    Profile_Num = str2num(char(tmp(2)));
                end
            end
            
            if strcmp(tmp(1), 'Scheduler')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Scheduler Model input\n');
                    return
                else
                    Scheduler_Num = str2num(char(tmp(2)));
                end
            end
            
            if strcmp(tmp(1), 'Functionality_Power')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Functionality Power Model input\n');
                    return
                else
                    Power_Func_Num = str2num(char(tmp(2)));
                end
            end
            
            if strcmp(tmp(1), 'Functionality_Comm')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Functionality Communication Model input\n');
                    return
                else
                    Comm_Func_Num = str2num(char(tmp(2)));
                end
            end
            
            if strcmp(tmp(1), 'Functionality_Trans')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Functionality Transporation Model input\n');
                    return
                else
                    Trans_Func_Num = str2num(char(tmp(2)));
                end
            end
            
            if strcmp(tmp(1), 'ReSchedule')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Functionality Transporation Model input\n');
                    return
                else
                    ReSchedule_Num = str2num(char(tmp(2)));
                end
            end
            
            if strcmp(tmp(1), 'Time')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Functionality Transporation Model input\n');
                    return
                else
                    time_horizon = str2num(char(tmp(2)));
                end
            end
            
            if strcmp(tmp(1), 'Interdependence')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Functionality Transporation Model input\n');
                    return
                else
                    Interdependence_Num = str2num(char(tmp(2)));
                end
            end
            
            if strcmp(tmp(1), 'Power_Resource')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Functionality Transporation Model input\n');
                    return
                else
                    for i = 1 + 1:length(tmp)
                        Power_Resource(i - 1) = str2num(char(tmp(i)));
                    end
                end
            end
            
            if strcmp(tmp(1), 'Comm_Resource')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Functionality Transporation Model input\n');
                    return
                else
                    for i = 1 + 1:length(tmp)
                        Comm_Resource(i - 1) = str2num(char(tmp(i)));
                    end
                end
            end
            
            if strcmp(tmp(1), 'Trans_Resource')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Functionality Transporation Model input\n');
                    return
                else
                    for i = 1 + 1:length(tmp)
                        Trans_Resource(i - 1) = str2num(char(tmp(i)));
                    end
                end
            end
            
            if strcmp(tmp(1), 'Power_Priority')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Functionality Transporation Model input\n');
                    return
                else
                    Power_Priority = str2num(char(tmp(2)));
                end
            end
            
            if strcmp(tmp(1), 'Comm_Priority')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Functionality Transporation Model input\n');
                    return
                else
                    Comm_Priority = str2num(char(tmp(2)));
                end
            end
            
            if strcmp(tmp(1), 'Trans_Priority')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Functionality Transporation Model input\n');
                    return
                else
                    Trans_Priority = str2num(char(tmp(2)));
                end
            end
            if strcmp(tmp(1), 'System_Dependent_Factor')
                if length(tmp) == 1
                    fprintf('ERROR: Missing Functionality Transporation Model input\n');
                    return
                else
                    System_Dependent_Factor = str2num(char(tmp(2)));
                end
            end
            if strcmp(tmp(1), 'Prob_Magic_Battery')
                if length(tmp) == 1
                    Prob_Magic_Battery = 0.9;
                else
                    Prob_Magic_Battery = str2num(char(tmp(2)));
                end
            end
            if strcmp(tmp(1), 'Seperate_Scheduling')
                if length(tmp) == 1
                    Seperate_Scheduling = 1;
                else
                    Seperate_Scheduling = str2num(char(tmp(2)));
                end
            end
            if strcmp(tmp(1), 'priority_power_num')
                if length(tmp) == 1
                    priority_power_num = 1;
                else
                    priority_power_num = str2num(char(tmp(2)));
                end
            end
            if strcmp(tmp(1), 'priority_transportation_num')
                if length(tmp) == 1
                    priority_transportation_num = 1;
                else
                    priority_transportation_num = str2num(char(tmp(2)));
                end
            end
            if strcmp(tmp(1), 'priority_communication_num')
                if length(tmp) == 1
                    priority_communication_num = 1;
                else
                    priority_communication_num = str2num(char(tmp(2)));
                end
            end
        end
        line = fgetl(fid);
    catch exception
        msg = getReport(exception, 'basic');
        disp(msg);
        break;
    end
end

Power = Library.createTransmissionTower(Power, Dictionary);
Trans = Library.assignRoadToRoadNode(Trans,Dictionary);

Library.assignFragility(Power, Trans, Comm);
Library.assignRecovery(Power, Trans, Comm);
Comm = Library.assignCellLine(Comm, Dictionary);
[Trans, Comm] = Library.assignPowerToTransComm(Power, Trans,Comm, Dictionary);
[Trans, Comm, Power, Neighborhood] = Library.linkNeighborhood(Power, Trans,Comm, Dictionary, Neighborhood);

transGraph = Library.graphTheoryTrans(Trans, Dictionary);
powerGraph = Library.graphTheoryPower(Power, Dictionary);
commGraph = Library.graphTheoryComm(Comm, Dictionary);

Branch_Set= Power{1};
Bus_Set = Power{2};
Generator_Set = Power{3};
TransmissionTower_Set = Power{4};
Neighborhood_Power_Set = Power{5};

Antenna_Set = Comm{1};
Centraloffice_Set = Comm{2};
Router_Set = Comm{3};
Cellline_Set = Comm{4};
CommunicationTower_Set = Comm{5};
Neighborhood_Comm_Set = Comm{6};

Road_Set = Trans{1};
Bridge_Set = Trans{2};
TrafficLight_Set = Trans{3};
RoadNode_Set = Trans{4};
Neighborhood_Trans_Set = Trans{5};
clear Power Comm Trans fid index system i line tmp antenna_check comm_check pow_check trans_check centraloffice_check bridge_check road_check trafficlight_check communicationtower_check;