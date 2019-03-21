% Create all data inpit and select model for simulator
%% General Input
% load input file
run('Data_Supplement_General.m');

% Sample number
Nsamples = 10;
NRun = 10;

% Choose Active_System
Active_System = {'Power', 'Transportation', 'Communication'};
[active_power, active_trans, active_comm] =  Library.ActiveSystem(Active_System);

% Profile 
Profile_Num = 1;

% Choose Scheduler
Scheduler_Num = 2;
ReSchedule_Num = 0;

% Choose Interdependence Model
Interdependence_Num = 0;

% Choose Functionality Model
Trans_Func_Num = 1;
Power_Func_Num = 1;
Comm_Func_Num = 1;

% Choose time_horizon
time_horizon = 365;

% Maximum number for each system can be repair at same time
Power_Resource = 8;
Comm_Resource = 8;
Trans_Resource = 15;

% Max Prority
Power_Priority = 4;
Comm_Priority = 4;
Trans_Priority = 4;

% load shakemap
load shakemap2.mat
%%