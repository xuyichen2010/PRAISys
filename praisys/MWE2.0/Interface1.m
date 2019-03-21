classdef Interface1
    methods(Static)
        % Select Scheduler Model
        function [Schedule, Date] = RepairSchedule(num, time, Max_Power, Max_Trans, Max_Comm, Power_Priority, Comm_Priority, Trans_Priority,...
                active_power, active_comm, active_trans, Power_Set, Communication_Set, Transportation_Set,...
                priority_power_num, priority_transportation_num, priority_communication_num)
            switch num
                case 1
                    if active_power
                        switch priority_power_num
                            case 1
                                [result_pow, pow_date] = Library.PowerSchedulePriority(1,Power_Set);
                            case 2
                                [result_pow, pow_date] = Library.PowerSchedulePriority(2,Power_Set);
                        end
                    else
                        result_pow = [];
                        pow_date = [];
                    end
                    
                    if active_trans
                        switch priority_transportation_num
                            case 1
                                [result_trans, trans_date] = Library.TransSchedulePriority(1,Transportation_Set);
                            case 2
                                [result_trans, trans_date] = Library.TransSchedulePriority(2,Transportation_Set);
                        end
                    else
                        result_trans = [];
                        trans_date = [];
                    end
                    if active_comm
                        switch priority_communication_num
                            case 1
                                [result_comm, comm_date] = Library.CommSchedulePriority(1,Communication_Set);
                            case 2
                                [result_comm, comm_date] = Library.CommSchedulePriority(2,Communication_Set);
                        end
                    else
                        result_comm = [];
                        comm_date = [];
                    end
                    
                    
%                     if active_trans
%                         [result_trans, trans_date] = Library.RepairSchedulePriority('Transportation', Transportation_Set, Trans_Priority);
%                     else

                    Schedule = {result_pow, result_comm, result_trans};
                    Date = {pow_date, comm_date, trans_date};
                    
                case 2
                    if active_power
                        [result_pow, pow_date] = Library.RepairSchedulEfficiency('Power', Max_Power, time, Power_Set);
                    else
                        result_pow = [];
                        pow_date = [];
                    end
                    
                    if active_trans
                        [result_trans, trans_date] = Library.RepairSchedulEfficiency('Transportation', Max_Trans, time, Transportation_Set);
                    else
                        result_trans = [];
                        trans_date = [];
                    end
                    
                    if active_comm
                        [result_comm, comm_date] = Library.RepairSchedulEfficiency('Communication', Max_Comm, time, Communication_Set);
                    else
                        result_comm = [];
                        comm_date = [];
                    end
                    Schedule = {result_pow, result_comm, result_trans};
                    Date = {pow_date, comm_date, trans_date};
            end
        end
        
        % Select Re-Scheduler Model
        function Schedule = RepairReSchedule(num, orig_Schedule, time, Max_Power, Max_Trans, Max_Comm, Power_Set, Communication_Set, Transportation_Set)
            switch num
                case 1
                    Schedule = Library.RepairScheduleReScheduleMean(orig_Schedule, time, Max_Power, Max_Trans, Max_Comm, Power_Set, Communication_Set, Transportation_Set);   
                case 2
                    Schedule = Library.RepairScheduleReScheduleActual(orig_Schedule, time, Max_Power, Max_Trans, Max_Comm, Power_Set, Communication_Set, Transportation_Set);      
            end
        end
        
        % Interdependence Selector
        function InterdependenceFactor(Interdependence_Num, CurrentWorking_Power, CurrentWorking_Comm, CurrentWorking_Trans, Power_Set, Communication_Set, Transportation_Set)
            switch Interdependence_Num
                case 1
                    Library.InterdenpendenceFactorCalculateBasic(CurrentWorking_Power, CurrentWorking_Comm, CurrentWorking_Trans, Power_Set, Communication_Set, Transportation_Set);
            end
        end
        
        % Create the 1/0 precedenceTable as input for scheduler
        function PreTableSep = createPreTableSep(Dictionary, active_power, active_comm, active_trans)
            if active_power
                result_pow = Library.createPreTableIndividual(Dictionary, 'Power');
            else
                result_pow = [];
            end
            
            if active_trans
                result_trans = Library.createPreTableIndividual(Dictionary,'Transportation');
            else
                result_trans = [];
            end
            
            if active_comm
                result_comm = Library.createPreTableIndividual(Dictionary,'Communication');
            else
                result_comm = [];
            end
            PreTableSep = {result_pow, result_comm, result_trans};
        end
        
        % Create the input table that contains all task information for
        % optimial scheduler
        function taskTable = createTaskTable(Dictionary, active_power, active_comm, active_trans)
            if active_power
                result_pow = Library.createTaskTableIndividual(Dictionary, 'Power');
            else
                result_pow = [];
            end
            
            if active_trans
                result_trans = Library.createTaskTableIndividual(Dictionary,'Transportation');
            else
                result_trans = [];
            end
            
            if active_comm
                result_comm = Library.createTaskTableIndividual(Dictionary,'Communication');
            else
                result_comm = [];
            end
            taskTable = {result_pow, result_comm, result_trans};
        end
        
        
        
        % Select Functionality Model and Calculate the System Functionality
%         function [Trans_Fun, Pow_Fun, Comm_Fun] = Functionality(Power_Func_Num, Trans_Func_Num, Comm_Func_Num, Power_Set, Communication_Set, Transportation_Set, powerGraph, commGraph, transGraph, Dictionary, LinkDirectionChoice)
%             Trans_Fun = -1;
%             Pow_Fun = -1;
%             Comm_Fun = -1;
%             
%             flag = 1;
%             
%             while flag
%                 change_trans = 0;
%                 change_pow = 0;
%                 change_comm = 0;
%                 
%                 switch Power_Func_Num
%                     case 0
%                         Pow_Fun = 0;
%                     case 1 % percentage of open bus (substation)
%                         tmp = Library.Functionality_PowerBasic(Power_Set);%Power_Set{1} = Bus(substation)
%                         if tmp ~= Pow_Fun
%                             Pow_Fun = tmp;
%                             change_pow = change_pow + 1;
%                         end
%                     
%                     case 2 % weighted network
%                         tmp = Library.Functionality_WeightNetwork(2,Power_Set);
%                         if tmp ~= Pow_Fun
%                             Pow_Fun = tmp;
%                             change_pow = change_pow + 1;
%                         end
%                       
%                     case 3 % neightborhood with power service 
%                         
% %                         [~,neighbourPowFunc,~,~] = Library.neighbourFunc(Dictionary);
%                         [totalPopulation,neighbourPowFunc,neighbourCommFunc,neighbourTransFunc] = Library.neighbourFunc(Dictionary);
% %                         if neighbourPowFunc ~= Pow_Fun
%                             Pow_Fun = neighbourPowFunc;
%                             change_pow = change_pow + 1;
% %                         end
%                         
%                     % ======= Graph theory related functionality parameter
%                     %   Gaveragedegree (scalar) - average value of all node degree in the network (0,+inf)
%                     %   L (scalar) - characteristic path length (0,+inf)
%                     %   EGlob (scalar) - global efficiency [0,1]
%                     
%                     case 91 % graph theory: average degree 
%                         result = Library.Functionality_GraphBasic(powerGraph, LinkDirectionChoice, Start_Day, End_Day,result); % have problem here, becuase of "Start_Day, End_Day,result"
%                         Pow_Fun = result(1,:);
%                         change_pow = change_pow + 1; % what is this for?
%                         
% %                     case 92 % graph theory: characteristic path length
% %                         result = Library.Functionality_GraphBasic(powerGraph, LinkDirectionChoice);
% %                         Pow_Fun = result(2,:);
% %                         change_pow = change_pow + 1; % what is this for?
% %                         
% %                     case 93 % graph theory: network efficiency
% %                         result = Library.Functionality_GraphBasic(powerGraph, LinkDirectionChoice);
% %                         Pow_Fun = result(3,:);
% %                         change_pow = change_pow + 1; % what is this for?    
%     
%                         
%                 end
%                         
%                         
%                 %end
%                 
%                 switch Trans_Func_Num
%                     case 0
%                         Trans_Fun = 0;
%                         
%                     case 1
%                         tmp = Library.Functionality_TransportationBasic(Transportation_Set);
%                         if tmp ~= Trans_Fun
%                             Trans_Fun = tmp;
%                             change_trans = change_trans + 1;
%                         end
%                         
%                     case 2
%                         tmp = Library.Functionality_WeightNetwork(1, Transportation_Set);
%                         if tmp ~= Trans_Fun
%                             Trans_Fun = tmp;
%                             change_trans = change_trans + 1;
%                         end
%                         
%                     case 3    
%                         [totalPopulation,neighbourPowFunc,neighbourCommFunc,neighbourTransFunc] = Library.neighbourFunc(Dictionary);
%                         if neighbourTransFunc ~= Trans_Fun
%                             Trans_Fun = neighbourTransFunc;
%                             change_trans = change_trans + 1;
%                         end
%                         
%                         
%                     % ======= Graph theory related functionality parameter
%                     %   Gaveragedegree (scalar) - average value of all node degree in the network (0,+inf)
%                     %   L (scalar) - characteristic path length (0,+inf)
%                     %   EGlob (scalar) - global efficiency [0,1]
%                     
% %                     case 91 % graph theory: average degree
% %                         result = Library.Functionality_GraphBasic(transGraph, LinkDirectionChoice); 
% %                         Trans_Fun = result(1,:);
% %                         change_trans = change_trans + 1; 
% %                         
% %                     case 92 % graph theory: characteristic path length
% %                         result = Library.Functionality_GraphBasic(transGraph, LinkDirectionChoice);
% %                         Trans_Fun = result(2,:);
% %                         change_trans = change_trans + 1; 
% %                         
% %                     case 93 % graph theory: network efficiency
% %                         result = Library.Functionality_GraphBasic(transGraph, LinkDirectionChoice);
% %                         Trans_Fun = result(3,:);
% %                         change_trans = change_trans + 1;      
%                         
%                 end
%                 
%                 switch Comm_Func_Num
%                     case 0
%                         Comm_Fun = 0;
%                     case 1
%                         tmp = Library.Functionality_CommunicationBasic(Communication_Set);
%                         if tmp ~= Comm_Fun
%                             Comm_Fun = tmp;
%                             change_comm = change_comm + 1;
%                         end
%                         
%                     case 3    
%                         [totalPopulation,neighbourPowFunc,neighbourCommFunc,neighbourTransFunc] = Library.neighbourFunc(Dictionary);
%                         if neighbourTransFunc ~= Trans_Fun
%                             Trans_Fun = neighbourTransFunc;
%                             change_trans = change_trans + 1;
%                         end
%                         
%                         
%                         
%                     % ======= Graph theory related functionality parameter
%                     %   Gaveragedegree (scalar) - average value of all node degree in the network (0,+inf)
%                     %   L (scalar) - characteristic path length (0,+inf)
%                     %   EGlob (scalar) - global efficiency [0,1]
%                     
% %                     case 91 % graph theory: average degree
% %                         result = Library.Functionality_GraphBasic(commGraph, LinkDirectionChoice); 
% %                         Trans_Fun = result(1,:);
% %                         change_trans = change_trans + 1; 
% %                         
% %                     case 92 % graph theory: characteristic path length
% %                         result = Library.Functionality_GraphBasic(commGraph, LinkDirectionChoice);
% %                         Trans_Fun = result(2,:);
% %                         change_trans = change_trans + 1; 
% %                         
% %                     case 93 % graph theory: network efficiency
% %                         result = Library.Functionality_GraphBasic(commGraph, LinkDirectionChoice);
% %                         Trans_Fun = result(3,:);
% %                         change_trans = change_trans + 1;       
% 
%                 end
%                 
%                 if change_pow == 0 && change_trans == 0 && change_comm == 0
%                     flag = 0;
%                 end
%             end
%         end
%         
        % Select Functionality Model and Calculate the Functionality
        
         function [Trans_Fun, Pow_Fun, Comm_Fun] = Functionality(Power_Func_Num, Trans_Func_Num, Comm_Func_Num, Power_Set, Communication_Set, Transportation_Set, powerGraph, commGraph, transGraph, Dictionary, LinkDirectionChoice)
            Trans_Fun = -1;
            Pow_Fun = -1;
            Comm_Fun = -1;
            
            flag = 1;
            
            while flag
                change_trans = 0;
                change_pow = 0;
                change_comm = 0;
                
                switch Power_Func_Num
                    case 0
                        Pow_Fun = 0;
                    case 1 % percentage of open bus (substation)
                        tmp = Library.Functionality_PowerBasic(Power_Set);%Power_Set{1} = Bus(substation)
                        if tmp ~= Pow_Fun
                            Pow_Fun = tmp;
                            change_pow = change_pow + 1;
                        end
                    
                    case 2 % weighted network
                        tmp = Library.Functionality_WeightNetwork(2,Power_Set);
                        if tmp ~= Pow_Fun
                            Pow_Fun = tmp;
                            change_pow = change_pow + 1;
                        end
                      
                    case 3 % neightborhood with power service 
                        
%                         [~,neighbourPowFunc,~,~] = Library.neighbourFunc(Dictionary);
                        [totalPopulation,neighbourPowFunc,neighbourCommFunc,neighbourTransFunc] = Library.neighbourFunc(Dictionary);
%                         if neighbourPowFunc ~= Pow_Fun
                            Pow_Fun = neighbourPowFunc;
                            change_pow = change_pow + 1;
%                         end
                        
                    % ======= Graph theory related functionality parameter
                    %   Gaveragedegree (scalar) - average value of all node degree in the network (0,+inf)
                    %   L (scalar) - characteristic path length (0,+inf)
                    %   EGlob (scalar) - global efficiency [0,1]
                    
                    case 91 % graph theory: average degree 
                        result = Library.Functionality_GraphBasic(powerGraph, LinkDirectionChoice, Start_Day, End_Day,result); % have problem here, becuase of "Start_Day, End_Day,result"
                        Pow_Fun = result(1,:);
                        change_pow = change_pow + 1; % what is this for?
                        
%                     case 92 % graph theory: characteristic path length
%                         result = Library.Functionality_GraphBasic(powerGraph, LinkDirectionChoice);
%                         Pow_Fun = result(2,:);
%                         change_pow = change_pow + 1; % what is this for?
%                         
%                     case 93 % graph theory: network efficiency
%                         result = Library.Functionality_GraphBasic(powerGraph, LinkDirectionChoice);
%                         Pow_Fun = result(3,:);
%                         change_pow = change_pow + 1; % what is this for?    
    
                        
                end
                        
                        
                %end
                
                switch Trans_Func_Num
                    case 0
                        Trans_Fun = 0;
                        
                    case 1
                        tmp = Library.Functionality_TransportationBasic(Transportation_Set);
                        if tmp ~= Trans_Fun
                            Trans_Fun = tmp;
                            change_trans = change_trans + 1;
                        end
                        
                    case 2
                        tmp = Library.Functionality_WeightNetwork(1, Transportation_Set);
                        if tmp ~= Trans_Fun
                            Trans_Fun = tmp;
                            change_trans = change_trans + 1;
                        end
                        
                    case 3    
                        [totalPopulation,neighbourPowFunc,neighbourCommFunc,neighbourTransFunc] = Library.neighbourFunc(Dictionary);
                        if neighbourTransFunc ~= Trans_Fun
                            Trans_Fun = neighbourTransFunc;
                            change_trans = change_trans + 1;
                        end
                        
                        
                    % ======= Graph theory related functionality parameter
                    %   Gaveragedegree (scalar) - average value of all node degree in the network (0,+inf)
                    %   L (scalar) - characteristic path length (0,+inf)
                    %   EGlob (scalar) - global efficiency [0,1]
                    
%                     case 91 % graph theory: average degree
%                         result = Library.Functionality_GraphBasic(transGraph, LinkDirectionChoice); 
%                         Trans_Fun = result(1,:);
%                         change_trans = change_trans + 1; 
%                         
%                     case 92 % graph theory: characteristic path length
%                         result = Library.Functionality_GraphBasic(transGraph, LinkDirectionChoice);
%                         Trans_Fun = result(2,:);
%                         change_trans = change_trans + 1; 
%                         
%                     case 93 % graph theory: network efficiency
%                         result = Library.Functionality_GraphBasic(transGraph, LinkDirectionChoice);
%                         Trans_Fun = result(3,:);
%                         change_trans = change_trans + 1;      
                        
                end
                
                switch Comm_Func_Num
                    case 0
                        Comm_Fun = 0;
                    case 1
                        tmp = Library.Functionality_CommunicationBasic(Communication_Set);
                        if tmp ~= Comm_Fun
                            Comm_Fun = tmp;
                            change_comm = change_comm + 1;
                        end
                        
                    case 3    
                        [totalPopulation,neighbourPowFunc,neighbourCommFunc,neighbourTransFunc] = Library.neighbourFunc(Dictionary);
                        if neighbourTransFunc ~= Trans_Fun
                            Trans_Fun = neighbourTransFunc;
                            change_trans = change_trans + 1;
                        end
                        
                        
                        
                    % ======= Graph theory related functionality parameter
                    %   Gaveragedegree (scalar) - average value of all node degree in the network (0,+inf)
                    %   L (scalar) - characteristic path length (0,+inf)
                    %   EGlob (scalar) - global efficiency [0,1]
                    
%                     case 91 % graph theory: average degree
%                         result = Library.Functionality_GraphBasic(commGraph, LinkDirectionChoice); 
%                         Trans_Fun = result(1,:);
%                         change_trans = change_trans + 1; 
%                         
%                     case 92 % graph theory: characteristic path length
%                         result = Library.Functionality_GraphBasic(commGraph, LinkDirectionChoice);
%                         Trans_Fun = result(2,:);
%                         change_trans = change_trans + 1; 
%                         
%                     case 93 % graph theory: network efficiency
%                         result = Library.Functionality_GraphBasic(commGraph, LinkDirectionChoice);
%                         Trans_Fun = result(3,:);
%                         change_trans = change_trans + 1;       

                end
                
                if change_pow == 0 && change_trans == 0 && change_comm == 0
                    flag = 0;
                end
            end
        end
        
        
%         function [Trans_Fun, Pow_Fun, Comm_Fun] = Functionality(Power_Func_Num, Trans_Func_Num, Comm_Func_Num, Power_Set, Communication_Set, Transportation_Set)
%             Trans_Fun = -1;
%             Pow_Fun = -1;
%             Comm_Fun = -1;
%             
%             flag = 1;
%             
%             while flag
%                 change_trans = 0;
%                 change_pow = 0;
%                 change_comm = 0;
%                 
%                 switch Power_Func_Num
%                     case 0
%                         Pow_Fun = 0;
%                     case 1
%                         tmp = Library.Functionality_PowerBasic(Power_Set{1});
%                         if tmp ~= Pow_Fun
%                             Pow_Fun = tmp;
%                             change_pow = change_pow + 1;
%                         end
%                 end
%                 
%                 switch Trans_Func_Num
%                     case 0
%                         Trans_Fun = 0;
%                         
%                     case 1
%                         tmp = Library.Functionality_TransportationBasic(Transportation_Set);
%                         if tmp ~= Trans_Fun
%                             Trans_Fun = tmp;
%                             change_trans = change_trans + 1;
%                         end
%                 end
%                 
%                 switch Comm_Func_Num
%                     case 0
%                         Comm_Fun = 0;
%                     case 1
%                         tmp = Library.Functionality_CommunicationBasic(Communication_Set);
%                         if tmp ~= Comm_Fun
%                             Comm_Fun = tmp;
%                             change_comm = change_comm + 1;
%                         end
% 
%                 end
%                 
%                 if change_pow == 0 && change_trans == 0 && change_comm == 0
%                     flag = 0;
%                 end
%             end
%         end
    end
end