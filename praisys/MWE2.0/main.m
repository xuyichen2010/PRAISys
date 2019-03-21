%% Main File Mimimum Work Example
% Clear All Data
close all
clear
clc
Library.CleanOldData();
Library.CreateFolder();

% Load Input File
run('Data_Supplement_Real.m');

% Profile
if Profile_Num == 1
    profile on
    spmd
        mpiprofile('on');
    end
end

%% Inititionlize Variables 
% Begin Simulation
Functionality_Power = zeros(Nsamples*NRun,time_horizon);
Functionality_Communication = zeros(Nsamples*NRun,time_horizon);
Functionality_Transportation = zeros(Nsamples*NRun,time_horizon);

% Data Export Field
Total_Schedule = cell(1,Nsamples*NRun);
Total_Date = cell(1,Nsamples*NRun);
index = 0;



% Save Original Data (Need to use load command to view the data)
Power_Set = {Branch_Set, Bus_Set, Generator_Set,TransmissionTower_Set, Neighborhood_Power_Set};
Communication_Set = {Antenna_Set, Centraloffice_Set, Router_Set, Cellline_Set, CommunicationTower_Set,Neighborhood_Comm_Set};
Transportation_Set = {Road_Set, Bridge_Set, TrafficLight_Set,RoadNode_Set,Neighborhood_Trans_Set};


Total = {Power_Set, Communication_Set, Transportation_Set, Dictionary, Neighborhood};

[~, Hostname] = system('hostname');
filename = strcat('./', deblank(Hostname), '/Original_Data.mat');
save(filename, 'Total');

[powerGraph, commGraph, transGraph] = Library.Sampling(Nsamples, NRun, Hostname, IM, IMx, IMy, active_power, active_comm, active_trans,transGraph, powerGraph, commGraph,Prob_Magic_Battery);


%parfor
%% Acutual Simulation
for i = 1:NRun * Nsamples
    list = dir(strcat('./', deblank(Hostname), '/mat/*.mat'));
    filename = strcat('./', deblank(Hostname), '/mat/', list(i).name);
    
    
    % Retrive Data For Every Thread
    [Power_Set, Communication_Set, Transportation_Set, Dictionary, Neighborhood] = Library.ResetData(filename);
    [Power_Set, Communication_Set, Transportation_Set, Dictionary] = Library.CalculateActualTime(Power_Set, Communication_Set, Transportation_Set, Dictionary);
    
    % Repair Schedule
    if Seperate_Scheduling == 0
        taskTable = Library.createTaskTable(Dictionary);
    else
        taskTable = Interface1.createTaskTable(Dictionary, active_power, active_comm, active_trans);
    end
    
    % Repair Schedule
    if Seperate_Scheduling == 0
        precedenceTable = Library.createPreTable(Dictionary);
    else
        precedenceTable = Interface1.createPreTableSep(Dictionary, active_power, active_comm, active_trans);
    end
    save tables.mat taskTable precedenceTable Power_Resource Comm_Resource Trans_Resource time_horizon
%     resource = [Power_Resource; Comm_Resource; Trans_Resource];
%     [Schedule, Date] = Interface1.RepairSchedule(Scheduler_Num, time_horizon, Power_Resource, Trans_Resource, Comm_Resource, Power_Priority, Comm_Priority, Trans_Priority, active_power, active_comm, active_trans, Power_Set, Communication_Set, Transportation_Set);
%     [Schedule, Date] = Interface1.RepairSchedule(Scheduler_Num, time_horizon, Power_Resource, Trans_Resource, Comm_Resource, Power_Priority, Comm_Priority, Trans_Priority, active_power, active_comm, active_trans, Power_Set, Communication_Set, Transportation_Set, taskTable, precedenceTable);
    [Schedule, Date] = Interface1.RepairSchedule(Scheduler_Num, time_horizon, Power_Resource, Trans_Resource, Comm_Resource, Power_Priority, Comm_Priority, Trans_Priority,...
                active_power, active_comm, active_trans, Power_Set, Communication_Set, Transportation_Set,...
                priority_power_num, priority_transportation_num, priority_communication_num)
    
    Schedule_Power = Schedule{1};
    Schedule_Comm = Schedule{2};
    Schedule_Trans = Schedule{3};
    
    Date_Power = Date{1};
    Date_Comm = Date{2};
    Date_Trans = Date{3};
    
    % Save Schedule
    Total_Schedule{index + i} = Schedule;
    Total_Date{index + i} = Date;
% end
% 
% for i = 1:NRun * Nsamples
    % Recovery Process
    [Power, Comm, Trans] = Library.Repairation(time_horizon, Interdependence_Num, ReSchedule_Num, Power_Resource, Comm_Resource, Trans_Resource, Power_Func_Num, Trans_Func_Num, Comm_Func_Num, Schedule_Power, Schedule_Comm, Schedule_Trans, Power_Set, Communication_Set, Transportation_Set, Dictionary, System_Dependent_Factor, transGraph,powerGraph,commGraph,Neighborhood,Seperate_Scheduling, LinkDirectionChoice);
% end
% 
% for i = 1:NRun * Nsamples
    % Functionality
    for j = 1:time_horizon
        Functionality_Power(index + i,j) = Power(:,j);
        Functionality_Communication(index + i,j) = Comm(:,j);
        Functionality_Transportation(index + i,j) = Trans(:,j);
    end
    
    disp(strcat('------------- Finished: ', list(i).name, ' -------------'));
end

% Resilience
Resilience = Library.computeResilience(ResilienceMetricChoice, time_horizon, Functionality_Power, Functionality_Communication, Functionality_Transportation);
[FunctionalityStatistics, ResilienceStatistics] = Library.computeStatistics(Functionality_Power, Functionality_Communication, Functionality_Transportation, Resilience);


%% Output
% Export Datasave(strcat('./', deblank(Hostname), '/mat/Schedule.mat'), 'Total_Schedule');
if isempty(strcat('./', deblank(Hostname), '/mat/Schedule.mat'))
   save(strcat('./', deblank(Hostname), '/mat/Schedule.mat'), 'Total_Date', '-append');
else
    save(strcat('./', deblank(Hostname), '/mat/Schedule.mat'), 'Total_Date');
end
save(strcat('./', deblank(Hostname), '/mat/Schedule.mat'), 'Total_Schedule');
save(strcat('./', deblank(Hostname), '/mat/TaskTable.mat'), 'taskTable');
save(strcat('./', deblank(Hostname), '/mat/Functionality.mat'), 'Functionality_Transportation');
save(strcat('./', deblank(Hostname), '/mat/Functionality.mat'), 'Functionality_Power','-append');
save(strcat('./', deblank(Hostname), '/mat/Functionality.mat'), 'Functionality_Communication','-append');
save(strcat('./', deblank(Hostname), '/mat/Resilience.mat'), 'Resilience');
save(strcat('./', deblank(Hostname), '/mat/ResilienceStatistics.mat'), 'ResilienceStatistics');
save(strcat('./', deblank(Hostname), '/mat/FunctionalityStatistics.mat'), 'FunctionalityStatistics');

% Save Log
Library.SaveScheduleLog(Nsamples, NRun, Total_Schedule, Total_Date);
Library.SaveFunctionalityLog(Nsamples, NRun, time_horizon, Functionality_Power, Functionality_Communication, Functionality_Transportation);

% Plot Figures
Library.PlotFigure(Nsamples, NRun, time_horizon, Functionality_Power, Functionality_Communication, Functionality_Transportation);
Library2.PlotFigureFunctionality(time_horizon, FunctionalityStatistics);
Library2.PlotFigureResilience(ResilienceStatistics);      


% Profile
if Profile_Num == 1
    spmd
        mpiprofile('viewer');
        mpiprofile('off');
    end
    profile off
    profsave(profile('info'),strcat('./', deblank(Hostname), '/profile_log'));
end
%% 
% Clean Data
clear ans index i n Comm_Fun data_index Days m name Start_Day End_Day finish filename Pow_Fun Trans_Fun Total Total_Schedule Transportation_Set Power_Set Communication_Set;