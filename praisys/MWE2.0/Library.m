classdef Library
    methods(Static)
        %% Active System
        function [active_power, active_trans, active_comm] = ActiveSystem(System)
            active_power = false;
            active_trans = false;
            active_comm = false;
            
            for i = 1:length(System)
                if strcmp(System{i}, 'Power')
                    active_power = true;
                end
                
                if strcmp(System{i}, 'Transportation')
                    active_trans = true;
                end
                
                if strcmp(System{i}, 'Communication')
                    active_comm = true;
                end
            end
        end
        
        %% Sampling
        function [powerGraph, commGraph, transGraph] = Sampling(Nsamples, NRun, Hostname, IM, IMx, IMy, active_power, active_comm, active_trans,transGraph, powerGraph, commGraph,Prob_Magic_Battery)
            % Create and Save sample
            [sumTaskHash, sumDamageTaskHash] = Library.setUpHashes();
            
            
            for n = 1:Nsamples
                taskIndex = 1;
                % Save Data (Need to use load command to view the data)
                % Create Three Infrastructure Systems
                filename = strcat('./', deblank(Hostname), '/Original_Data.mat');
                [Power_Set, Communication_Set, Transportation_Set,Dictionary, Neighborhood] = Library.ResetData(filename);
                
                
                
                % Initial Damage Evaluation:
                [transGraph,powerGraph,commGraph,taskIndex] = Library.DamageAndStop(IM, IMx, IMy, active_power, active_comm, active_trans, Power_Set, Communication_Set, Transportation_Set, Dictionary, Neighborhood,transGraph, powerGraph, commGraph,sumTaskHash, sumDamageTaskHash,taskIndex,Prob_Magic_Battery);
                
                Total = {Power_Set, Communication_Set, Transportation_Set, Dictionary, Neighborhood};
                
                % Save Log
                Library.SaveDataLog(n, Power_Set, Communication_Set, Transportation_Set);
                
                for m = 1:NRun
                    filename = strcat('./', deblank(Hostname), '/mat/Data_Sample_', num2str(n), '_Run_',num2str(m), '.mat');
                    save(filename, 'Total');
                end
            end
        end
        
        %% Disaster Manager
        % Initial Damage Evaluation, Evaluate Stoped or Cascading Damaged
        % Compoment and Calculate the initial Functionnality for each Road
        function [transGraph,powerGraph,commGraph,taskIndex] = DamageAndStop(IM,IMx,IMy, active_power, active_comm, active_trans, Power_Set, Communication_Set, Transportation_Set, Dictionary, Neighborhood, transGraph, powerGraph, commGraph,sumTaskHash, sumDamageTaskHash,taskIndex,Prob_Magic_Battery)
            % Initial Damage Evaluation
            if active_power
                for i = 1:length(Power_Set)
                    if ~isempty(Power_Set{i})
                        taskIndex = Library.DamageEval(Power_Set{i},1,IM,IMx,IMy,Dictionary,sumTaskHash, sumDamageTaskHash,taskIndex,Prob_Magic_Battery);
                    end
                end
            end
            
            if active_comm
                for i = 1:length(Communication_Set)
                    if ~isempty(Communication_Set{i})
                        taskIndex = Library.DamageEval(Communication_Set{i},1,IM,IMx,IMy,Dictionary,sumTaskHash, sumDamageTaskHash,taskIndex,Prob_Magic_Battery);
                    end
                end
            end
            
            if active_trans
                for i = 1:length(Transportation_Set)
                    if ~isempty(Transportation_Set{i})
                        taskIndex = Library.DamageEval(Transportation_Set{i},1,IM,IMx,IMy, Dictionary,sumTaskHash, sumDamageTaskHash,taskIndex,Prob_Magic_Battery);
                    end
                end
            end
            
            % Evaluate Stoped or Cascading Damaged Compoment
            Library.StopedEval(active_power, active_comm, active_trans, Power_Set, Communication_Set, Transportation_Set, Dictionary, Neighborhood,sumTaskHash, sumDamageTaskHash,taskIndex);
            transGraph = Library.RemoveTransGraph(Transportation_Set, transGraph);
            powerGraph = Library.RemovePowerGraph(Power_Set, powerGraph);
            commGraph = Library.RemoveCommGraph(Communication_Set, commGraph);
            
            
        end
        
        % DamageEval function needs to be replaced by a new fragility
        % analysis function.
        function taskIndex = DamageEval(cell,Event,IM,IMx,IMy, Dictionary,sumTaskHash, sumDamageTaskHash,taskIndex,Prob_Magic_Battery)
            
            
            switch cell{1}.Class
                case {'Centraloffice','CommunicationTower','TrafficLight'}
                    for i = 1:size(cell,2)
                        if (rand > Prob_Magic_Battery)
                            cell{i}.Battery = 1;
                            %disp(cell{i});
                        else
                            cell{i}.Battery = 0;
                        end
                    end
            end
            
            switch cell{1}.Class
                case {'Bus', 'Generator', 'Centraloffice', 'Router', 'CommunicationTower','TransmissionTower'}
                    for i = 1:size(cell,2)
                        Intensity = interp2(IMx,IMy,IM,cell{i}.Location(1),cell{i}.Location(2));
                        % assign probabilty of failure we can improve it later
                        Prob_Failure = Library.Prob_Failure(Intensity,cell{i});
                        Y = [1, Prob_Failure, 0];
                        aa = rand;
                        index = 0;
                        for idx = 1:length(Y)-1
                            if lt((aa - Y(idx))*(aa > Y(idx + 1)),0)
                                index = idx - 1;
                            end
                        end
                        
                        cell{i}.DamageLevel = index ;
                        if isempty(cell{i}.DamageLevel)
                            tmp = 0;
                        end
                        
                        %                             disp(cell{i}.DamageLevel);
                        Library2.Recovery(cell{i});
                        if cell{i}.DamageLevel > 0
                            cell{i}.Status='Damaged';
                            cell{i}.Functionality = 0;
                            if ~strcmp(cell{1}.Class, 'Generator')
                                [cell,taskIndex] = Library.assignTask(cell,i,sumTaskHash, sumDamageTaskHash, Dictionary,taskIndex);
                            end
                            
                        end
                        
                    end
                    
                case {'Road' 'Cellline', 'Branch'}
                    for i = 1:size(cell,2)
                        Intensity=interp2(IMx,IMy,IM,cell{i}.Start_Location(1),cell{i}.Start_Location(2));
                        %Intensity=Intensity + interp2(IMx,IMy,IM,cell{i}.End_Location(1),cell{i}.End_Location(2));
                        % assign probabilty of failure we can improve it later
                        Prob_Failure = Library.Prob_Failure(Intensity,cell{i});
                        Y = [1, Prob_Failure, 0];
                        aa = rand;
                        index = 0;
                        for idx = 1:length(Y)-1
                            if lt((aa - Y(idx))*(aa > Y(idx + 1)),0)
                                index = idx - 1;
                            end
                        end
                        
                        cell{i}.DamageLevel = index;
                        
                        if isempty(cell{i}.DamageLevel)
                            tmp = 0;
                        end
                        Library2.Recovery(cell{i});
                        if cell{i}.DamageLevel > 0
                            cell{i}.Status = 'Damaged';
                            cell{i}.Functionality = 0;
                            [cell,taskIndex] = Library.assignTask(cell,i,sumTaskHash, sumDamageTaskHash, Dictionary,taskIndex);
                        end
                        
                    end
                case {'TrafficLight', 'Bridge'}
                    for i = 1:size(cell,2)

                        %for subcomponent
                        if strcmp(cell{i}.Class,'Bridge') && cell{i}.HasSub == 1
                            newcells = [cell{i}.ColumnSet,cell{i}.ColumnFoundSet,cell{i}.AbutmentSet,cell{i}.AbutmentFoundSet,cell{i}.BearingSet,cell{i}.SlabSet]
                            newcells = num2cell(newcells)
                            for j = 1:length(newcells)
                                Intensity = interp2(IMx,IMy,IM,newcells{j}.Location(1),newcells{j}.Location(2));
                                % assign probabilty of failure, we can improve it later
                                Prob_Failure = Library.Prob_Failure(Intensity,newcells{j});
                                Y = [1, Prob_Failure, 0];
                                aa = rand;
                                index = 0;
                                for idx = 1:length(Y)-1
                                    if lt((aa - Y(idx))*(aa > Y(idx + 1)),0)
                                        index = idx - 1;
                                    end
                                end

                                newcells{j}.DamageLevel = index;
                                if isempty(newcells{j}.DamageLevel)
                                    tmp = 0;
                                end
                                Library2.Recovery(newcells{j});
                                if newcells{j}.DamageLevel > 0
                                    newcells{j}.Status='Damaged';
                                    cell{i}.Status='Damaged';
                                    [newcells,taskIndex] = Library.assignTask(newcells,j,sumTaskHash, sumDamageTaskHash, Dictionary,taskIndex);

                                end                    
                            end
                            
                            
                        elseif cell{i}.Destructible == 1
                            
                            Intensity = interp2(IMx,IMy,IM,cell{i}.Location(1),cell{i}.Location(2));
                            % assign probabilty of failure we can improve it later
                            Prob_Failure = Library.Prob_Failure(Intensity,cell{i});
                            Y = [1, Prob_Failure, 0];
                            aa = rand;
                            index = 0;
                            for idx = 1:length(Y)-1
                                if lt((aa - Y(idx))*(aa > Y(idx + 1)),0)
                                    index = idx - 1;
                                end
                            end
                            
                            cell{i}.DamageLevel = index;
                            if isempty(cell{i}.DamageLevel)
                                tmp = 0;
                            end
                            Library2.Recovery(cell{i});
                            if cell{i}.DamageLevel > 0
                                cell{i}.Status='Damaged';
                                cell{i}.Functionality = 0;
                                
                                [cell,taskIndex] = Library.assignTask(cell,i,sumTaskHash, sumDamageTaskHash, Dictionary,taskIndex);
                                
                            end
                            
                        end
                        
                    end
            end
        end
        
        % Calculated the exceeding probability of different damage state levels
        % Prob_Failure = ExceedingProbability[slight, moderate, extensive, complete]
        function Prob_Failure = Prob_Failure(Intensity,Object)
            Prob_Failure = zeros(1,size(Object.Fragility,1));
            for idx = 1:size(Object.Fragility,1)
                clearvars mu sigma;
                mean = Object.Fragility(idx,1);
                std = Object.Fragility(idx,2);
                mu = log(mean) - 0.5*log(1+ (std^2)/(mean^2));
                sigma = sqrt(log(1+ (std^2)/(mean^2)));
                Prob_Failure(idx) =  cdf('lognormal',Intensity,mu,sigma);
            end
            Prob_Failure = Prob_Failure(1);
        end
        
        % Change status for stoped or cascading damaged component
        function StopedEval(active_power, active_comm, active_trans, Pow, Comm, Trans, Dictionary,Neighborhood,sumTaskHash, sumDamageTaskHash,taskIndex)
            % Field
            Branch= Pow{1};
            Bus= Pow{2};
            Generator= Pow{3};
            TransTower = Pow{4};
            
            
            Centraloffice = Comm{2};
            Router = Comm{3};
            Cellline = Comm{4};
            CommTower = Comm{5};
            
            Road = Trans{1};
            Bridge = Trans{2};
            TrafficLight = Trans{3};
            
            Branch_list = [];
            Bus_list = [];
            
            TrafficLight_list = [];
            Bridge_list = [];
            Road_list = [];
            
            Antenna_list = [];
            Router_list = [];
            Cellline_list = [];
            Centraloffice_list = [];
            Neighborhood_list = [];
            
            
            % Power System
            
            if active_power
                % cascading failure
                for i = 1:length(Bus)
                    if strcmp(Bus{i}.Status, 'Damaged') % If Bus damaged, branches stoped
                        for j = 1:length(Bus{i}.Branch)
                            if ~strcmp(Branch{Bus{i}.Branch(j)}.Status, 'Damaged')
                                Branch{Bus{i}.Branch(j)}.Status = 'Stoped';
                            end
                        end
                    end
                    
                end
                
                for i = 1:length(TransTower)
                    if strcmp(TransTower{i}.Status, 'Damaged') % If Bus damaged, branches stoped
                        if TransTower{i}.DamageLevel == 4
                            for j = 1:length(TransTower{i}.Branch)
                                if ~strcmp(Branch{TransTower{i}.Branch(j)}.Status, 'Damaged')
                                    Branch{TransTower{i}.Branch(j)}.Status = 'Damaged';
                                    Branch{TransTower{i}.Branch(j)}.Functionality = 0;
                                    Branch{TransTower{i}.Branch(j)}.DamageLevel = 4;
                                    [Branch,taskIndex] = Library.assignTask(Branch,TransTower{i}.Branch(j),sumTaskHash, sumDamageTaskHash, Dictionary,taskIndex);
                                end
                                
                            end
                        else
                            for j = 1:length(TransTower{i}.Branch)
                                if ~strcmp(Branch{TransTower{i}.Branch(j)}.Status, 'Damaged')
                                    Branch{TransTower{i}.Branch(j)}.Status = 'Stoped';
                                    Branch{TransTower{i}.Branch(j)}.Functionality = 0;
                                end
                            end
                        end
                    end
                    
                end
                
                % Bus
                for i = 1:length(Bus)
                    if ~isempty(Bus{i}.Generator) && strcmp(Bus{i}.Status, 'Open') % If generator damaged, bus stoppend, bus.branch stoped.
                        bus = extractAfter(Bus{i}.Generator, 9);
                        bus = str2num(bus);
                        if strcmp(Generator{bus}.Status, 'Damaged')
                            if ~strcmp(Bus{i}.Status, 'Damaged')
                                Bus{i}.Status = 'Stoped';
                                for j = 1:length(Bus{i}.Branch)
                                    if ~strcmp(Branch{Bus{i}.Branch(j)}.Status, 'Damaged')
                                        Branch{Bus{i}.Branch(j)}.Status = 'Stoped';
                                        Branch{Bus{i}.Branch(j)}.Functionality = 0;
                                    end
                                end
                            end
                        end
                    end
                end
                
                for i = 1:length(Branch)
                    obj1 = Dictionary(Branch{i}.connectedObj1);
                    obj2 = Dictionary(Branch{i}.connectedObj2);
                    if ~strcmp(obj1{1}.Status, 'Open') || ~strcmp(obj2{1}.Status, 'Open')
                        if ~strcmp(Branch{i}.Status, 'Damaged')
                            Branch{i}.Status = 'Stoped';
                            Branch{i}.Functionality = 0;
                        end
                    end
                end
                for i = 1:length(Branch)
                    if ~strcmp(Branch{i}.Status, 'Open')
                        Branch_list = [Branch_list, i];
                    end
                end
                
                for i = 1:length(Bus)
                    if ~strcmp(Bus{i}.Status, 'Open')
                        Bus_list = [Bus_list, i];
                        for j = 1:length(Bus{i}.Neighborhood)
                            temp = Dictionary(Bus{i}.Neighborhood{j});
                            temp = temp{1};
                            temp.PowerStatus = 0;
                            temp = Dictionary(Bus{i}.Neighborhood_Power_Link{j});
                            temp = temp{1};
                            temp.Status = 'Stoped';
                        end
                    end
                end
            end
            
            
            % Transportation System
            if active_trans
                for i = 1:length(TrafficLight)
                    if strcmp(TrafficLight{i}.Status, 'Damaged')
                        TrafficLight_list = [TrafficLight_list, i];
                    else
                        bus = extractAfter(TrafficLight{i}.Bus, 3);
                        bus = str2num(bus);
                        if ismember(bus, Bus_list)
                            TrafficLight{i}.Status = 'Stoped';
                            TrafficLight{i}.Functionality = 0;
                            TrafficLight_list = [TrafficLight_list, i];
                        end
                    end
                end
                
                for i = 1:length(Road)
                    if strcmp(Road{i}.Status, 'Damaged')
                        Road_list = [Road_list, i];
                    else
                        flag = 0;
                        
                        for j = 1:length(Road{i}.Bridge_Carr)
                            if strcmp(Bridge{Road{i}.Bridge_Carr(j)}.Status, 'Damaged')
                                flag = flag + 1;
                            end
                        end
                        
                        for j = 1:length(Road{i}.Bridge_Cross)
                            if strcmp(Bridge{Road{i}.Bridge_Cross(j)}.Status, 'Damaged')
                                flag = flag + 1;
                            end
                        end
                        
                        if flag ~= 0
                            Road{i}.Status = 'Stoped';
                            Road{i}.Functionality = 0;
                            Road_list = [Road_list, i];
                        end
                    end
                end
                for i = 1:length(Road)
                    if ~strcmp(Road{i}.Status, 'Open')
                        temp = Dictionary(strcat('RoadNode',num2str(Road{i}.Start_Node)));
                        temp = temp{1};
                        for j = 1:length(temp.Neighborhood)
                            t1 = Dictionary(temp.Neighborhood{j});
                            t1 = t1{1};
                            t1.TransStatus = 0;
                            t1 = Dictionary(temp.Neighborhood_Trans_Link{j});
                            t1 = t1{1};
                            t1.Status = 'Stoped';
                        end
                        temp = Dictionary(strcat('RoadNode',num2str(Road{i}.End_Node)));
                        temp = temp{1};
                        for j = 1:length(temp.Neighborhood)
                            t1 = Dictionary(temp.Neighborhood{j});
                            t1 = t1{1};
                            t1.TransStatus = 0;
                            t1 = Dictionary(temp.Neighborhood_Trans_Link{j});
                            t1 = t1{1};
                            t1.Status = 'Stoped';
                        end
                    end
                end
            end
            
            % Communication System
            if active_comm
                
                for i = 1:length(Router)
                    if strcmp(Router{i}.Status, 'Damaged')
                        Router_list = [Router_list, i];
                    end
                end
                
                for i = 1:length(Cellline)
                    if strcmp(Cellline{i}.Status, 'Damaged')
                        Cellline_list = [Cellline_list, i];
                    else
                        bus = extractAfter(Cellline{i}.Bus, 3);
                        bus = str2num(bus);
                        if ismember(bus, Bus_list)
                            Cellline{i}.Status = 'Stoped';
                            Cellline{i}.Functionality = 0;
                            Cellline_list = [Cellline_list, i];
                        end
                    end
                end
                
                for i = 1:length(CommTower)
                    if ~strcmp(CommTower{i}.Status, 'Damaged')
                        bus = extractAfter(CommTower{i}.Bus, 3);
                        bus = str2num(bus);
                        if ismember(bus, Bus_list)
                            CommTower{i}.Status = 'Stoped';
                            CommTower{i}.Functionality = 0;
                        end
                    end
                end
                
                for i =1:length(Centraloffice)
                    if strcmp(Centraloffice{i}.Status, 'Damaged')
                        Centraloffice_list = [Centraloffice_list, i];
                        for j = 1:length(Centraloffice{i}.Router)
                            Router{Centraloffice{i}.Router(j)}.Status = 'Damaged';
                            Router{Centraloffice{i}.Router(j)}.Functionality = 0;
                            Router_list = [Router_list, i];
                        end
                    else
                        bus = extractAfter(Centraloffice{i}.Bus, 3);
                        bus = str2num(bus);
                        if ismember(bus, Bus_list)
                            Centraloffice{i}.Status = 'Stoped';
                            Centraloffice{i}.Functionality = 0;
                            Centraloffice_list = [Centraloffice_list, i];
                        end
                    end
                end
                
                for i = 1:length(Centraloffice)
                    if ~strcmp(Centraloffice{i}.Status, 'Open')
                        for j = 1:length(Centraloffice{i}.Neighborhood)
                            temp = Dictionary(Centraloffice{i}.Neighborhood{j});
                            temp = temp{1};
                            temp.CommStatus = 0;
                            temp = Dictionary(Centraloffice{i}.Neighborhood_Comm_Link{j});
                            temp = temp{1};
                            temp.Status = 'Stoped';
                        end
                    end
                end
            end
            
            for i = 1:length(Neighborhood)
                if Neighborhood{i}.PowerStatus ~= 1|| Neighborhood{i}.CommStatus ~= 1||Neighborhood{i}.TransStatus ~= 1
                    Neighborhood{i}.Status = 'Stoped';
                    Neighborhood{i}.Functionality = 0;
                end
            end
        end
        
        % Remove damaged nodes and edges after the damage assesment
        function G = RemoveTransGraph(Trans_Set, G)
            hash = containers.Map('KeyType','double','ValueType','char');
            road_Set = Trans_Set{1};
            roadnode_Set = Trans_Set{4};
            for i = 1:length(roadnode_Set)
                hash(roadnode_Set{i}.nodeID) = roadnode_Set{i}.uniqueID;
            end
            s = [];
            t = [];
            index = 1;
            for i = 1:length(road_Set)
                if ~strcmp(road_Set{i}.Status, 'Open')
                    s{index} = hash(road_Set{i}.Start_Node);
                    t{index} =  hash(road_Set{i}.End_Node);
                    index = index + 1;
                end
            end
            G = rmedge(G,s,t);
        end
        
        % Remove damaged nodes and edges after the damage assesment
        % assuming that generators (Power_Set{3}) do not fail!
        function G = RemovePowerGraph(Power_Set, G)
            Branch = Power_Set{1};
            Bus = Power_Set{2};
            TransTower = Power_Set{4};
            s = [];
            t = [];
            st = [];
            tt = [];
            Lst = [];
            s2 = [];
            t2 = [];
            index = 1;
            
            for i = 1:length(Bus)
                if ~strcmp(Bus{i}.Status, 'Open')
                    G = rmnode(G,Bus{i}.uniqueID);
                end
            end
            
            for i = 1:length(TransTower)
                if ~strcmp(TransTower{i}.Status, 'Open')
                    G = rmnode(G,TransTower{i}.uniqueID);
                end
            end
            
            for i = 1:length(Branch)
                if ~strcmp(Branch{i}.Status, 'Open')
                    s{index} = Branch{i}.connectedObj1;
                    t{index} =  Branch{i}.connectedObj2;
                    index = index + 1;
                end
            end
            
            % check Nodes in cellls of s and t in the table of G.Nodes or not
            st = cell2table(s'); tt = cell2table(t');
            st.Properties.VariableNames = {'Name'}; tt.Properties.VariableNames = {'Name'};
            Lst = [ismember(st,G.Nodes), ismember(tt,G.Nodes)];
            
            % find nodes in s and t that are also in G.Nodes 
            id = find(sum(Lst,2) == 2); 
            if length(id)>0
                for ii = 1:length(id)
                    s2{ii} = s{id(ii)};
                    t2{ii} = t{id(ii)};
                end
                G = rmedge(G,s2,t2);
            end

        end
        
        % Remove damaged nodes and edges after the damage assesment
        function G = RemoveCommGraph(Comm, G)
            Centraloffice_Set = Comm{2};
            Cellline_Set = Comm{4};
            CommunicationTower_Set = Comm{5};
            
            s = [];
            t = [];
            st = [];
            tt = [];
            Lst = [];
            s2 = [];
            t2 = [];
            
            index = 1;
            
            for i = 1:length(Centraloffice_Set)
                if ~strcmp(Centraloffice_Set{i}.Status, 'Open')
                    G = rmnode(G,Centraloffice_Set{i}.uniqueID);
                end
            end
            for i = 1:length(CommunicationTower_Set)
                if ~strcmp(CommunicationTower_Set{i}.Status, 'Open')
                    G = rmnode(G,CommunicationTower_Set{i}.uniqueID);
                end
            end
            
            for i = 1:length(Cellline_Set)
                if ~strcmp(Cellline_Set{i}.Status, 'Open')
                    s{index} = Cellline_Set{i}.connectedObj1;
                    t{index} =  Cellline_Set{i}.connectedObj2;
                    index = index + 1;
                end
            end
            
            % check Nodes in cellls of s and t in the table of G.Nodes or not
            st = cell2table(s'); tt = cell2table(t');
            st.Properties.VariableNames = {'Name'}; tt.Properties.VariableNames = {'Name'};
            Lst = [ismember(st,G.Nodes), ismember(tt,G.Nodes)];
            
            % find nodes in s and t that are also in G.Nodes 
            id = find(sum(Lst,2) == 2); 
            if length(id)>0
                for ii = 1:length(id)
                    s2{ii} = s{id(ii)};
                    t2{ii} = t{id(ii)};
                end
                G = rmedge(G,s2,t2);
            end     
           

        end
        
        %% Scheduler
        % Priority Scheduler for power
        % num: 1 for volatage 2 for population
        function [Schedule, Return_Date] = TransSchedulePriority(num,Set)
            Return_Date = [];
            Road = Set{1};
            Bridge = Set{2};
            TrafficLight = Set{3};
            Rank = [];
            index = 1;
            if num == 1
                for i = 1:length(Bridge)
                    if strcmp(Bridge{i}.Status, 'Damaged')
                        Rank(end+1,:) = [i, Bridge{i}.MaxSpanLength];
                    end
                end
            else
                for i = 1:length(Bridge)
                    if strcmp(Bridge{i}.Status, 'Damaged')
                        Rank(end+1,:) = [i, Bridge{i}.Traffic];
                    end
                end
            end
            if ~isempty(Rank)
                sortedBridge = sortrows(Rank,2);
                for i = 1:length(sortedBridge)
                    bridgeCurrent = sortedBridge(length(sortedBridge) - i + 1,1);
                    tasks = Bridge{bridgeCurrent}.taskUniqueIds;
                    for j = 1:length(tasks)
                        Schedule{index} = strcat('Bridge/',num2str(bridgeCurrent));
                        Schedule{index} = strcat(Schedule{index}, '/');
                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                        index = index + 1;
                    end
                end
            end
            
            for i = 1:length(Road)
                if strcmp(Road{i}.Status, 'Damaged')
                    tasks = Road{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        Schedule{index} = strcat('Road/',num2str(i));
                        Schedule{index} = strcat(Schedule{index}, '/');
                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                        index = index + 1;
                    end
                end
            end
            
            for i = 1:length(TrafficLight)
                if strcmp(TrafficLight{i}.Status, 'Damaged')
                    tasks = TrafficLight{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        Schedule{index} = strcat('TrafficLight/',num2str(i));
                        Schedule{index} = strcat(Schedule{index}, '/');
                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                        index = index + 1;
                    end
                end
            end
        end
        % Priority Scheduler for power
        % num: 1 for volatage 2 for population
        function [Schedule, Return_Date] = PowerSchedulePriority(num,Set)
            Return_Date = [];
            Branch= Set{1};
            Bus= Set{2};
            Generator= Set{3};
            TransmissionTower = Set{4};
            Rank = [];
            index = 1;
            if num == 1
                for i = 1:length(Bus)
                    if strcmp(Bus{i}.Status, 'Damaged')
                        Rank(end+1,:) = [i, Bus{i}.Capacity];
                    end
                end
            else
                for i = 1:length(Bus)
                    if strcmp(Bus{i}.Status, 'Damaged')
                        Rank(end+1,:) = [i, Bus{i}.PopulationServed];
                    end
                end
            end
            if ~isempty(Rank)
                sortedBus = sortrows(Rank,2);
                for i = 1:length(sortedBus)
                    busCurrent = sortedBus(length(sortedBus) - i + 1,1);
                    tasks = Bus{busCurrent}.taskUniqueIds;
                    for j = 1:length(tasks)
                        Schedule{index} = strcat('Bus/',num2str(busCurrent));
                        Schedule{index} = strcat(Schedule{index}, '/');
                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                        index = index + 1;
                    end
                end
            end
            for i = 1:length(Generator)
                if strcmp(Generator{i}.Status, 'Damaged')
                    Schedule{index} = strcat('Generator/',num2str(i));
                    index = index + 1;
                end
            end
            
            for i = 1:length(Branch)
                if strcmp(Branch{i}.Status, 'Damaged')
                    tasks = Branch{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        Schedule{index} = strcat('Branch/',num2str(i));
                        Schedule{index} = strcat(Schedule{index}, '/');
                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                        index = index + 1;
                    end
                end
            end
            for i = 1:length(TransmissionTower)
                if strcmp(TransmissionTower{i}.Status, 'Damaged')
                    tasks = TransmissionTower{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        Schedule{index} = strcat('TransmissionTower/',num2str(i));
                        Schedule{index} = strcat(Schedule{index}, '/');
                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                        index = index + 1;
                    end
                end
            end
        end
        function [Schedule, Return_Date] = CommSchedulePriority(num,Set)
            Return_Date = [];
            Centraloffice = Set{2};
            Router = Set{3};
            Cellline = Set{4};
            CommunicationTower = Set{5};
            Rank = [];
            index = 1;
            if num == 1
                for i = 1:length(Centraloffice)
                    if strcmp(Centraloffice{i}.Status, 'Damaged')
                        Rank(end+1,:) = [i, Centraloffice{i}.PopulationServed];
                    end
                end
            else
            end
            if ~isempty(Rank)
                sortedCentral = sortrows(Rank,2);
                for i = 1:length(sortedCentral)
                    centralCurrent = sortedCentral(length(sortedCentral) - i + 1,1);
                    tasks = Centraloffice{centralCurrent}.taskUniqueIds;
                    for j = 1:length(tasks)
                        Schedule{index} = strcat('CentralOffice/',num2str(centralCurrent));
                        Schedule{index} = strcat(Schedule{index}, '/');
                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                        index = index + 1;
                    end
                end
            end
            
            for i = 1:length(Router)
                if strcmp(Router{i}.Status, 'Damaged') 
                    tasks = Router{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        Schedule{index} = strcat('Router/',num2str(i));
                        Schedule{index} = strcat(Schedule{index}, '/');
                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                        index = index + 1;
                    end
                end
            end
            
            for i = 1:length(Cellline)
                if strcmp(Cellline{i}.Status, 'Damaged') 
                    tasks = Cellline{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        Schedule{index} = strcat('Cellline/',num2str(i));
                        Schedule{index} = strcat(Schedule{index}, '/');
                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                        index = index + 1;
                    end
                end
            end
            
            for i = 1:length(CommunicationTower)
                if strcmp(CommunicationTower{i}.Status, 'Damaged')
                    tasks = CommunicationTower{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        Schedule{index} = strcat('CommunicationTower/',num2str(i));
                        Schedule{index} = strcat(Schedule{index}, '/');
                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                        index = index + 1;
                    end
                end
            end
        end
        % Create repair schedule according to the importatance of component
        function [Return_Schedule, Return_Date] = RepairSchedulePriority(System, Set, Max)
            Schedule = {};
            if strcmp(System, 'Power')
                Branch= Set{1};
                Bus= Set{2};
                Generator= Set{3};
                TransmissionTower = Set{4};
                
                current_priority = 1;
                index = 1;
                
                while(current_priority <= Max)
                    change = 0;
                    
                    for i = 1:length(Bus)
                        if strcmp(Bus{i}.Status, 'Damaged') && Bus{i}.Priority == current_priority
                            tasks = Bus{i}.taskUniqueIds;
                            for j = 1:length(tasks)
                                Schedule{index} = strcat('Bus/',num2str(i));
                                Schedule{index} = strcat(Schedule{index}, '/');
                                Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                index = index + 1;
                            end
                        end
                    end
                    for i = 1:length(Generator)
                        if strcmp(Generator{i}.Status, 'Damaged') && Generator{i}.Priority == current_priority
                            Schedule{index} = strcat('Generator/',num2str(i));
                            index = index + 1;
                        end
                    end
                    
                    for i = 1:length(Branch)
                        if strcmp(Branch{i}.Status, 'Damaged') && Branch{i}.Priority == current_priority
                            tasks = Branch{i}.taskUniqueIds;
                            for j = 1:length(tasks)
                                Schedule{index} = strcat('Branch/',num2str(i));
                                Schedule{index} = strcat(Schedule{index}, '/');
                                Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                index = index + 1;
                            end
                        end
                    end
                    

                    
                    for i = 1:length(TransmissionTower)
                        if strcmp(TransmissionTower{i}.Status, 'Damaged') && TransmissionTower{i}.Priority == current_priority
                            tasks = TransmissionTower{i}.taskUniqueIds;
                            for j = 1:length(tasks)
                                Schedule{index} = strcat('TransmissionTower/',num2str(i));
                                Schedule{index} = strcat(Schedule{index}, '/');
                                Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                index = index + 1;
                            end
                        end
                    end
                    
                    current_priority = current_priority + 1;
                end
                
            elseif strcmp(System, 'Communication')
                Centraloffice = Set{2};
                Router = Set{3};
                Cellline = Set{4};
                CommunicationTower = Set{5};
                
                current_priority = 1;
                index = 1;
                
                while(current_priority <= Max)
                    change = 0;
                    
                    for i = 1:length(Centraloffice)
                        if strcmp(Centraloffice{i}.Status, 'Damaged') && Centraloffice{i}.Priority == current_priority
                            tasks = Centraloffice{i}.taskUniqueIds;
                            for j = 1:length(tasks)
                                Schedule{index} = strcat('CentralOffice/',num2str(i));
                                Schedule{index} = strcat(Schedule{index}, '/');
                                Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                index = index + 1;
                            end
                        end
                    end
                    
                    for i = 1:length(Router)
                        if strcmp(Router{i}.Status, 'Damaged') && Router{i}.Priority == current_priority
                            tasks = Router{i}.taskUniqueIds;
                            for j = 1:length(tasks)
                                Schedule{index} = strcat('Router/',num2str(i));
                                Schedule{index} = strcat(Schedule{index}, '/');
                                Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                index = index + 1;
                            end
                        end
                    end
                    
                    for i = 1:length(Cellline)
                        if strcmp(Cellline{i}.Status, 'Damaged') && Cellline{i}.Priority == current_priority
                            tasks = Cellline{i}.taskUniqueIds;
                            for j = 1:length(tasks)
                                Schedule{index} = strcat('Cellline/',num2str(i));
                                Schedule{index} = strcat(Schedule{index}, '/');
                                Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                index = index + 1;
                            end
                        end
                    end
                    
                    for i = 1:length(CommunicationTower)
                        if strcmp(CommunicationTower{i}.Status, 'Damaged') && CommunicationTower{i}.Priority == current_priority
                            tasks = CommunicationTower{i}.taskUniqueIds;
                            for j = 1:length(tasks)
                                Schedule{index} = strcat('CommunicationTower/',num2str(i));
                                Schedule{index} = strcat(Schedule{index}, '/');
                                Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                index = index + 1;
                            end
                        end
                    end
                    
                    current_priority = current_priority + 1;
                end
                
            elseif strcmp(System, 'Transportation')
                Road = Set{1};
                Bridge = Set{2};
                TrafficLight = Set{3};
                
                current_priority = 1;
                index = 1;
                
                while(current_priority <= Max)
                    change = 0;
                    for i = 1:length(Road)
                        if strcmp(Road{i}.Status, 'Damaged') && Road{i}.Priority == current_priority
                            tasks = Road{i}.taskUniqueIds;
                            for j = 1:length(tasks)
                                Schedule{index} = strcat('Road/',num2str(i));
                                Schedule{index} = strcat(Schedule{index}, '/');
                                Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                index = index + 1;
                            end
                        end
                    end
                    
                    for i = 1:length(Bridge)
                        if strcmp(Bridge{i}.Status, 'Damaged') && Bridge{i}.Priority == current_priority
                            
                            
%                                 tasks = Bridge{i}.taskUniqueIds;
%                                 for j = 1:length(tasks)
%                                     Schedule{index} = strcat('Bridge/',num2str(i));
%                                     Schedule{index} = strcat(Schedule{index}, '/');
%                                     Schedule{index} =  strcat(Schedule{index}, tasks{j});
%                                     index = index + 1;
%                                 end
                            
                            if Bridge{i}.HasSub == 1
                                for sub_index = 1:length(Bridge{i}.ColumnSet)
                                    tasks = Bridge{i}.ColumnSet(sub_index).taskUniqueIds;
                                    for j = 1:length(tasks)
                                        Schedule{index} = strcat('Column/',num2str(i));
                                        Schedule{index} = strcat(Schedule{index}, '/');
                                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                        index = index + 1;
                                    end
                                end
                                for sub_index = 1:length(Bridge{i}.ColumnFoundSet)
                                    tasks = Bridge{i}.ColumnFoundSet(sub_index).taskUniqueIds;
                                    for j = 1:length(tasks)
                                        Schedule{index} = strcat('ColumnFoundation/',num2str(i));
                                        Schedule{index} = strcat(Schedule{index}, '/');
                                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                        index = index + 1;
                                    end
                                end
                                for sub_index = 1:length(Bridge{i}.AbutmentSet)
                                    tasks = Bridge{i}.AbutmentSet(sub_index).taskUniqueIds;
                                    for j = 1:length(tasks)
                                        Schedule{index} = strcat('Abutment/',num2str(i));
                                        Schedule{index} = strcat(Schedule{index}, '/');
                                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                        index = index + 1;
                                    end
                                end
                                for sub_index = 1:length(Bridge{i}.AbutmentFoundSet)
                                    tasks = Bridge{i}.AbutmentFoundSet(sub_index).taskUniqueIds;
                                    for j = 1:length(tasks)
                                        Schedule{index} = strcat('AbutmentFoundation/',num2str(i));
                                        Schedule{index} = strcat(Schedule{index}, '/');
                                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                        index = index + 1;
                                    end
                                end
                                for sub_index = 1:length(Bridge{i}.BearingSet)
                                    tasks = Bridge{i}.BearingSet(sub_index).taskUniqueIds;
                                    for j = 1:length(tasks)
                                        Schedule{index} = strcat('Bearing/',num2str(i));
                                        Schedule{index} = strcat(Schedule{index}, '/');
                                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                        index = index + 1;
                                    end
                                end
                                for sub_index = 1:length(Bridge{i}.SlabSet)
                                    tasks = Bridge{i}.SlabSet(sub_index).taskUniqueIds;
                                    for j = 1:length(tasks)
                                        Schedule{index} = strcat('ApproachSlab/',num2str(i));
                                        Schedule{index} = strcat(Schedule{index}, '/');
                                        Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                        index = index + 1;
                                    end
                                end
                            else
                                tasks = Bridge{i}.taskUniqueIds;
                                for j = 1:length(tasks)
                                    Schedule{index} = strcat('Bridge/',num2str(i));
                                    Schedule{index} = strcat(Schedule{index}, '/');
                                    Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                    index = index + 1;
                                end
                            end
                        end
                    end
                    
                    for i = 1:length(TrafficLight)
                        if strcmp(TrafficLight{i}.Status, 'Damaged') && TrafficLight{i}.Priority == current_priority
                            tasks = TrafficLight{i}.taskUniqueIds;
                            for j = 1:length(tasks)
                                Schedule{index} = strcat('TrafficLight/',num2str(i));
                                Schedule{index} = strcat(Schedule{index}, '/');
                                Schedule{index} =  strcat(Schedule{index}, tasks{j});
                                index = index + 1;
                            end
                        end
                    end
                    
                    current_priority = current_priority + 1;
                    
                end
                
            end
            Return_Schedule = Schedule;
            Return_Date = [];
        end
        
        % Create repair schedule according to the efficiency
        % (NEED UPDATE)
        function [Return_Schedule, Return_Date] = RepairSchedulEfficiency(System, Max_Number, time, Set)
            Schedule = [];
            numOfResources = length(Max_Number);
            if strcmp(System, 'Power')
                Branch= Set{1};
                Bus= Set{2};
                Generator= Set{3};
                
                Damaged_Number = 0;
                
                for i = 1:length(Set)
                    tmp = Library.countDamaged(Set{i});
                    Damaged_Number = Damaged_Number + tmp;
                end
                
                Total = (time) * (length(Branch) + length(Bus) + length(Generator) + 1);
                
                A = zeros(Damaged_Number+time * numOfResources, Total);
                B = zeros(Damaged_Number+time * numOfResources,1);
                Aeq = zeros(length(Branch) + length(Bus) + length(Generator) + 1, Total);
                Beq = zeros(length(Branch) + length(Bus) + length(Generator) + 1, 1);
                
                index = 1;
                
                Start_Branch = 0;
                Start_Bus = length(Branch);
                Start_Generator = length(Branch) + length(Bus);
                Start_End = length(Branch) + length(Bus) + length(Generator);
                
                tmp = zeros(1, Total);
                tmp((Start_End * time + 1):(Start_End * time + time)) = (1:time);
                obj = tmp;
                intcon = linspace(1,length(tmp),length(tmp));
                lb = zeros(1,Total);
                ub = ones(1,Total);
                
                % A and B
                % Precendence constrain
                for i = 1:length(Branch)
                    if strcmp(Branch{i}.Status, 'Damaged')
                        Branch_Num = Branch{i}.Number - 1;
                        Branch_Time = Branch{i}.Recovery(1);
                        A(index, ((Branch_Num + Start_Branch) * time + 1):((Branch_Num + Start_Branch) * time) + time) = (1:time);
                        A(index, (Start_End * time + 1):(Start_End * time + time)) = (-1:-1:-time);
                        B(index) = -Branch_Time;
                        index = index + 1;
                    end
                end
                
                for i = 1:length(Bus)
                    if strcmp(Bus{i}.Status, 'Damaged')
                        Bus_Num = Bus{i}.Number - 1;
                        Bus_Time = Bus{i}.Recovery(1);
                        A(index, ((Bus_Num + Start_Bus) * time + 1):((Bus_Num + Start_Bus) * time) + time) = (1:time);
                        A(index, (Start_End * time + 1):(Start_End * time + time)) = (-1:-1:-time);
                        B(index) = -Bus_Time;
                        index = index + 1;
                    end
                end
                
                for i = 1:length(Generator)
                    if strcmp(Generator{i}.Status, 'Damaged')
                        Generator_Num = Generator{i}.Number - 1;
                        Generator_Time = Generator{i}.Recovery(1);
                        A(index, ((Generator_Num + Start_Generator) * time + 1):((Generator_Num + Start_Generator) * time) + time) = (1:time);
                        A(index, (Start_End * time + 1):(Start_End * time + time)) = (-1:-1:-time);
                        B(index) = -Generator_Time;
                        index = index + 1;
                    end
                end
                
                % Max constrain
                for k = 1:numOfResources
                    for i = 1:time
                        count = length(Branch) + length(Bus) + length(Generator);
                        for j = 1:count
                            if j <= length(Branch) && strcmp(Branch{j}.Status, 'Damaged') %if j == branch && j is damaged
                                if (i + Branch{j}.Recovery(1) - 1 ) <= time
                                    % Previous Version (Potentially wrong):
                                    % A(index, (j - 1) * time + i:(j - 1) * time + i + Branch{j}.Recovery(1) - 1) = 1;
                                    A(Damaged_Number + i + (k - 1) * time:Damaged_Number + i + Branch{j}.Recovery(1) - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                end
                            elseif j > length(Branch) && j <= length(Bus) + length(Branch) && strcmp(Bus{j-length(Branch)}.Status, 'Damaged')
                                if (i + Bus{j-length(Branch)}.Recovery(1) - 1 ) <= time
                                    % Previous Version (Potentially wrong):
                                    % A(index, (j - 1) * time + i:(j - 1) * time + i + Bus{j-length(Branch)}.Recovery(1) - 1) = 1;
                                    A(Damaged_Number + i + (k - 1) * time:Damaged_Number + i + Bus{j-length(Branch)}.Recovery(1) - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                end
                            elseif j > length(Branch) + length(Bus) && j <= length(Generator) + length(Bus) + length(Branch) && strcmp(Generator{j-length(Bus)-length(Branch)}.Status, 'Damaged')
                                if (i + Generator{j-length(Bus)-length(Branch)}.Recovery(1) - 1 ) <= time
                                    % Previous Version (Potentially wrong):
                                    % A(index, (j- 1) * time + i:(j - 1) * time + i + Generator{j-length(Bus)-length(Branch)}.Recovery(1) - 1) = 1;
                                    A(Damaged_Number + i + (k - 1) * time:Damaged_Number + i + Generator{j-length(Bus)-length(Branch)}.Recovery(1) - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                end
                            end
                        end
                        B(index) = Max_Number(k);
                        index = index + 1;
                    end
                end
                index = 1;
                % Aeq and Beq
                % Only doing once constrain
                for i = 1:length(Branch)
                    Branch_Num = Branch{i}.Number - 1;
                    Aeq(index, ((Branch_Num + Start_Branch) * time + 1):((Branch_Num + Start_Branch) * time) + time) = 1;
                    if strcmp(Branch{i}.Status, 'Damaged')
                        Beq(index) = 1;
                    else
                        Beq(index) = 0;
                    end
                    index = index + 1;
                end
                
                for i = 1:length(Bus)
                    Bus_Num = Bus{i}.Number - 1;
                    Aeq(index,((Bus_Num + Start_Bus) * time + 1):((Bus_Num + Start_Bus) * time) + time) = 1;
                    if strcmp(Bus{i}.Status, 'Damaged')
                        Beq(index) = 1;
                    else
                        Beq(index) = 0;
                    end
                    index = index + 1;
                end
                
                for i = 1:length(Generator)
                    Generator_Num = Generator{i}.Number - 1;
                    Aeq(index, ((Generator_Num + Start_Generator) * time + 1):((Generator_Num + Start_Generator) * time) + time) = 1;
                    if strcmp(Generator{i}.Status, 'Damaged')
                        Beq(index) = 1;
                    else
                        Beq(index) = 0;
                    end
                    index = index + 1;
                end
                
                Aeq(index, (Start_End * time + 1):(Start_End * time + time)) = 1;
                Beq(index) = 1;
                
                % Result
                [x, fval, exitflag] = Library.intlinprog(obj,intcon, A, B, Aeq, Beq, lb, ub);
                Result = rem(find(x), time);
                for i = 1:length(Result)
                    if Result(i) == 0
                        Result(i) = time;
                    end
                end
                Number = floor((find(x)-1)/time) + 1;
                Schedule = [Number, Result];
                
            elseif strcmp(System, 'Communication')
                A = [];
                B = [];
                Aeq = [];
                Beq = [];
                
                
                Centraloffice = Set{2};
                Router = Set{3};
                Cellline = Set{4};
                CommunicationTower = Set{5};
                Antenna = {};
                
                Damaged_Number = 0;
                
                for i = 1:length(Set)
                    tmp = Library.countDamaged(Set{i});
                    Damaged_Number = Damaged_Number + tmp;
                end
                
                Total = (time) * ( length(Centraloffice) + length(Router) + length(Cellline) + length(CommunicationTower) + 1);
                
                A = zeros(Damaged_Number+time, Total);
                B = zeros(Damaged_Number+time,1);
                Aeq = zeros(length(Centraloffice) + length(Router) + length(Cellline)  + length(CommunicationTower) + 1, Total);
                Beq = zeros(length(Centraloffice) + length(Router) + length(Cellline)  + length(CommunicationTower) + 1, 1);
                
                index = 1;
                
                
                Start_Centraloffice = 0;
                Start_Router = length(Centraloffice);
                Start_Cellline = length(Centraloffice) + length(Router);
                Start_CommunicationTower =length(Centraloffice) + length(Router) + length(Cellline);
                Start_End = length(Centraloffice) + length(Router) + length(Cellline) + length(CommunicationTower);
                
                tmp = zeros(1, Total);
                tmp((Start_End * time + 1):(Start_End * time + time)) = (1:time);
                obj = tmp;
                intcon = linspace(1,length(tmp),length(tmp));
                lb = zeros(1,Total);
                ub = ones(1,Total);
                
                % A and B
                % Precendence constrain
                
                
                for i = 1:length(Centraloffice)
                    if strcmp(Centraloffice{i}.Status, 'Damaged')
                        Centraloffice_Num = Centraloffice{i}.Number - 1;
                        Centraloffice_Time = Centraloffice{i}.Recovery(1);
                        A(index, ((Centraloffice_Num + Start_Centraloffice) * time + 1):((Centraloffice_Num + Start_Centraloffice) * time) + time) = (1:time);
                        A(index, (Start_End * time + 1):(Start_End * time + time)) = (-1:-1:-time);
                        B(index) = -Centraloffice_Time;
                        index = index + 1;
                    end
                end
                
                for i = 1:length(Router)
                    if strcmp(Router{i}.Status, 'Damaged')
                        Router_Num = Router{i}.Number - 1;
                        Router_Time = Router{i}.Recovery(1);
                        A(index, ((Router_Num + Start_Router) * time + 1):((Router_Num + Start_Router) * time) + time) = (1:time);
                        A(index, (Start_End * time + 1):(Start_End * time + time)) = (-1:-1:-time);
                        B(index) = -Router_Time;
                        index = index + 1;
                    end
                end
                
                for i = 1:length(Cellline)
                    if strcmp(Cellline{i}.Status, 'Damaged')
                        Cellline_Num = Cellline{i}.Number - 1;
                        Cellline_Time = Cellline{i}.Recovery(1);
                        A(index, ((Cellline_Num + Start_Cellline) * time + 1):((Cellline_Num + Start_Cellline) * time) + time) = (1:time);
                        A(index, (Start_End * time + 1):(Start_End * time + time)) = (-1:-1:-time);
                        B(index) = -Cellline_Time;
                        index = index + 1;
                    end
                end
                
                for i = 1:length(CommunicationTower)
                    if strcmp(CommunicationTower{i}.Status, 'Damaged')
                        CommunicationTower_Num = CommunicationTower{i}.Number - 1;
                        CommunicationTower_Time = CommunicationTower{i}.Recovery(1);
                        A(index, ((CommunicationTower_Num + Start_CommunicationTower) * time + 1):((CommunicationTower_Num + Start_CommunicationTower) * time) + time) = (1:time);
                        A(index, (Start_End * time + 1):(Start_End * time + time)) = (-1:-1:-time);
                        B(index) = -CommunicationTower_Time;
                        index = index + 1;
                    end
                end
                
                % Max constrain
                for k = 1:numOfResources
                    for i = 1:time
                        count = length(Antenna) + length(Centraloffice) + length(Router);
                        array = zeros(1, Total);
                        for j = 1:count
                            if j <= length(Antenna) && strcmp(Antenna{j}.Status, 'Damaged')
                                if (i + Antenna{j}.Recovery(1) - 1 ) <= time
                                    A(Damaged_Number + i + (k - 1) * time:Damaged_Number + i + Antenna{j}.Recovery(1) - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                    %A(index, (j - 1) * time + i:(j - 1) * time + i + Antenna{j}.Recovery(1) - 1) = 1;
                                end
                            elseif j > length(Antenna) && j <= length(Centraloffice) + length(Antenna) && strcmp(Centraloffice{j-length(Antenna)}.Status, 'Damaged')
                                if (i + Centraloffice{j-length(Antenna)}.Recovery(1) - 1 ) <= time
                                    A(Damaged_Number + i + (k - 1) * time:Damaged_Number + i +  Centraloffice{j-length(Antenna)}.Recovery(1) - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                    %A(index, (j - 1) * time + i:(j - 1) * time + i + Centraloffice{j-length(Antenna)}.Recovery(1) - 1) = 1;
                                end
                            elseif j > length(Antenna) + length(Centraloffice) && j <= length(Router) + length(Centraloffice) + length(Antenna) && strcmp(Router{j-length(Antenna)-length(Centraloffice)}.Status, 'Damaged')
                                if (i + Router{j-length(Centraloffice)-length(Antenna)}.Recovery(1) - 1 ) <= time
                                    A(Damaged_Number + i + (k - 1) * time:Damaged_Number + i +  Router{j-length(Centraloffice)-length(Antenna)}.Recovery(1) - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                    %A(index, (j- 1) * time + i:(j - 1) * time + i + Router{j-length(Centraloffice)-length(Antenna)}.Recovery(1) - 1) = 1;
                                end
                            elseif j > length(Antenna) + length(Centraloffice) + length(Router) && j <= length(Router) + length(Centraloffice) + length(Antenna) + length(Cellline) && strcmp(Cellline{j-length(Antenna)-length(Centraloffice)-length(Router)}.Status, 'Damaged')
                                if (i + Cellline{j-length(Centraloffice)-length(Antenna)-length(Router)}.Recovery(1) - 1 ) <= time
                                    A(Damaged_Number + i + (k - 1) * time:Damaged_Number + i +  Cellline{j-length(Centraloffice)-length(Antenna)-length(Router)}.Recovery(1) - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                    %A(index, (j- 1) * time + i:(j - 1) * time + i + Cellline{j-length(Centraloffice)-length(Antenna)-length(Router)}.Recovery(1) - 1) = 1;
                                end
                            elseif j > length(Antenna) + length(Centraloffice) + length(Router) + length(Cellline) && j <= length(Router) + length(Centraloffice) + length(Antenna) + length(Cellline) + length(CommunicationTower) && strcmp(CommunicationTower{j-length(Antenna)-length(Centraloffice)-length(Router)-length(Cellline)}.Status, 'Damaged')
                                if (i + CommunicationTower{j-length(Antenna)-length(Centraloffice)-length(Router)-length(Cellline)}.Recovery(1) - 1 ) <= time
                                    A(Damaged_Number + i + (k - 1) * time:Damaged_Number + i +  CommunicationTower{j-length(Antenna)-length(Centraloffice)-length(Router)-length(Cellline)}.Recovery(1) - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                    %A(index, (j- 1) * time + i:(j - 1) * time + i + CommunicationTower{j-length(Antenna)-length(Centraloffice)-length(Router)-length(Cellline)}.Recovery(1) - 1) = 1;
                                end
                            end
                        end
                        B(index) = Max_Number(k);
                        %B(index) = Max_Number;
                        index = index + 1;
                    end
                end
                index = 1;
                % Aeq and Beq
                % Only doing once constrain
                
                
                for i = 1:length(Centraloffice)
                    Centraloffice_Num = Centraloffice{i}.Number - 1;
                    Aeq(index, ((Centraloffice_Num + Start_Centraloffice) * time + 1):((Centraloffice_Num + Start_Centraloffice) * time) + time) = 1;
                    if strcmp(Centraloffice{i}.Status, 'Damaged')
                        Beq(index) = 1;
                    else
                        Beq(index) = 0;
                    end
                    index = index + 1;
                end
                
                for i = 1:length(Router)
                    Router_Num = Router{i}.Number - 1;
                    Aeq(index, ((Router_Num + Start_Router) * time + 1):((Router_Num + Start_Router) * time) + time) = 1;
                    if strcmp(Router{i}.Status, 'Damaged')
                        Beq(index) = 1;
                    else
                        Beq(index) = 0;
                    end
                    index = index + 1;
                end
                
                for i = 1:length(Cellline)
                    Cellline_Num = Cellline{i}.Number - 1;
                    Aeq(index, ((Cellline_Num + Start_Cellline) * time + 1):((Cellline_Num + Start_Cellline) * time) + time) = 1;
                    if strcmp(Cellline{i}.Status, 'Damaged')
                        Beq(index) = 1;
                    else
                        Beq(index) = 0;
                    end
                    index = index + 1;
                end
                
                for i = 1:length(CommunicationTower)
                    CommunicationTower_Num = CommunicationTower{i}.Number - 1;
                    Aeq(index, ((CommunicationTower_Num + Start_CommunicationTower) * time + 1):((CommunicationTower_Num + Start_CommunicationTower) * time) + time) = 1;
                    if strcmp(CommunicationTower{i}.Status, 'Damaged')
                        Beq(index) = 1;
                    else
                        Beq(index) = 0;
                    end
                    index = index + 1;
                end
                
                Aeq(index, (Start_End * time + 1):(Start_End * time + time)) = 1;
                Beq(index) = 1;
                
                
                % Result
                [x, fval, exitflag] = Library.intlinprog(obj,intcon, A, B, Aeq, Beq, lb, ub);
                
                Result = rem(find(x), time);
                for i = 1:length(Result)
                    if Result(i) == 0
                        Result(i) = time;
                    end
                end
                Number = floor((find(x)-1)/time) + 1;
                Schedule = [Number, Result];
                
            elseif strcmp(System, 'Transportation')
                Road = Set{1};
                Bridge = Set{2};
                TrafficLight = Set{3};
                
                Damaged_Number = 0;
                
                for i = 1:length(Set)
                    tmp = Library.countDamaged(Set{i});
                    Damaged_Number = Damaged_Number + tmp;
                end
                
                Total = (time) * (length(Road) + length(Bridge) + length(TrafficLight) + 1);
                
                A = zeros(Damaged_Number+time, Total);
                B = zeros(Damaged_Number+time,1);
                Aeq = zeros(length(Road) + length(Bridge) + length(TrafficLight) + 1, Total);
                Beq = zeros(length(Road) + length(Bridge) + length(TrafficLight) + 1, 1);
                
                index = 1;
                
                Start_Road = 0;
                Start_Bridge = length(Road);
                Start_TrafficLight = length(Road) + length(Bridge);
                Start_End = length(Road) + length(Bridge) + length(TrafficLight);
                
                tmp = zeros(1, Total);
                tmp((Start_End * time + 1):(Start_End * time + time)) = (1:time);
                obj = tmp;
                intcon = linspace(1,length(tmp),length(tmp));
                lb = zeros(1,Total);
                ub = ones(1,Total);
                
                % A and B
                % Precendence constrain
                for i = 1:length(Road)
                    if strcmp(Road{i}.Status, 'Damaged')
                        Road_Num = Road{i}.Number - 1;
                        Road_Time = Road{i}.Recovery(1);
                        A(index, ((Road_Num + Start_Road) * time + 1):((Road_Num + Start_Road) * time) + time) = (1:time);
                        A(index, (Start_End * time + 1):(Start_End * time + time)) = (-1:-1:-time);
                        B(index) = -Road_Time;
                        index = index + 1;
                    end
                end
                
                for i = 1:length(Bridge)
                    if strcmp(Bridge{i}.Status, 'Damaged')
                        Bridge_Num = Bridge{i}.Number - 1;
                        Bridge_Time = Bridge{i}.Recovery(1);
                        A(index, ((Bridge_Num + Start_Bridge) * time + 1):((Bridge_Num + Start_Bridge) * time) + time) = (1:time);
                        A(index, (Start_End * time + 1):(Start_End * time + time)) = (-1:-1:-time);
                        B(index) = -Bridge_Time;
                        index = index + 1;
                    end
                end
                
                for i = 1:length(TrafficLight)
                    if strcmp(TrafficLight{i}.Status, 'Damaged')
                        TrafficLight_Num = TrafficLight{i}.Number - 1;
                        TrafficLight_Time = TrafficLight{i}.Recovery(1);
                        A(index, ((TrafficLight_Num + Start_TrafficLight) * time + 1):((TrafficLight_Num + Start_TrafficLight) * time) + time) = (1:time);
                        A(index, (Start_End * time + 1):(Start_End * time + time)) = (-1:-1:-time);
                        B(index) = -TrafficLight_Time;
                        index = index + 1;
                    end
                end
                
                % Max constrain
                for k = 1:numOfResources
                    for i = 1:time
                        count = length(Road) + length(Bridge) + length(TrafficLight);
                        array = zeros(1, Total);
                        for j = 1:count
                            if j <= length(Road) && strcmp(Road{j}.Status, 'Damaged')
                                if (i + Road{j}.Recovery(1) - 1 ) <= time
                                    A(Damaged_Number + i + (k - 1) * time:Damaged_Number + i + Road{j}.Recovery(1) - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                    %A(index, (j - 1) * time + i:(j - 1) * time + i + Road{j}.Recovery(1) - 1) = 1;
                                end
                            elseif j > length(Road) && j <= length(Bridge) + length(Road) && strcmp(Bridge{j-length(Road)}.Status, 'Damaged')
                                if (i + Bridge{j-length(Road)}.Recovery(1) - 1 ) <= time
                                    A(Damaged_Number + i + (k - 1) * time:Damaged_Number + i + Bridge{j-length(Road)}.Recovery(1) - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                    %A(index, (j - 1) * time + i:(j - 1) * time + i + Bridge{j-length(Road)}.Recovery(1) - 1) = 1;
                                end
                            elseif j > length(Road) + length(Bridge) && j <= length(TrafficLight) + length(Bridge) + length(Road) && strcmp(TrafficLight{j-length(Bridge)-length(Road)}.Status, 'Damaged')
                                if (i + TrafficLight{j-length(Bridge)-length(Road)}.Recovery(1) - 1 ) <= time
                                    A(Damaged_Number + i + (k - 1) * time:Damaged_Number + i + TrafficLight{j-length(Bridge)-length(Road)}.Recovery(1) - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                    %A(index, (j- 1) * time + i:(j - 1) * time + i + TrafficLight{j-length(Bridge)-length(Road)}.Recovery(1) - 1) = 1;
                                end
                            end
                        end
                        B(index) = Max_Number(k);
                        %B(index) = Max_Number;
                        index = index + 1;
                    end
                end
                index = 1;
                % Aeq and Beq
                % Only doing once constrain
                for i = 1:length(Road)
                    Road_Num = Road{i}.Number - 1;
                    Aeq(index, ((Road_Num + Start_Road) * time + 1):((Road_Num + Start_Road) * time) + time) = 1;
                    if strcmp(Road{i}.Status, 'Damaged')
                        Beq(index) = 1;
                    else
                        Beq(index) = 0;
                    end
                    index = index + 1;
                end
                
                for i = 1:length(Bridge)
                    Bridge_Num = Bridge{i}.Number - 1;
                    Aeq(index, ((Bridge_Num + Start_Bridge) * time + 1):((Bridge_Num + Start_Bridge) * time) + time) = 1;
                    if strcmp(Bridge{i}.Status, 'Damaged')
                        Beq(index) = 1;
                    else
                        Beq(index) = 0;
                    end
                    index = index + 1;
                end
                
                for i = 1:length(TrafficLight)
                    TrafficLight_Num = TrafficLight{i}.Number - 1;
                    Aeq(index, ((TrafficLight_Num + Start_TrafficLight) * time + 1):((TrafficLight_Num + Start_TrafficLight) * time) + time) = 1;
                    if strcmp(TrafficLight{i}.Status, 'Damaged')
                        Beq(index) = 1;
                    else
                        Beq(index) = 0;
                    end
                    index = index + 1;
                end
                
                Aeq(index, (Start_End * time + 1):(Start_End * time + time)) = 1;
                Beq(index) = 1;
                
                
                % Result
                [x, fval, exitflag] = Library.intlinprog(obj,intcon, A, B, Aeq, Beq, lb, ub);
                
                Result = rem(find(x), time);
                for i = 1:length(Result)
                    if Result(i) == 0
                        Result(i) = time;
                    end
                end
                Number = floor((find(x)-1)/time) + 1;
                Schedule = [Number, Result];
            end
            
            Schedule = sortrows(Schedule,2);
            %disp(Schedule);
            Return_Schedule = {length(Schedule)};
            Return_Date = zeros(length(Schedule), 1);
            
            if strcmp(System, 'Power')
                for i = 1:length(Schedule)
                    if Schedule(i,1) <= length(Branch)
                        Return_Schedule{i} = strcat('Branch/',num2str(Branch{Schedule(i,1)}.Number));
                        Return_Date(i) = Schedule(i,2);
                    elseif Schedule(i,1) <= length(Branch) + length(Bus)
                        Return_Schedule{i} = strcat('Bus/',num2str(Bus{Schedule(i,1)-length(Branch)}.Number));
                        Return_Date(i) = Schedule(i,2);
                    elseif Schedule(i,1) <= length(Branch) + length(Bus) + length(Generator)
                        Return_Schedule{i} = strcat('Generator/',num2str(Generator{Schedule(i,1)-length(Branch)-length(Bus)}.Number));
                        Return_Date(i) = Schedule(i,2);
                    end
                end
            elseif strcmp(System, 'Transportation')
                for i = 1:length(Schedule)
                    if Schedule(i,1) <= length(Road)
                        Return_Schedule{i} = strcat('Road/',num2str(Road{Schedule(i,1)}.Number));
                        Return_Date(i) = Schedule(i,2);
                    elseif Schedule(i,1) <= length(Road) + length(Bridge)
                        Return_Schedule{i} = strcat('Bridge/',num2str(Bridge{Schedule(i,1)-length(Road)}.Number));
                        Return_Date(i) = Schedule(i,2);
                    elseif Schedule(i,1) <= length(Road) + length(Bridge) + length(TrafficLight)
                        Return_Schedule{i} = strcat('TrafficLight/',num2str(TrafficLight{Schedule(i,1)-length(Road)-length(Bridge)}.Number));
                        Return_Date(i) = Schedule(i,2);
                    end
                end
            elseif strcmp(System, 'Communication')
                for i = 1:length(Schedule)
                    if Schedule(i,1) <= length(Antenna)
                        Return_Schedule{i} = strcat('Antenna/',num2str(Antenna{Schedule(i,1)}.Number));
                        Return_Date(i) = Schedule(i,2);
                    elseif Schedule(i,1) <= length(Antenna) + length(Centraloffice)
                        Return_Schedule{i} = strcat('Centraloffice/',num2str(Centraloffice{Schedule(i,1)-length(Antenna)}.Number));
                        Return_Date(i) = Schedule(i,2);
                    elseif Schedule(i,1) <= length(Antenna) + length(Centraloffice) + length(Router)
                        Return_Schedule{i} = strcat('Router/',num2str(Router{Schedule(i,1)-length(Antenna)-length(Centraloffice)}.Number));
                        Return_Date(i) = Schedule(i,2);
                    elseif Schedule(i,1) <= length(Antenna) + length(Centraloffice) + length(Router) + length(Cellline)
                        Return_Schedule{i} = strcat('Cellline/',num2str(Cellline{Schedule(i,1)-length(Antenna)-length(Centraloffice)-length(Router)}.Number));
                        Return_Date(i) = Schedule(i,2);
                    elseif Schedule(i,1) <= length(Antenna) + length(Centraloffice) + length(Router) + length(Cellline) + length(CommunicationTower)
                        Return_Schedule{i} = strcat('CommunicationTower/',num2str(CommunicationTower{Schedule(i,1)-length(Antenna)-length(Centraloffice)-length(Router)-length(Cellline)}.Number));
                        Return_Date(i) = Schedule(i,2);
                    end
                end
            end
        end
        
        % Reschedule mean time
        % (NEED UPDATE)
        function Return_Schedule = RepairScheduleReScheduleMean(orig_Schedule, time, Max_Power, Max_Trans, Max_Comm, Power_Set, Communication_Set, Transportation_Set)
            A = [];
            B = [];
            Aeq = [];
            Beq = [];
            Schedule = [];
            index = 1;
            
            [rescheduleSet, pow_number, comm_number, trans_number] = Library.countSchedule(orig_Schedule);
            total_number = pow_number + comm_number + trans_number;
            if total_number > 0
                Total = (time) * (total_number + 1);
                
                tmp = zeros(1, Total);
                tmp((total_number * time + 1):(total_number * time + time)) = (1:time);
                obj = tmp;
                intcon = linspace(1,length(tmp),length(tmp));
                lb = zeros(1,Total);
                ub = ones(1,Total);
                
                for i = 1:length(rescheduleSet)
                    repair_Time = Library.getRepairationTime(1, rescheduleSet{i}, Power_Set, Communication_Set, Transportation_Set);
                    tmp = zeros(1,Total);
                    tmp(((i - 1) * time + 1):((i - 1) * time) + time) = (1:time);
                    tmp((total_number * time + 1):(total_number * time + time)) = (-1:-1:-time);
                    A = [A; tmp];
                    B = [B; -repair_Time];
                    [A, B] = Library.addInterdependence(1, rescheduleSet{i}, A, B, time, rescheduleSet, Power_Set, Communication_Set, Transportation_Set);
                    index = index + 1;
                end
                
                for i = index:(length(Max_Power) +  length(Max_Comm) + length(Max_Trans))* time
                    for j = 1:Total
                        A(i,j) = 0;
                    end
                end
                
                % Power Max constrain
                if pow_number ~= 0
                    for k = 1:length(Max_Power)
                        for i = 1:time
                            %array = zeros(1, Total);
                            for j = 1:pow_number
                                repair_Time = Library.getRepairationTime(1, rescheduleSet{j}, Power_Set, Communication_Set, Transportation_Set);
                                if (i + repair_Time - 1) <= time
                                    %array((j - 1) * time + i:(j - 1) * time + i + repair_Time - 1) = 1
                                    A(i + (k - 1) * time + length(rescheduleSet):i + repair_Time - 1 + (k - 1) * time + length(rescheduleSet), (j - 1) * time + i) = 1;
                                end
                            end
                            %A = [A; array];
                            B(index) = Max_Power(k);
                            index = index + 1;
                            %B = [B; Max_Power];
                        end
                    end
                end
                indexC = index;
                if comm_number ~= 0
                    for k = 1:length(Max_Comm)
                        for i = 1:time
                            %array = zeros(1, Total);
                            for j = 1:comm_number
                                repair_Time = Library.getRepairationTime(1, rescheduleSet{j + pow_number}, Power_Set, Communication_Set, Transportation_Set);
                                if (i + repair_Time ) <= time
                                    %array((j + pow_number - 1) * time + i:(j + pow_number - 1) * time + i + repair_Time - 1) = 1;
                                    A(indexC + i + (k - 1) * time:indexC + i + repair_Time - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                end
                            end
                            %A = [A; array];
                            %B = [B; Max_Comm];
                            B(index) = Max_Comm(k);
                            index = index + 1;
                        end
                    end
                end
                indexT = index;
                if trans_number ~= 0
                    for k = 1:length(Max_Trans)
                        for i = 1:time
                            %array = zeros(1, Total);
                            for j = 1:trans_number
                                repair_Time = Library.getRepairationTime(1, rescheduleSet{j + pow_number + comm_number}, Power_Set, Communication_Set, Transportation_Set);
                                if (i + repair_Time ) <= time
                                    %array((j + pow_number + comm_number - 1) * time + i:(j + pow_number + comm_number - 1) * time + i + repair_Time - 1) = 1;
                                    A(indexT + i + (k - 1) * time:indexT + i + repair_Time - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                end
                            end
                            %A = [A; array];
                            %B = [B; Max_Comm];
                            B(index) = Max_Trans(k);
                            index = index + 1;
                        end
                    end
                end
                
                % Aeq and Beq
                % Only doing once constrain
                for i = 1:length(rescheduleSet) + 1
                    tmp = zeros(1,Total);
                    tmp(((i - 1) * time + 1):((i - 1) * time) + time) = 1;
                    Aeq = [Aeq;tmp];
                    Beq = [Beq; 1];
                end
                
                [x, fval, exitflag] = Library.intlinprog(obj,intcon, A, B, Aeq, Beq, lb, ub);
                Result = rem(find(x), time);
                
                Number = floor((find(x)-1)/time) + 1;
                Schedule = [Number, Result];
                Schedule = sortrows(Schedule,2);
                %disp(Schedule);
                
                Pow = orig_Schedule{1};
                Comm = orig_Schedule{2};
                Trans = orig_Schedule{3};
                
                for i = 1:length(Schedule) - 1
                    object = rescheduleSet{Schedule(i,1)};
                    tem = strsplit(object,'/');
                    name = tem{1};
                    
                    if strcmp(name, 'Generator') || strcmp(name, 'Branch') || strcmp(name, 'Bus')
                        Pow{length(Pow) - pow_number + 1} = object;
                        pow_number = pow_number - 1;
                    end
                    
                    if  strcmp(name, 'Centraloffice') || strcmp(name, 'Router') || strcmp(name, 'Cellline') || strcmp(name, 'CommunicationTower')
                        Comm{length(Comm) - comm_number + 1} = object;
                        comm_number = comm_number - 1;
                    end
                    
                    if strcmp(name, 'Road') || strcmp(name, 'Bridge') || strcmp(name, 'TrafficLight')
                        Trans{length(Trans) - trans_number + 1} = object;
                        trans_number = trans_number - 1;
                    end
                end
                Return_Schedule = {Pow, Comm, Trans};
            else
                Return_Schedule = orig_Schedule;
            end
        end
        
        % Reschedule Actual time
        % (NEED UPDATE)
        function Return_Schedule = RepairScheduleReScheduleActual(orig_Schedule, time, Max_Power, Max_Trans, Max_Comm, Power_Set, Communication_Set, Transportation_Set)
            A = [];
            B = [];
            Aeq = [];
            Beq = [];
            Schedule = [];
            
            [rescheduleSet, pow_number, comm_number, trans_number] = Library.countSchedule(orig_Schedule);
            total_number = pow_number + comm_number + trans_number;
            if total_number > 0
                Total = (time) * (total_number + 1);
                
                tmp = zeros(1, Total);
                tmp((total_number * time + 1):(total_number * time + time)) = (1:time);
                obj = tmp;
                intcon = linspace(1,length(tmp),length(tmp));
                lb = zeros(1,Total);
                ub = ones(1,Total);
                
                for i = 1:length(rescheduleSet)
                    repair_Time = Library.getRepairationTime(2, rescheduleSet{i}, Power_Set, Communication_Set, Transportation_Set);
                    tmp = zeros(1,Total);
                    tmp(((i - 1) * time + 1):((i - 1) * time) + time) = (1:time);
                    tmp((total_number * time + 1):(total_number * time + time)) = (-1:-1:-time);
                    A = [A; tmp];
                    B = [B; -repair_Time];
                    [A, B] = Library.addInterdependence(2, rescheduleSet{i}, A, B, time, rescheduleSet, Power_Set, Communication_Set, Transportation_Set);
                end
                
                % Power Max constrain
                if pow_number ~= 0
                    for k = 1:length(Max_Power)
                        for i = 1:time
                            %array = zeros(1, Total);
                            for j = 1:pow_number
                                repair_Time = Library.getRepairationTime(2, rescheduleSet{j}, Power_Set, Communication_Set, Transportation_Set);
                                if (i + repair_Time - 1) <= time
                                    %array((j - 1) * time + i:(j - 1) * time + i + repair_Time - 1) = 1
                                    A(i + (k - 1) * time + length(rescheduleSet):i + repair_Time - 1 + (k - 1) * time + length(rescheduleSet), (j - 1) * time + i) = 1;
                                end
                            end
                            %A = [A; array];
                            B(index) = Max_Power(k);
                            index = index + 1;
                            %B = [B; Max_Power];
                        end
                    end
                end
                
                indexC = index;
                if comm_number ~= 0
                    for k = 1:length(Max_Comm)
                        for i = 1:time
                            %array = zeros(1, Total);
                            for j = 1:comm_number
                                repair_Time = Library.getRepairationTime(2, rescheduleSet{j + pow_number}, Power_Set, Communication_Set, Transportation_Set);
                                if (i + repair_Time ) <= time
                                    %array((j + pow_number - 1) * time + i:(j + pow_number - 1) * time + i + repair_Time - 1) = 1;
                                    A(indexC + i + (k - 1) * time:indexC + i + repair_Time - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                end
                            end
                            %A = [A; array];
                            %B = [B; Max_Comm];
                            B(index) = Max_Comm(k);
                            index = index + 1;
                        end
                    end
                end
                indexT = index;
                if trans_number ~= 0
                    for k = 1:length(Max_Trans)
                        for i = 1:time
                            %array = zeros(1, Total);
                            for j = 1:trans_number
                                repair_Time = Library.getRepairationTime(2, rescheduleSet{j + pow_number + comm_number}, Power_Set, Communication_Set, Transportation_Set);
                                if (i + repair_Time ) <= time
                                    %array((j + pow_number + comm_number - 1) * time + i:(j + pow_number + comm_number - 1) * time + i + repair_Time - 1) = 1;
                                    A(indexT + i + (k - 1) * time:indexT + i + repair_Time - 1 + (k - 1) * time, (j - 1) * time + i) = 1;
                                end
                            end
                            %A = [A; array];
                            %B = [B; Max_Comm];
                            B(index) = Max_Trans(k);
                            index = index + 1;
                        end
                    end
                end
                
                % Aeq and Beq
                % Only doing once constrain
                for i = 1:length(rescheduleSet) + 1
                    tmp = zeros(1,Total);
                    tmp(((i - 1) * time + 1):((i - 1) * time) + time) = 1;
                    Aeq = [Aeq;tmp];
                    Beq = [Beq; 1];
                end
                
                [x, fval, exitflag] = Library.intlinprog(obj,intcon, A, B, Aeq, Beq, lb, ub);
                Result = rem(find(x), time);
                
                Number = floor((find(x)-1)/time) + 1;
                Schedule = [Number, Result];
                Schedule = sortrows(Schedule,2);
                %disp(Schedule);
                
                Pow = orig_Schedule{1};
                Comm = orig_Schedule{2};
                Trans = orig_Schedule{3};
                
                for i = 1:length(Schedule) - 1
                    object = rescheduleSet{Schedule(i,1)};
                    tem = strsplit(object,'/');
                    name = tem{1};
                    
                    if strcmp(name, 'Generator') || strcmp(name, 'Branch') || strcmp(name, 'Bus')
                        Pow{length(Pow) - pow_number + 1} = object;
                        pow_number = pow_number - 1;
                    end
                    
                    if strcmp(name, 'Centraloffice') || strcmp(name, 'Router') || strcmp(name, 'Cellline')
                        Comm{length(Comm) - comm_number + 1} = object;
                        comm_number = comm_number - 1;
                    end
                    
                    if strcmp(name, 'Road') || strcmp(name, 'Bridge') || strcmp(name, 'TrafficLight')
                        Trans{length(Trans) - trans_number + 1} = object;
                        trans_number = trans_number - 1;
                    end
                end
                Return_Schedule = {Pow, Comm, Trans};
            else
                Return_Schedule = orig_Schedule;
            end
        end
        
        % add interdependence
        % (NEED UPDATE)
        function [A, B] = addInterdependence(num, Object, A, B, time, rescheduleSet, Power_Set, Communication_Set, Transportation_Set)
            Branch= Power_Set{1};
            Bus= Power_Set{2};
            Generator= Power_Set{3};
            
            
            Centraloffice = Communication_Set{2};
            Router = Communication_Set{3};
            Cellline = Communication_Set{4};
            CommunicationTower = Communication_Set{5};
            
            Road = Transportation_Set{1};
            Bridge = Transportation_Set{2};
            TrafficLight = Transportation_Set{3};
            
            tem = strsplit(Object,'/');
            name = tem{1};
            number = str2num(tem{2});
            index = 0;
            
            % Power
            if strcmp(name, 'Generator')
                for i = 1:length(Bus)
                    if Bus{i}.Generator == number
                        [x,y] = ismember(strcat('Bus/', num2str(Bus{i}.Number)), rescheduleSet);
                        if x == 1
                            index = y;
                        end
                    end
                end
            end
            
            if strcmp(name, 'Bus')
                for i = 1:length(Bus{number}.Road)
                    [x,y] = ismember(strcat('Road/', num2str(Bus{number}.Road(i))), rescheduleSet);
                    if x == 1
                        index = y;
                    end
                end
            end
            
            % Communication
            
            if strcmp(name, 'Centraloffice')
                for i = 1:length(Centraloffice{number}.Road)
                    [x,y] = ismember(strcat('Road/', num2str(Centraloffice{number}.Road(i))), rescheduleSet);
                    if x == 1
                        index = y;
                    end
                end
            end
            
            if strcmp(name, 'Router')
                for i = 1:length(Centraloffice)
                    if Centraloffice{i}.Router == number
                        [x,y] = ismember(strcat('Centraloffice/', num2str(Centraloffice{i}.Number)), rescheduleSet);
                        if x == 1
                            index = y;
                        end
                    end
                end
            end
            
            if strcmp(name, 'CommunicationTower')
                for i = 1:length(CommunicationTower{number}.Road)
                    [x,y] = ismember(strcat('Road/', num2str(CommunicationTower{number}.Road(i))), rescheduleSet);
                    if x == 1
                        index = y;
                    end
                end
            end
            
            % Transportation
            if strcmp(name, 'Road')
                for j = 1:length(Road{number}.Bridge_Carr)
                    [x,y] = ismember(strcat('Bridge/', num2str(Road{number}.Bridge_Carr(j))), rescheduleSet);
                    if x == 1
                        index = [index, y];
                    end
                end
            end
            
            if strcmp(name, 'TrafficLight')
                for i = 1:length(Road)
                    if Road{i}.TrafficLight == number
                        [x,y] = ismember(strcat('Road/', num2str(Road{i}.Number)), rescheduleSet);
                        if x == 1
                            index = y;
                        end
                    end
                end
                
                for i = 1:length(Bridge)
                    if Bridge{i}.TrafficLight == number
                        [x,y] = ismember(strcat('Bridge/', num2str(Bridge{i}.Number)), rescheduleSet);
                        if x == 1
                            index = y;
                        end
                    end
                end
            end
            
            for i = 1:length(index)
                if index(i) > 0 && ~isempty(index(i))
                    repair_Time = Library.getRepairationTime(num, Object, Power_Set, Communication_Set, Transportation_Set);
                    tmp = zeros(1,length(A));
                    [x, y] = ismember(Object, rescheduleSet);
                    tmp(((y - 1) * time + 1):((y - 1) * time) + time) = (1:time);
                    tmp(((index(i) - 1) * time + 1):((index(i) - 1) * time + time)) = (-1:-1:-time);
                    A = [A; tmp];
                    B = [B; -repair_Time];
                end
            end
        end
        
        % Count and get unfixed item from schedule
        function [set, pow_count, comm_count, trans_count] = countSchedule(orig_Schedule)
            Pow = orig_Schedule{1};
            Comm = orig_Schedule{2};
            Trans = orig_Schedule{3};
            
            pow_count = 0;
            comm_count = 0;
            trans_count = 0;
            set = {};
            
            for i = 1:length(Pow)
                tem = strsplit(Pow{i},'/');
                if length(tem) == 2
                    %disp(Pow{i});
                    pow_count = pow_count + 1;
                    set = [set, Pow{i}];
                end
            end
            
            for i = 1:length(Comm)
                tem = strsplit(Comm{i},'/');
                if length(tem) == 2
                    %disp(Comm{i});
                    comm_count = comm_count + 1;
                    set = [set, Comm{i}];
                end
            end
            
            for i = 1:length(Trans)
                tem = strsplit(Trans{i},'/');
                if length(tem) == 2 || length(tem) == 3
                    %disp(Trans{i});
                    trans_count = trans_count + 1;
                    set = [set, Trans{i}];
                end
            end
        end
        
        %% Repairation Process
        % Overall recoveray process
        
          function [Power, Comm, Trans] = Repairation(time_horizon, Interdependence_Num, ReSchedule_Num, Max_Power, Max_Comm, Max_Trans, Power_Func_Num, Trans_Func_Num, Comm_Func_Num, Schedule_Power, Schedule_Comm, Schedule_Trans, Power_Set, Communication_Set, Transportation_Set, Dictionary, System_Dependent_Factor, transGraph, powerGraph, commGraph,Neighborhood,Seperate_Scheduling, LinkDirectionChoice)
            %Branch_Set = Power_Set{1};
            %temp = Dictionary(Branch_Set{1}.uniqueID);
            %temp{1}.WorkingDays = 100;
            %disp(Branch_Set{1});
            %subplot(1,3,1);
            %plot(transGraph,'Layout','force');
            %subplot(1,3,2);
            %plot(powerGraph,'Layout','force');
            %subplot(1,3,3);
            %plot(commGraph,'Layout','force');
            lookupTable = {};
            [totalPopulation,PowFunc,CommFunc,TransFunc] = Library.neighbourFunc(Dictionary);
            
            funcTable = containers.Map('KeyType','char','ValueType','any');
            funcTable = Library.initialFuncTable(Power_Set, Communication_Set, Transportation_Set,funcTable,time_horizon,Neighborhood);
            neighbourPowFunc = zeros(1,time_horizon);
            neighbourCommFunc = zeros(1,time_horizon);
            neighbourTransFunc = zeros(1,time_horizon);
            Power = zeros(1,time_horizon);
            Comm = zeros(1,time_horizon);
            Trans = zeros(1,time_horizon);
            TransTest = zeros(4,time_horizon);
            CurrentWorking_Power = {};
            CurrentWorking_Comm = {};
            CurrentWorking_Trans = {};
            
            finish = 0;
            Start_Day = 1;
            End_Day = 1;
            flag = 0;
            ploti= 0;
            
            total_damaged = length(Schedule_Power) + length(Schedule_Comm) + length(Schedule_Trans);
            total_fixed = 0;
            need_reschedule = 0;
            
            % Calculate actual repair time
            
            while finish == 0
                
                % Add Damaged Component to Current Working List Based on
                % Resource Constraint
                [CurrentWorking_Power, Schedule_Power, Max_Power,lookupTable] = Library.AddCurrentWorking(Max_Power, CurrentWorking_Power, Schedule_Power, Dictionary,lookupTable,Start_Day);
                [CurrentWorking_Comm, Schedule_Comm, Max_Comm,lookupTable] = Library.AddCurrentWorking(Max_Comm, CurrentWorking_Comm, Schedule_Comm, Dictionary,lookupTable,Start_Day);
                [CurrentWorking_Trans, Schedule_Trans, Max_Trans,lookupTable] = Library.AddCurrentWorking(Max_Trans, CurrentWorking_Trans, Schedule_Trans, Dictionary,lookupTable,Start_Day);
                
                % Calculation inerdependence and the working days
                %Interface.InterdependenceFactor(Interdependence_Num, CurrentWorking_Power, CurrentWorking_Comm, CurrentWorking_Trans, Power_Set, Communication_Set, Transportation_Set);
                
                % Find Day for the Component take shorest time
                Days = Library.FindMinDays(CurrentWorking_Power, CurrentWorking_Comm, CurrentWorking_Trans, Power_Set, Communication_Set, Transportation_Set,Dictionary);
                % Updating the Working Days for Current Working Component
                
                Library.WorkingProcess(CurrentWorking_Power, Dictionary, Days);
                Library.WorkingProcess(CurrentWorking_Comm, Dictionary, Days);
                Library.WorkingProcess(CurrentWorking_Trans, Dictionary, Days);
                
                if Days ~= 0
                    if Days == 1
                        End_Day = End_Day + 1;
                    else
                        End_Day = End_Day + ceil(Days);
                    end
                else
                    End_Day = time_horizon;
                    finish = 1;
                end
                % Calculated Functionality
                [Trans_Fun, Pow_Fun, Comm_Fun] = Interface1.Functionality(Power_Func_Num, Trans_Func_Num, Comm_Func_Num, Power_Set, Communication_Set, Transportation_Set, powerGraph, commGraph, transGraph, Dictionary,LinkDirectionChoice);
                if Interdependence_Num == 1
                    if flag == 0 && Trans_Fun < 0.8
                        Library.SysFuncInterdependence(Power_Set, Communication_Set, Transportation_Set, System_Dependent_Factor, Dictionary);
                        flag = 1;
                    elseif flag == 1 && Trans_Fun > 0.8
                        Restore_Factor = 1 / System_Dependent_Factor;
                        Library.SysFuncInterdependence(Power_Set, Communication_Set, Transportation_Set, Restore_Factor, Dictionary);
                        flag = 2;
                    else
                        Library.SysFuncInterdependence(Power_Set, Communication_Set, Transportation_Set, 1, Dictionary);
                        
                    end
                else
                    Library.SysFuncInterdependence(Power_Set, Communication_Set, Transportation_Set, 1, Dictionary);
                end
                
                
                
                [CurrentWorking_Power,Max_Power] = Library.Clean(CurrentWorking_Power, Dictionary, Max_Power);
                [CurrentWorking_Comm,Max_Comm] = Library.Clean(CurrentWorking_Comm, Dictionary, Max_Comm);
                [CurrentWorking_Trans,Max_Trans] = Library.Clean(CurrentWorking_Trans, Dictionary, Max_Trans);
                
                
                % Update the Status for reparied Component
                [need_reschedule, total_fixed, transGraph, powerGraph, commGraph,Power_Set, Communication_Set, Transportation_Set,funcTable] = Library.UpdateStatus(Power_Set, Communication_Set, Transportation_Set, total_damaged, total_fixed, need_reschedule,Dictionary, transGraph, powerGraph, commGraph,funcTable,End_Day);
                
                if ReSchedule_Num ~= 0
                    if need_reschedule == 1
                        need_reschedule = 2;
                        Schedule = {Schedule_Power, Schedule_Comm, Schedule_Trans};
                        Schedule = Interface1.RepairReSchedule(ReSchedule_Num, Schedule, time_horizon, Max_Power, Max_Trans, Max_Comm, Power_Set, Communication_Set, Transportation_Set);
                        Schedule_Power = Schedule{1};
                        Schedule_Comm = Schedule{2};
                        Schedule_Trans = Schedule{3};
                    end
                end
                
                [totalPopulation,PowFunc,CommFunc,TransFunc] = Library.neighbourFunc(Dictionary);% Propotion of population that has power/comm/trans
                neighbourPowFunc(Start_Day:End_Day) = PowFunc;
                neighbourCommFunc(Start_Day:End_Day) = CommFunc;
                neighbourTransFunc(Start_Day:End_Day) = TransFunc;
                Trans(Start_Day:End_Day) = Trans_Fun;
                Power(Start_Day:End_Day) = Pow_Fun;
                Comm(Start_Day:End_Day) = Comm_Fun;
                %p = plot(commGraph,'Layout','force');
                %saveas(p,strcat('./test/Comm', num2str(ploti),'.jpg'));
                %p = plot(powerGraph,'Layout','force');
                %saveas(p,strcat('./test/Power', num2str(ploti),'.jpg'));
                %TransTest = Library.ComputeFunc(transGraph, Start_Day, End_Day,TransTest);
                
                TransTest = Library.Functionality_GraphBasic(transGraph, LinkDirectionChoice, Start_Day, End_Day,TransTest);
                ploti = ploti + 1;
                
                Start_Day = End_Day + 1;
            end
            
            % Error Check
            filename = strcat('lookupTable.mat');
            save(filename, 'lookupTable');
            printedFuncTable = Library.printFuncTable(funcTable, time_horizon);
            filename = strcat('printedFuncTable.mat');
            save(filename, 'printedFuncTable');
            if Power(time_horizon) ~= 1
                disp('Warning: Functionality Power is eventually less than 100% at t = time_horizon.');
            end
            
            if Comm(time_horizon) ~= 1
                disp('Warning: Functionality Communication is eventually less than 100% at t = time_horizon.');
            end
            
            if Trans(time_horizon) ~= 1
                disp('Warning: Functionality Transportation is eventually less than 100% at t = time_horizon.');
            end
            
        end
        
        
    
        % Add damaged component to current working list to start repairing process
        function [Current, Schedule, Max_Resource,lookupTable] = AddCurrentWorking(Max_Resource, Current, Schedule, Dictionary,lookupTable,End_Day)
            for i = 1:length(Schedule)
                tem = strsplit(Schedule{i},'/');
                isTask = 0;
                % Check if the object is already being repaired
                if length(tem) ~= 2 && length(tem) ~= 3
                    continue;
                end
                flagResource = 0;
                allEmpty = 1;
                resourceNeed = zeros(1,length(Max_Resource));
                
                if(Library.getDependency(Schedule{i},Dictionary))
                    continue;
                end
                objTemp = Dictionary(Library.getUniqueId(Schedule{i},0));
                % Check if there're enough resources to accomplish the task
                for j = 1:length(Max_Resource)
                    resourceNeed(j) = Library.getResource(Schedule{i},Dictionary,j, 0);
                    if (Max_Resource(j) - resourceNeed(j)) < 0
                        flagResource = 1;
                        break;
                    end
                end
                if flagResource == 1
                    continue;
                end
                % If the object is a task
                if length(tem) == 3
                    isTask = 1;
                    tasktemp = Dictionary(tem{3});
                    flagPredecessor = 0;
                    % Check if dependent tasks are already finished
                    for j = 1:length(tasktemp.predecessorTask)
                        if(Dictionary(tasktemp.predecessorTask{j}).WorkingDays > 0)
                            flagPredecessor = 1;
                            break;
                        end
                    end
                    if flagPredecessor == 1
                        continue;
                    end
                    if tasktemp.WorkingDays == 0
                        disp('Error: AddCurrentWorking -- Working Days == 0');
                        disp(tasktemp);
                    end
                    parent = Dictionary(tasktemp.parentUniqueID);
                    parent = parent{1};
                    parent.Functionality = tasktemp.taskFunctionality;
                end
                % Find an empty block to fill in
                indexCurrent = 0;
                for j = 1:length(Current)
                    if isempty(Current{j})
                        indexCurrent = j;
                    end
                end
                if indexCurrent == 0
                    indexCurrent = length(Current) + 1;
                end
                % Mark the task/object as working
                % Add to Current working and subtract resource
                Schedule{i} = strcat(Schedule{i},'/Working/dummy');
                Current{indexCurrent} = Schedule{i};
                lookupTable = Library.addToLookupTable(lookupTable, objTemp, End_Day,isTask);
                for j = 1:length(Max_Resource)
                    Max_Resource(j) = Max_Resource(j) - resourceNeed(j);
                    if Max_Resource(j) ~= 0
                        allEmpty = 0;
                    end
                end
                if allEmpty == 1
                    return;
                end
                
            end
        end
        
        % Basic Interdependence Function
        function InterdenpendenceFactorCalculateBasic(CurrentWorking_Power, CurrentWorking_Comm, CurrentWorking_Trans, Pow, Comm, Trans)
            % Field
            Branch= Pow{1};
            Bus= Pow{2};
            Generator= Pow{3};
            
            Centraloffice = Comm{2};
            Router = Comm{3};
            Cellline = Comm{4};
            
            Road = Trans{1};
            Bridge = Trans{2};
            TrafficLight = Trans{3};
            
            for i = 1:length(CurrentWorking_Power)
                if ~isempty(CurrentWorking_Power{i})
                    tem = strsplit(CurrentWorking_Power{i},'/');
                    name = tem{1};
                    number = str2num(tem{2});
                    if strcmp(name, 'Generator')
                        score = 0;
                        
                        if strcmp(Centraloffice{Generator{number}.Centraloffice}.Status, 'Damaged')
                            score = 0.8;
                        else
                            score = 1;
                        end
                        
                        if Generator{number}.Interdependence_Factor == -1
                            Generator{number}.Interdependence_Factor = score;
                            Generator{number}.WorkingDays = round(Generator{number}.WorkingDays/Generator{number}.Interdependence_Factor);
                        else
                            Generator{number}.WorkingDays = round(Generator{number}.WorkingDays*Generator{number}.Interdependence_Factor/score);
                            Generator{number}.Interdependence_Factor = score;
                        end
                    elseif strcmp(name, 'Bus')
                        count = 0;
                        score = 0;
                        tmp = 0;
                        
                        for j = 1:length(Bus{number}.Road)
                            if strcmp(Road{Branch{number}.Road(j)}.Status, 'Damaged')
                                tmp = tmp + 0.3;
                            elseif strcmp(Road{Branch{number}.Road(j)}.Status, 'Bridge_Damaged')
                                tmp = tmp + 0.5;
                            elseif strcmp(Road{Branch{number}.Road(j)}.Status, 'Stoped')
                                tmp = tmp + 0.8;
                            elseif strcmp(Road{Branch{number}.Road(j)}.Status, 'Open')
                                tmp = tmp + 0.1;
                            end
                            count = count + 1;
                        end
                        
                        score = score + 0.6*(tmp/count);
                        if strcmp(Centraloffice{Bus{number}.Centraloffice}.Status, 'Damaged')
                            score = score + 0.4*0.3;
                        else
                            score = score + 0.4*1;
                        end
                        
                        
                        
                        if Bus{number}.Interdependence_Factor == -1
                            Bus{number}.Interdependence_Factor = score;
                            Bus{number}.WorkingDays = round(Bus{number}.WorkingDays/Bus{number}.Interdependence_Factor);
                        else
                            Bus{number}.WorkingDays = round(Bus{number}.WorkingDays*Bus{number}.Interdependence_Factor/score);
                            Bus{number}.Interdependence_Factor = score;
                        end
                    elseif strcmp(name, 'Branch')
                        score = 0;
                        
                        
                        
                        if Branch{number}.Interdependence_Factor == -1
                            Branch{number}.Interdependence_Factor = score;
                            Branch{number}.WorkingDays = round(Branch{number}.WorkingDays/Branch{number}.Interdependence_Factor);
                        else
                            Branch{number}.WorkingDays = round(Branch{number}.WorkingDays*Branch{number}.Interdependence_Factor/score);
                            Branch{number}.Interdependence_Factor = score;
                        end
                    end
                end
            end
            
            for i = 1:length(CurrentWorking_Comm)
                if ~isempty(CurrentWorking_Comm{i})
                    tem = strsplit(CurrentWorking_Comm{i},'/');
                    name = tem{1};
                    number = str2num(tem{2});
                    
                    if strcmp(name, 'Centraloffice')
                        count = 0;
                        score = 0;
                        tmp = 0;
                        
                        for j = 1:length(Centraloffice{number}.Road)
                            if strcmp(Road{Centraloffice{number}.Road(j)}.Status, 'Damaged')
                                tmp = tmp + 0.3;
                            elseif strcmp(Road{Centraloffice{number}.Road(j)}.Status, 'Bridge_Damaged')
                                tmp = tmp + 0.5;
                            elseif strcmp(Road{Centraloffice{number}.Road(j)}.Status, 'Stoped')
                                tmp = tmp + 0.8;
                            elseif strcmp(Road{Centraloffice{number}.Road(j)}.Status, 'Open')
                                tmp = tmp + 0.1;
                            end
                            count = count + 1;
                        end
                        
                        score = score + 0.6*(tmp/count);
                        if strcmp(Bus{Centraloffice{number}.Bus}.Status, 'Damaged')
                            score = score + 0.4*0.3;
                        else
                            score = score + 0.4*1;
                        end
                        
                        
                        if Centraloffice{number}.Interdependence_Factor == -1
                            Centraloffice{number}.Interdependence_Factor = score;
                            Centraloffice{number}.WorkingDays = round(Centraloffice{number}.WorkingDays/Centraloffice{number}.Interdependence_Factor);
                        else
                            Centraloffice{number}.WorkingDays = round(Centraloffice{number}.WorkingDays*Centraloffice{number}.Interdependence_Factor/score);
                            Centraloffice{number}.Interdependence_Factor = score;
                        end
                    elseif strcmp(name, 'Router')
                        score = 0;
                        
                        if strcmp(Bus{Router{number}.Bus}.Status, 'Damaged')
                            score = 0.8;
                        else
                            score = 1;
                        end
                        
                        
                        
                        if Router{number}.Interdependence_Factor == -1
                            Router{number}.Interdependence_Factor = score;
                            Router{number}.WorkingDays = round(Router{number}.WorkingDays/Router{number}.Interdependence_Factor);
                        else
                            Router{number}.WorkingDays = round(Router{number}.WorkingDays*Router{number}.Interdependence_Factor/score);
                            Router{number}.Interdependence_Factor = score;
                        end
                    elseif strcmp(name, 'Cellline')
                        score = 0;
                        
                        if strcmp(Bus{Cellline{number}.Bus}.Status, 'Damaged')
                            score = score + 0.5*0.8;
                        else
                            score = score + 0.5*1;
                        end
                        
                        if Cellline{number}.Interdependence_Factor == -1
                            Cellline{number}.Interdependence_Factor = score;
                            Cellline{number}.WorkingDays = round(Cellline{number}.WorkingDays/Cellline{number}.Interdependence_Factor);
                        else
                            Cellline{number}.WorkingDays = round(Cellline{number}.WorkingDays*Cellline{number}.Interdependence_Factor/score);
                            Cellline{number}.Interdependence_Factor = score;
                        end
                    end
                end
            end
            
            for i = 1:length(CurrentWorking_Trans)
                if ~isempty(CurrentWorking_Trans{i})
                    tem = strsplit(CurrentWorking_Trans{i},'/');
                    name = tem{1};
                    number = str2num(tem{2});
                    if strcmp(name, 'Road')
                        score = 0;
                        
                        if strcmp(Bus{Road{number}.Bus}.Status, 'Damaged')
                            score = score + 0.5*0.8;
                        else
                            score = score + 0.5*1;
                        end
                        
                        if Road{number}.Interdependence_Factor == -1
                            Road{number}.Interdependence_Factor = score;
                            Road{number}.WorkingDays = round(Road{number}.WorkingDays/Road{number}.Interdependence_Factor);
                        else
                            Road{number}.WorkingDays = round(Road{number}.WorkingDays*Road{number}.Interdependence_Factor/score);
                            Road{number}.Interdependence_Factor = score;
                        end
                    elseif strcmp(name, 'Bridge')
                        score = 0;
                        
                        if strcmp(Bus{Bridge{number}.Bus}.Status, 'Damaged')
                            score = score + 0.5*0.8;
                        else
                            score = score + 0.5*1;
                        end
                        
                        if Bridge{number}.Interdependence_Factor == -1
                            Bridge{number}.Interdependence_Factor = score;
                            Bridge{number}.WorkingDays = ceil(Bridge{number}.WorkingDays/Bridge{number}.Interdependence_Factor);
                        else
                            Bridge{number}.WorkingDays = ceil(Bridge{number}.WorkingDays*Bridge{number}.Interdependence_Factor/score);
                            Bridge{number}.Interdependence_Factor = score;
                        end
                        
                    elseif strcmp(name, 'TrafficLight')
                        score = 0;
                        
                        if strcmp(Bus{TrafficLight{number}.Bus}.Status, 'Damaged')
                            score = score + 0.5*0.8;
                        else
                            score = score + 0.5*1;
                        end
                        
                    end
                    
                    if TrafficLight{number}.Interdependence_Factor == -1
                        TrafficLight{number}.Interdependence_Factor = score;
                        TrafficLight{number}.WorkingDays = round(TrafficLight{number}.WorkingDays/TrafficLight{number}.Interdependence_Factor);
                    else
                        TrafficLight{number}.WorkingDays = round(TrafficLight{number}.WorkingDays*TrafficLight{number}.Interdependence_Factor/score);
                        TrafficLight{number}.Interdependence_Factor = score;
                    end
                end
            end
        end
        
        % Update the status for repaired component
        function [need_reschedule, total_fixed,  transGraph, powerGraph, commGraph,Pow, Comm, Trans,funcTable] = UpdateStatus(Pow, Comm, Trans, total_damaged, total_fixed, need_reschedule,Dictionary, transGraph, powerGraph, commGraph,funcTable,Start_Day)
            % Field
            Branch= Pow{1};
            Bus= Pow{2};
            Generator= Pow{3};
            TransTower = Pow{4};
            
            Centraloffice = Comm{2};
            Router = Comm{3};
            Cellline = Comm{4};
            CommunicationTower = Comm{5};
            
            Road = Trans{1};
            Bridge = Trans{2};
            TrafficLight = Trans{3};
            fixed = false;
            % Power System
            for i = 1:length(Generator)
                if strcmp(Generator{i}.Status, 'Damaged') && ~isempty(Generator{i}.WorkingDays)
                    
                    if Generator{i}.WorkingDays <= 0
                        Generator{i}.Status = 'Open';
                        
                        temp = funcTable(Generator{i}.uniqueID);
                        temp(Start_Day:end) = 1;
                        funcTable(Generator{i}.uniqueID) = temp;
                        
                        Generator{i}.Functionality = 1;
                        total_fixed = total_fixed + 1;
                        need_reschedule = Library.checkNeedReschedule(total_damaged, total_fixed, need_reschedule);
                    end
                end
            end
            for i = 1:length(Bus)
                if ~isempty(Bus{i}.Generator)
                    if strcmp(Bus{i}.Status, 'Damaged') && ~isempty(Bus{i}.WorkingDays)
                        Bus = Library.getWorkDays(Bus, i,Dictionary);
                        if  Bus{i}.WorkingDays <= 0
                            Bus{i}.Status = 'Stoped';
                            total_fixed = total_fixed + 1;
                            need_reschedule = Library.checkNeedReschedule(total_damaged, total_fixed, need_reschedule);
                        end
                    end
                    if strcmp(Bus{i}.Status, 'Stoped')
                        temp = extractAfter(Bus{i}.Generator, 9);
                        temp = str2num(temp);
                        if strcmp(Generator{temp}.Status, 'Open')
                            Bus{i}.Status = 'Open';
                            fixed = true;
                            temp = funcTable(Bus{i}.uniqueID);
                            temp(Start_Day:end) = 1;
                            funcTable(Bus{i}.uniqueID) = temp;
                            
                            Bus{i}.Functionality = 1;
                            powerGraph = addnode(powerGraph,Bus{i}.uniqueID);
                            
                        end
                    end
                else
                    if strcmp(Bus{i}.Status, 'Damaged') && ~isempty(Bus{i}.WorkingDays)
                        if  Bus{i}.WorkingDays <= 0
                            Bus{i}.Status = 'Open';
                            fixed = true;
                            Bus{i}.Functionality = 1;
                            
                            temp = funcTable(Bus{i}.uniqueID);
                            temp(Start_Day:end) = 1;
                            funcTable(Bus{i}.uniqueID) = temp;
                            
                            powerGraph = addnode(powerGraph,Bus{i}.uniqueID);
                            total_fixed = total_fixed + 1;
                            need_reschedule = Library.checkNeedReschedule(total_damaged, total_fixed, need_reschedule);
                        end
                    end
                end
                if fixed
                    
                    
                    for j = 1:length(Bus{i}.Neighborhood)
                        temp = Dictionary(Bus{i}.Neighborhood{j});
                        temp = temp{1};
                        disp( temp.uniqueID);
                        temp.PowerStatus = 1;
                        temp = Dictionary(Bus{i}.Neighborhood_Power_Link{j});
                        temp = temp{1};
                        temp.Status = 'Open';
                    end
                    
                    fixed = false;
                end
            end
            for i = 1:length(Branch)
                if strcmp(Branch{i}.Status, 'Damaged') && ~isempty(Branch{i}.WorkingDays)
                    
                    Branch = Library.getWorkDays(Branch, i,Dictionary);
                    
                    if Branch{i}.WorkingDays <= 0
                        Branch{i}.Status = 'Stoped';
                        total_fixed = total_fixed + 1;
                        need_reschedule = Library.checkNeedReschedule(total_damaged, total_fixed, need_reschedule);
                    end
                end
                if strcmp(Branch{i}.Status, 'Stoped')
                    obj1 = Dictionary(Branch{i}.connectedObj1);
                    obj2 = Dictionary(Branch{i}.connectedObj2);
                    if strcmp(obj1{1}.Status, 'Open')&&strcmp(obj2{1}.Status, 'Open')
                        Branch{i}.Status = 'Open';
                        Branch{i}.Functionality = 1;
                        temp = funcTable(Branch{i}.uniqueID);
                        temp(Start_Day:end) = 1;
                        funcTable(Branch{i}.uniqueID) = temp;
                        powerGraph = Library.addPowerGraph(Pow, powerGraph, i, Dictionary);
                        
                    end
                end
            end
            
            for i = 1:length(TransTower)
                if strcmp(TransTower{i}.Status, 'Damaged') && ~isempty(TransTower{i}.WorkingDays)
                    if  TransTower{i}.WorkingDays <= 0
                        TransTower{i}.Status = 'Open';
                        TransTower{i}.Functionality = 1;
                        temp = funcTable(TransTower{i}.uniqueID);
                        temp(Start_Day:end) = 1;
                        funcTable(TransTower{i}.uniqueID) = temp;
                        
                        powerGraph = addnode(powerGraph,TransTower{i}.uniqueID);
                        total_fixed = total_fixed + 1;
                        need_reschedule = Library.checkNeedReschedule(total_damaged, total_fixed, need_reschedule);
                    end
                end
            end
            
            
            % Communication
            % Router
            for i = 1:length(Router)
                if strcmp(Router{i}.Status, 'Damaged') && ~isempty(Router{i}.WorkingDays)
                    Router = Library.getWorkDays(Router, i,Dictionary);
                    
                    if Router{i}.WorkingDays <= 0
                        Router{i}.Status = 'Open';
                        temp = funcTable(Router{i}.uniqueID);
                        temp(Start_Day:end) = 1;
                        funcTable(Router{i}.uniqueID) = temp;
                        Router{i}.Functionality = 1;
                        total_fixed = total_fixed + 1;
                        need_reschedule = Library.checkNeedReschedule(total_damaged, total_fixed, need_reschedule);
                    end
                end
            end
            
            % Central Office
            for i = 1:length(Centraloffice)
                if strcmp(Centraloffice{i}.Status, 'Damaged') && ~isempty(Centraloffice{i}.WorkingDays)
                    Centraloffice = Library.getWorkDays(Centraloffice, i,Dictionary);
                    
                    if Centraloffice{i}.WorkingDays <= 0
                        Centraloffice{i}.Status = 'Stoped';
                        total_fixed = total_fixed + 1;
                        need_reschedule = Library.checkNeedReschedule(total_damaged, total_fixed, need_reschedule);
                    end
                end
                
                if strcmp(Centraloffice{i}.Status, 'Stoped')
                    if Centraloffice{i}.Battery == 1
                        Centraloffice{i}.Status = 'Open';
                        fixed = true;
                        temp = funcTable(Centraloffice{i}.uniqueID);
                        temp(Start_Day:end) = 1;
                        funcTable(Centraloffice{i}.uniqueID) = temp;
                        Centraloffice{i}.Functionality = 1;
                        commGraph = addnode(commGraph,Centraloffice{i}.uniqueID);
                        continue;
                    end
                    bus = Dictionary(Centraloffice{i}.Bus);
                    if strcmp(bus{1}.Status, 'Open')
                        Centraloffice{i}.Status = 'Open';
                        fixed = true;
                        temp = funcTable(Centraloffice{i}.uniqueID);
                        temp(Start_Day:end) = 1;
                        funcTable(Centraloffice{i}.uniqueID) = temp;
                        Centraloffice{i}.Functionality = 1;
                        commGraph = addnode(commGraph,Centraloffice{i}.uniqueID);
                    end
                end
                if fixed
                    for j = 1:length(Centraloffice{i}.Neighborhood)
                        temp = Dictionary(Centraloffice{i}.Neighborhood{j});
                        temp = temp{1};
                        disp(temp.uniqueID);
                        temp.CommStatus = 1;
                        temp = Dictionary(Centraloffice{i}.Neighborhood_Comm_Link{j});
                        temp = temp{1};
                        temp.Status = 'Open';
                    end
                    
                    fixed = false;
                end
            end
            
            % CommunicationTower
            for i = 1:length(CommunicationTower)
                if strcmp(CommunicationTower{i}.Status, 'Damaged') && ~isempty(CommunicationTower{i}.WorkingDays)
                    CommunicationTower = Library.getWorkDays(CommunicationTower, i,Dictionary);
                    if CommunicationTower{i}.WorkingDays <= 0
                        CommunicationTower{i}.Status = 'Stoped';
                        total_fixed = total_fixed + 1;
                        need_reschedule = Library.checkNeedReschedule(total_damaged, total_fixed, need_reschedule);
                    end
                end
                if strcmp(CommunicationTower{i}.Status, 'Stoped')
                    if CommunicationTower{i}.Battery == 1
                        CommunicationTower{i}.Status = 'Open';
                        temp = funcTable(CommunicationTower{i}.uniqueID);
                        temp(Start_Day:end) = 1;
                        funcTable(CommunicationTower{i}.uniqueID) = temp;
                        CommunicationTower{i}.Functionality = 1;
                        commGraph = addnode(commGraph,CommunicationTower{i}.uniqueID);
                        continue;
                    end
                    bus = Dictionary(CommunicationTower{i}.Bus);
                    if strcmp(bus{1}.Status, 'Open')
                        CommunicationTower{i}.Status = 'Open';
                        temp = funcTable(CommunicationTower{i}.uniqueID);
                        temp(Start_Day:end) = 1;
                        funcTable(CommunicationTower{i}.uniqueID) = temp;
                        CommunicationTower{i}.Functionality = 1;
                        commGraph = addnode(commGraph,CommunicationTower{i}.uniqueID);
                    end
                end
            end
            
            % Cell Line
            for i = 1:length(Cellline)
                if strcmp(Cellline{i}.Status, 'Damaged') && ~isempty(Cellline{i}.WorkingDays)
                    Cellline = Library.getWorkDays(Cellline, i,Dictionary);
                    if Cellline{i}.WorkingDays <= 0
                        Cellline{i}.Status = 'Stoped';
                        total_fixed = total_fixed + 1;
                        need_reschedule = Library.checkNeedReschedule(total_damaged, total_fixed, need_reschedule);
                    end
                end
                if strcmp(Cellline{i}.Status, 'Stoped')
                    
                    bus = Dictionary(Cellline{i}.Bus);
                    obj1 = Dictionary(Cellline{i}.connectedObj1);
                    obj2 = Dictionary(Cellline{i}.connectedObj2);
                    
                    if strcmp(bus{1}.Status, 'Open')&& strcmp(obj1{1}.Status, 'Open')&&strcmp(obj2{1}.Status, 'Open')
                        Cellline{i}.Status = 'Open';
                        temp = funcTable(Cellline{i}.uniqueID);
                        temp(Start_Day:end) = 1;
                        funcTable(Cellline{i}.uniqueID) = temp;
                        Cellline{i}.Functionality = 1;
                        commGraph = Library.addCommGraph(Comm, commGraph, i,Dictionary);
                        
                    end
                end
            end
            
            % Transportation
            % TrafficLight
            for i = 1:length(TrafficLight)
                if strcmp(TrafficLight{i}.Status, 'Damaged') && ~isempty(TrafficLight{i}.WorkingDays)
                    
                    TrafficLight = Library.getWorkDays(TrafficLight, i,Dictionary);
                    if TrafficLight{i}.WorkingDays <= 0
                        TrafficLight{i}.Status = 'Stoped';
                        total_fixed = total_fixed + 1;
                        need_reschedule = Library.checkNeedReschedule(total_damaged, total_fixed, need_reschedule);
                    end
                end
                
                if strcmp(TrafficLight{i}.Status, 'Stoped')
                    if TrafficLight{i}.Battery == 1
                        TrafficLight{i}.Status = 'Open';
                        temp = funcTable(TrafficLight{i}.uniqueID);
                        temp(Start_Day:end) = 1;
                        funcTable(TrafficLight{i}.uniqueID) = temp;
                        
                        TrafficLight{i}.Functionality = 1;
                        transGraph = addnode(transGraph,TrafficLight{i}.uniqueID);
                        continue;
                    end
                    temp = extractAfter(TrafficLight{i}.Bus, 3);
                    temp = str2num(temp);
                    if ~isempty(temp) && strcmp(Bus{temp}.Status, 'Open')
                        TrafficLight{i}.Status = 'Open';
                        temp = funcTable(TrafficLight{i}.uniqueID);
                        temp(Start_Day:end) = 1;
                        funcTable(TrafficLight{i}.uniqueID) = temp;
                        TrafficLight{i}.Functionality = 1;
                    end
                end
            end
            
            % Bridge
            for i = 1:length(Bridge)
                flag = 1;
                if strcmp(Bridge{i}.Status, 'Damaged') && ~isempty(Bridge{i}.WorkingDays) && Bridge{i}.HasSub == 0 
                    tasks = Bridge{i}.taskUniqueIds;
                    sumWorkDay = 0;
                    for j = 1:length(tasks)
                        temp = Dictionary(tasks{j});
                        if iscell(temp)
                            temp = temp{1};
                        end
                        if temp.WorkingDays > 0
                            sumWorkDay = sumWorkDay + temp.WorkingDays;
                            flag = 0;
                        end
                    end
                    Bridge{i}.WorkingDays = sumWorkDay;
                    if Bridge{i}.WorkingDays <= 0 || flag
                        Bridge{i}.Status = 'Open';
%                         temp = funcTable(Bridge{i}.uniqueID);
%                         temp(Start_Day:end) = 1;
%                         funcTable(Bridge{i}.uniqueID) = temp;
                        Bridge{i}.Functionality = 1;
                        total_fixed = total_fixed + 1;
                        need_reschedule = Library.checkNeedReschedule(total_damaged, total_fixed, need_reschedule);
                    end
                end
                % for subcomponent
                if strcmp(Bridge{i}.Status, 'Damaged') && ~isempty(Bridge{i}.WorkingDays) && Bridge{i}.HasSub == 1
                    for sub_index = 1:length(Bridge{i}.ColumnSet)
                        tasks = Bridge{i}.ColumnSet(sub_index).taskUniqueIds;
                        sumWorkDay = 0;
                        for j = 1:length(tasks)
                            temp = Dictionary(tasks{j});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            if temp.WorkingDays > 0
                                sumWorkDay = sumWorkDay + temp.WorkingDays;
                                flag = 0;
                            end
                        end
                         Bridge{i}.WorkingDays = sumWorkDay;
                    end
                    
                    for sub_index = 1:length(Bridge{i}.ColumnFoundSet)
                        tasks = Bridge{i}.ColumnFoundSet(sub_index).taskUniqueIds;
                        sumWorkDay = 0;
                        for j = 1:length(tasks)
                            temp = Dictionary(tasks{j});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            if temp.WorkingDays > 0
                                sumWorkDay = sumWorkDay + temp.WorkingDays;
                                flag = 0;
                            end
                        end
                         Bridge{i}.WorkingDays = sumWorkDay;
                    end
                    
                    for sub_index = 1:length(Bridge{i}.AbutmentSet)
                        tasks = Bridge{i}.AbutmentSet(sub_index).taskUniqueIds;
                        sumWorkDay = 0;
                        for j = 1:length(tasks)
                            temp = Dictionary(tasks{j});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            if temp.WorkingDays > 0
                                sumWorkDay = sumWorkDay + temp.WorkingDays;
                                flag = 0;
                            end
                        end
                         Bridge{i}.WorkingDays = sumWorkDay;
                    end
                    
                    for sub_index = 1:length(Bridge{i}.AbutmentFoundSet)
                        tasks = Bridge{i}.AbutmentFoundSet(sub_index).taskUniqueIds;
                        sumWorkDay = 0;
                        for j = 1:length(tasks)
                            temp = Dictionary(tasks{j});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            if temp.WorkingDays > 0
                                sumWorkDay = sumWorkDay + temp.WorkingDays;
                                flag = 0;
                            end
                        end
                         Bridge{i}.WorkingDays = sumWorkDay;
                    end
                    
                    for sub_index = 1:length(Bridge{i}.BearingSet)
                        tasks = Bridge{i}.BearingSet(sub_index).taskUniqueIds;
                        sumWorkDay = 0;
                        for j = 1:length(tasks)
                            temp = Dictionary(tasks{j});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            if temp.WorkingDays > 0
                                sumWorkDay = sumWorkDay + temp.WorkingDays;
                                flag = 0;
                            end
                        end
                         Bridge{i}.WorkingDays = sumWorkDay;
                    end
                    
                    for sub_index = 1:length(Bridge{i}.SlabSet)
                        tasks = Bridge{i}.SlabSet(sub_index).taskUniqueIds;
                        sumWorkDay = 0;
                        for j = 1:length(tasks)
                            temp = Dictionary(tasks{j});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            if temp.WorkingDays > 0
                                sumWorkDay = sumWorkDay + temp.WorkingDays;
                                flag = 0;
                            end
                        end
                         Bridge{i}.WorkingDays = sumWorkDay;
                    end
                   
                    if Bridge{i}.WorkingDays <= 0 || flag
                        Bridge{i}.Status = 'Open';
                        Bridge{i}.Functionality = 1;
                        total_fixed = total_fixed + 1;
                        need_reschedule = Library.checkNeedReschedule(total_damaged, total_fixed, need_reschedule);
                    end                   
                end

            end
            
            % Road
            for i = 1:length(Road)
                if strcmp(Road{i}.Status, 'Damaged') &&  ~isempty(Road{i}.WorkingDays)
                    Road = Library.getWorkDays(Road, i,Dictionary);
                    if Road{i}.WorkingDays <= 0
                        total_fixed = total_fixed + 1;
                        need_reschedule = Library.checkNeedReschedule(total_damaged, total_fixed, need_reschedule);
                        Road{i}.Status = 'Stoped';
                    end
                end
                if strcmp(Road{i}.Status, 'Stoped')
                    flag = 0;
                    for j = 1:length(Road{i}.Bridge_Carr)
                        if strcmp(Bridge{Road{i}.Bridge_Carr(j)}.Status, 'Damaged')
                            flag = 1;
                            break;
                        end
                    end
                    for j = 1:length(Road{i}.Bridge_Cross)
                        if strcmp(Bridge{Road{i}.Bridge_Cross(j)}.Status, 'Damaged')
                            flag = 1;
                            break;
                        end
                    end
                    
                    if flag == 0
                        Road{i}.Status = 'Open';
                        temp = funcTable(Road{i}.uniqueID);
                        temp(Start_Day:end) = 1;
                        funcTable(Road{i}.uniqueID) = temp;
                        Road{i}.Functionality = 1;
                        transGraph = Library.addTransGraph(Trans, transGraph, i);
                        temp = Dictionary(strcat('RoadNode',num2str(Road{i}.Start_Node)));
                        temp = temp{1};
                        for j = 1:length(temp.Neighborhood)
                            t1 = Dictionary(temp.Neighborhood{j});
                            t1 = t1{1};
                            t1.TransStatus = 1;
                            t1 = Dictionary(temp.Neighborhood_Trans_Link{j});
                            t1 = t1{1};
                            t1.Status = 'Open';
                        end
                        temp = Dictionary(strcat('RoadNode',num2str(Road{i}.End_Node)));
                        temp = temp{1};
                        for j = 1:length(temp.Neighborhood)
                            t1 = Dictionary(temp.Neighborhood{j});
                            t1 = t1{1};
                            t1.TransStatus = 1;
                            t1 = Dictionary(temp.Neighborhood_Trans_Link{j});
                            t1 = t1{1};
                            t1.Status = 'Open';
                        end
                    end
                end
            end
            
            Pow{1} = Branch;
            Pow{2} = Bus;
            Pow{3} = Generator;
            Pow{4} = TransTower;
            
            Comm{2} = Centraloffice;
            Comm{3} = Router;
            Comm{4} = Cellline;
            Comm{5} = CommunicationTower;
            
            Trans{1} = Road;
            Trans{2} = Bridge;
            Trans{3} = TrafficLight;
        end
        
        % Calculated the need for reschedule
        function need_reschedule = checkNeedReschedule(total_damaged, total_fixed, need_reschedule)
            if need_reschedule == 0
                if (total_fixed/total_damaged) >= 0.2
                    %disp(total_fixed);
                    %disp(total_damaged);
                    need_reschedule = 1;
                end
            end
        end
        
        % Calculate actual repair time
        function [Pow, Comm, Trans, Dictionary] = CalculateActualTime(Pow, Comm, Trans, Dictionary)
            % Field
            Branch= Pow{1};
            Bus= Pow{2};
            Generator= Pow{3};
            TransTower = Pow{4};
            
            Centraloffice = Comm{2};
            Router = Comm{3};
            Cellline = Comm{4};
            CommunicationTower = Comm{5};
            
            Road = Trans{1};
            Bridge = Trans{2};
            TrafficLight = Trans{3};
            
            for i = 1:length(Branch)
                if strcmp(Branch{i}.Status, 'Damaged')
                    sum = 0;
                    tasks = Branch{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        temp = Dictionary(tasks{j});
                        if iscell(temp)
                            temp = temp{1};
                        end
                        samples = lhsdesign(1,1);
                        duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                        if duration == 0
                            duration = 1;
                            disp('--');
                            disp(temp);
                        end
                        temp.WorkingDays = duration;
                        %temp.WorkingDays = Library.RepairTime(temp);
                        if(temp.WorkingDays == 0)
                            disp(temp);
                        end
                        sum = sum + temp.WorkingDays;
                    end
                    Branch{i}.WorkingDays = sum;
                end
            end
            
            for i = 1:length(Bus)
                if strcmp(Bus{i}.Status, 'Damaged')
                    sum = 0;
                    tasks = Bus{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        temp = Dictionary(tasks{j});
                        if iscell(temp)
                            temp = temp{1};
                        end
                        samples = lhsdesign(1,1);
                        duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                        if duration == 0
                            duration = 1;
                            disp('--');
                            disp(temp);
                        end
                        temp.WorkingDays = duration;
                        if(temp.WorkingDays == 0)
                            disp(temp);
                        end
                        sum = sum + temp.WorkingDays;
                    end
                    Bus{i}.WorkingDays = sum;
                end
            end
            
            for i = 1:length(TransTower)
                if strcmp(TransTower{i}.Status, 'Damaged')
                    sum = 0;
                    tasks = TransTower{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        temp = Dictionary(tasks{j});
                        if iscell(temp)
                            temp = temp{1};
                        end
                        samples = lhsdesign(1,1);
                        duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                        if duration == 0
                            duration = 1;
                            disp('--');
                            disp(temp);
                        end
                        temp.WorkingDays = duration;
                        if(temp.WorkingDays == 0)
                            disp(temp);
                        end
                        sum = sum + temp.WorkingDays;
                    end
                    TransTower{i}.WorkingDays = sum;
                end
            end
            
            for i = 1:length(Generator)
                if strcmp(Generator{i}.Status, 'Damaged')
                    Generator{i}.WorkingDays = Library.RepairTime(Generator{i});
                end
            end
            
            for i = 1:length(Centraloffice)
                if strcmp(Centraloffice{i}.Status, 'Damaged')
                    sum = 0;
                    tasks = Centraloffice{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        temp = Dictionary(tasks{j});
                        if iscell(temp)
                            temp = temp{1};
                        end
                        samples = lhsdesign(1,1);
                        duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                        if duration == 0
                            duration = 1;
                            disp('--');
                            disp(temp);
                        end
                        temp.WorkingDays = ceil(duration/24);
                        if(temp.WorkingDays == 0)
                            disp(temp);
                        end
                        sum = sum + temp.WorkingDays;
                    end
                    Centraloffice{i}.WorkingDays = sum;
                end
            end
            
            for i = 1:length(Router)
                if strcmp(Router{i}.Status, 'Damaged')
                    sum = 0;
                    tasks = Router{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        temp = Dictionary(tasks{j});
                        if iscell(temp)
                            temp = temp{1};
                        end
                        temp.WorkingDays = ceil(Library.RepairTime(temp)/24);
                        if(temp.WorkingDays == 0)
                            disp(temp);
                        end
                        sum = sum + temp.WorkingDays;
                    end
                    Router{i}.WorkingDays = sum;
                end
            end
            
            for i = 1:length(Cellline)
                if strcmp(Cellline{i}.Status, 'Damaged')
                    sum = 0;
                    tasks = Cellline{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        temp = Dictionary(tasks{j});
                        if iscell(temp)
                            temp = temp{1};
                        end
                        samples = lhsdesign(1,1);
                        duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                        if duration == 0
                            duration = 1;
                            disp('--');
                            disp(temp);
                        end
                        temp.WorkingDays = ceil(duration/24);
                        if(temp.WorkingDays == 0)
                            disp(temp);
                        end
                        sum = sum + temp.WorkingDays;
                    end
                    Cellline{i}.WorkingDays = sum/24;
                end
            end
            
            for i = 1:length(CommunicationTower)
                if strcmp(CommunicationTower{i}.Status, 'Damaged')
                    sum = 0;
                    tasks = CommunicationTower{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        
                        temp = Dictionary(tasks{j});
                        if iscell(temp)
                            temp = temp{1};
                        end
                        samples = lhsdesign(1,1);
                        duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                        if duration == 0
                            duration = 1;
                            disp('--');
                            disp(temp);
                        end
                        temp.WorkingDays = ceil(duration/24);
                        if(temp.WorkingDays == 0)
                            disp(temp);
                        end
                        sum = sum + temp.WorkingDays;
                    end
                    CommunicationTower{i}.WorkingDays = sum;
                end
            end
            
            for i = 1:length(Road)
                if strcmp(Road{i}.Status, 'Damaged')
                    sum = 0;
                    tasks = Road{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        temp = Dictionary(tasks{j});
                        if iscell(temp)
                            temp = temp{1};
                        end
                        samples = lhsdesign(1,1);
                        duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                        if duration == 0
                            duration = 1;
                            disp('--');
                            disp(temp);
                        end
                        temp.WorkingDays = duration * Road{i}.numLanes * Road{i}.Length;
                        if(temp.WorkingDays == 0)
                            disp(temp);
                        end
                        sum = sum + temp.WorkingDays;
                    end
                    Road{i}.WorkingDays = sum;
                end
            end
            
            for i = 1:length(Bridge)
                
                if strcmp(Bridge{i}.Status, 'Damaged') && Bridge{i}.HasSub == 1
                        all_sum = 0
                        for sub_index = 1:length(Bridge{i}.ColumnSet)
                            tasks = Bridge{i}.ColumnSet(sub_index).taskUniqueIds;
                            sum = 0;
                            for j = 1:length(tasks)
                                temp = Dictionary(tasks{j});
                                if iscell(temp)
                                    temp = temp{1};
                                end
                                samples = lhsdesign(1,1);
                                duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                                if duration == 0
                                    duration = 1;
                                    disp('--');
                                    disp(temp);
                                end
                                temp.WorkingDays = duration;
                                if(temp.WorkingDays <= 0)

                                end
                                sum = sum + temp.WorkingDays;
                                
                            end
                            Bridge{i}.ColumnSet(sub_index).WorkingDays = sum;
                            all_sum = all_sum + sum
                        end
                        
                        for sub_index = 1:length(Bridge{i}.ColumnFoundSet)
                            tasks = Bridge{i}.ColumnFoundSet(sub_index).taskUniqueIds;
                            sum = 0;
                            for j = 1:length(tasks)
                                temp = Dictionary(tasks{j});
                                if iscell(temp)
                                    temp = temp{1};
                                end
                                samples = lhsdesign(1,1);
                                duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                                if duration == 0
                                    duration = 1;
                                    disp('--');
                                    disp(temp);
                                end
                                temp.WorkingDays = duration;
                                if(temp.WorkingDays <= 0)

                                end
                                sum = sum + temp.WorkingDays;
                                
                            end
                            Bridge{i}.ColumnFoundSet(sub_index).WorkingDays = sum;
                            all_sum = all_sum + sum
                        end
                        
                        for sub_index = 1:length(Bridge{i}.AbutmentSet)
                            tasks = Bridge{i}.AbutmentSet(sub_index).taskUniqueIds;
                             sum = 0;
                            for j = 1:length(tasks)
                                temp = Dictionary(tasks{j});
                                if iscell(temp)
                                    temp = temp{1};
                                end
                                samples = lhsdesign(1,1);
                                duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                                if duration == 0
                                    duration = 1;
                                    disp('--');
                                    disp(temp);
                                end
                                temp.WorkingDays = duration;
                                if(temp.WorkingDays <= 0)

                                end
                                sum = sum + temp.WorkingDays;
                                
                            end
                            Bridge{i}.AbutmentSet(sub_index).WorkingDays = sum;
                            all_sum = all_sum + sum
                        end
                        
                        for sub_index = 1:length(Bridge{i}.AbutmentFoundSet)
                            tasks = Bridge{i}.AbutmentFoundSet(sub_index).taskUniqueIds;
                            sum = 0;
                            for j = 1:length(tasks)
                                temp = Dictionary(tasks{j});
                                if iscell(temp)
                                    temp = temp{1};
                                end
                                samples = lhsdesign(1,1);
                                duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                                if duration == 0
                                    duration = 1;
                                    disp('--');
                                    disp(temp);
                                end
                                temp.WorkingDays = duration;
                                if(temp.WorkingDays <= 0)

                                end
                                sum = sum + temp.WorkingDays;
                                
                            end
                            Bridge{i}.AbutmentFoundSet(sub_index).WorkingDays = sum;
                            all_sum = all_sum + sum
                        end
                        
                        for sub_index = 1:length(Bridge{i}.BearingSet)
                            tasks = Bridge{i}.BearingSet(sub_index).taskUniqueIds;
                            sum = 0;
                            for j = 1:length(tasks)
                                temp = Dictionary(tasks{j});
                                if iscell(temp)
                                    temp = temp{1};
                                end
                                samples = lhsdesign(1,1);
                                duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                                if duration == 0
                                    duration = 1;
                                    disp('--');
                                    disp(temp);
                                end
                                temp.WorkingDays = duration;
                                if(temp.WorkingDays <= 0)

                                end
                                sum = sum + temp.WorkingDays;
                                
                            end
                            Bridge{i}.BearingSet(sub_index).WorkingDays = sum;
                            all_sum = all_sum + sum
                        end
                        for sub_index = 1:length(Bridge{i}.SlabSet)
                            tasks = Bridge{i}.SlabSet(sub_index).taskUniqueIds;
                            sum = 0;
                            for j = 1:length(tasks)
                                temp = Dictionary(tasks{j});
                                if iscell(temp)
                                    temp = temp{1};
                                end
                                samples = lhsdesign(1,1);
                                duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                                if duration == 0
                                    duration = 1;
                                    disp('--');
                                    disp(temp);
                                end
                                temp.WorkingDays = duration;
                                if(temp.WorkingDays <= 0)

                                end
                                sum = sum + temp.WorkingDays;
                                
                            end
                            Bridge{i}.SlabSet(sub_index).WorkingDays = sum;
                            all_sum = all_sum + sum
                        end
                        Bridge{i}.WorkingDays = all_sum;
           
                elseif strcmp(Bridge{i}.Status, 'Damaged')
%                 if strcmp(Bridge{i}.Status, 'Damaged')
                    sum = 0;
                    tasks = Bridge{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        temp = Dictionary(tasks{j});
                        if iscell(temp)
                            temp = temp{1};
                        end
                        samples = lhsdesign(1,1);
                        duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                        if duration == 0
                            duration = 1;
                            disp('--');
                            disp(temp);
                        end
                        temp.WorkingDays = duration * Bridge{i}.MaxSpanLength/48.8;
                        if(temp.WorkingDays <= 0)
                            
                        end
                        sum = sum + temp.WorkingDays;
                    end
                    Bridge{i}.WorkingDays = sum;
                end
            end
            
            for i = 1:length(TrafficLight)
                if strcmp(TrafficLight{i}.Status, 'Damaged')
                    sum = 0;
                    tasks = TrafficLight{i}.taskUniqueIds;
                    for j = 1:length(tasks)
                        temp = Dictionary(tasks{j});
                        if iscell(temp)
                            temp = temp{1};
                        end
                        samples = lhsdesign(1,1);
                        duration = round(Library.simulatervLHS(samples,temp.durationType, [temp.durationMin,temp.durationMode ,temp.durationMax]));
                        if duration == 0
                            duration = 1;
                            disp('--');
                            disp(temp);
                        end
                        temp.WorkingDays = duration;
                        if(temp.WorkingDays == 0)
                            disp(temp);
                        end
                        sum = sum + temp.WorkingDays;
                    end
                    TrafficLight{i}.WorkingDays = sum;
                end
            end
            disp('Done Checking');
        end
        
        % Update the remain working days for current working component
        function WorkingProcess(Current,Dictionary, Days)
            for i = 1:length(Current)
                if isempty(Current{i})
                    continue;
                end
                uniqueId = Library.getUniqueId(Current{i}, 1);
                temp = Dictionary(uniqueId);
                if iscell(temp)
                    temp = temp{1};
                end
                temp.WorkingDays = temp.WorkingDays - Days;
            end
        end
        
        function [return_Schedule,Max] = Clean(Current,Dictionary, Max)
            for i = 1:length(Current)
                if ~isempty(Current{i})
                    temp = Dictionary(Library.getUniqueId(Current{i}, 1));
                    if iscell(temp)
                        temp = temp{1};
                    end
                    if temp.WorkingDays <= 0
                        for j = 1:length(Max)
                            %                             fprintf('Clean out: %s\n',Current{i});
                            resourceNeed = Library.getResource(Current{i}, Dictionary,j, 1);
                            Max(j) = Max(j) + resourceNeed;
                        end
                        %temp.WorkingDays = 0;
                        Current{i} = [];
                    end
                end
            end
            return_Schedule = Current;
        end
        
        % Calculate the repair time
        function Time_Component = RepairTime(Component)
            m=Component.RecoveryMatrix(1);
            v=Component.RecoveryMatrix(2);
            mu = log((m^2)/sqrt(v+m^2));
            sigma = sqrt(log(v/(m^2)+1));
            Time_Component=round(lognrnd(mu,sigma));
            if(Time_Component <= 0)
                Time_Component = 1;
            end
        end
        
        % Find minimum working day for all current working component
        function day = FindMinDays(Current_Power, Current_Comm, Current_Trans, Pow, Comm, Trans, Dictionary)
            % Field
            Branch= Pow{1};
            Bus= Pow{2};
            Generator= Pow{3};
            TransTower = Pow{4};
            
            Centraloffice = Comm{2};
            Router = Comm{3};
            Cellline = Comm{4};
            CommunicationTower = Comm{5};
            
            Road = Trans{1};
            Bridge = Trans{2};
            TrafficLight = Trans{3};
            
            flag = 0;
            day = 99999999;
            
            for i = 1:length(Current_Power)
                if ~isempty(Current_Power{i})
                    flag = 1;
                    tem = strsplit(Current_Power{i},'/');
                    
                    if strcmp(tem(1), 'Branch') && strcmp(Branch{str2double(tem(2))}.Status, 'Damaged')
                        if length(tem) == 4
                            day = min(day,Branch{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                    elseif strcmp(tem(1), 'Bus') && strcmp(Bus{str2double(tem(2))}.Status, 'Damaged')
                        if length(tem) == 4
                            day = min(day, Bus{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                    elseif strcmp(tem(1), 'TransmissionTower') && strcmp(Bus{str2double(tem(2))}.Status, 'Damaged')
                        if length(tem) == 4
                            day = min(day, TransTower{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                    elseif strcmp(tem(1), 'Generator') && strcmp(Generator{str2double(tem(2))}.Status, 'Damaged')
                        if length(tem) == 4
                            day = min(day, Generator{str2double(tem(2))}.WorkingDays);
                            if Generator{str2double(tem(2))}.WorkingDays <= 0
                                disp(tem{2});
                            end
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                    else
                    end
                end
                
            end
            %             disp(day);
            
            for i = 1:length(Current_Comm)
                if ~isempty(Current_Comm{i})
                    flag = 1;
                    tem = strsplit(Current_Comm{i},'/');
                    if strcmp(tem(1), 'Centraloffice') && strcmp(Centraloffice{str2double(tem(2))}.Status, 'Damaged')
                        if length(tem) == 4
                            day = min(day, Centraloffice{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                    elseif strcmp(tem(1), 'Router')&& strcmp(Router{str2double(tem(2))}.Status, 'Damaged')
                        if length(tem) == 4
                            day = min(day, Router{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                    elseif strcmp(tem(1), 'Cellline')&& strcmp(Cellline{str2double(tem(2))}.Status, 'Damaged')
                        if length(tem) == 4
                            day = min(day, Cellline{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                    elseif strcmp(tem(1), 'CommunicationTower')&& strcmp(CommunicationTower{str2double(tem(2))}.Status, 'Damaged')
                        if length(tem) == 4
                            day = min(day, CommunicationTower{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                    else
                    end
                end
            end
            %             disp(day);
            
            for i = 1:length(Current_Trans)
                if ~isempty(Current_Trans{i})
                    flag = 1;
                    tem = strsplit(Current_Trans{i},'/');
                    
                    if strcmp(tem(1), 'Road')&& strcmp(Road{str2double(tem(2))}.Status, 'Damaged')
                        if length(tem) == 4
                            day = min(day, Road{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                    elseif strcmp(tem(1), 'Bridge')&& strcmp(Bridge{str2double(tem(2))}.Status, 'Damaged')
                        
                        if length(tem) == 4
                            day = min(day, Bridge{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                        
                    %subcomponent    
                    elseif strcmp(tem(1), 'Abutment')&& strcmp(Bridge{str2double(tem(2))}.Status, 'Damaged')
                        
                        if length(tem) == 4
                            day = min(day, Bridge{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                    elseif strcmp(tem(1), 'AbutmentFoundation')&& strcmp(Bridge{str2double(tem(2))}.Status, 'Damaged')
                        
                        if length(tem) == 4
                            day = min(day, Bridge{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                    elseif strcmp(tem(1), 'ApproachSlab')&& strcmp(Bridge{str2double(tem(2))}.Status, 'Damaged')
                        
                        if length(tem) == 4
                            day = min(day, Bridge{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                    elseif strcmp(tem(1), 'Bearing')&& strcmp(Bridge{str2double(tem(2))}.Status, 'Damaged')
                        
                        if length(tem) == 4
                            day = min(day, Bridge{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                       elseif strcmp(tem(1), 'Column')&& strcmp(Bridge{str2double(tem(2))}.Status, 'Damaged')
                        
                        if length(tem) == 4
                            day = min(day, Bridge{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                        elseif strcmp(tem(1), 'ColumnFoundation')&& strcmp(Bridge{str2double(tem(2))}.Status, 'Damaged')
                        
                        if length(tem) == 4
                            day = min(day, Bridge{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                        elseif strcmp(tem(1), 'Deck')&& strcmp(Bridge{str2double(tem(2))}.Status, 'Damaged')
                        
                        if length(tem) == 4
                            day = min(day, Bridge{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                        elseif strcmp(tem(1), 'Girder')&& strcmp(Bridge{str2double(tem(2))}.Status, 'Damaged')
                        
                        if length(tem) == 4
                            day = min(day, Bridge{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end                        
                        
                        
                    elseif strcmp(tem(1), 'TrafficLight')&& strcmp(TrafficLight{str2double(tem(2))}.Status, 'Damaged')
                        if length(tem) == 4
                            day = min(day, TrafficLight{str2double(tem(2))}.WorkingDays);
                        elseif length(tem) == 5
                            temp = Dictionary(tem{3});
                            if iscell(temp)
                                temp = temp{1};
                            end
                            day = min(day,temp.WorkingDays);
                            if temp.WorkingDays <= 0
                                disp(tem{3});
                            end
                        end
                    else
                    end
                    
                end
            end
            
            if (isempty(day)|| day <= 0) && flag == 1
                disp('error')
                
            end
            if day == 99999999
                day = 0;
            end
        end
        
        % Add back node or edge back to the graph if fixed
        function G = addTransGraph(Trans_Set, G, index)
            hash = containers.Map('KeyType','double','ValueType','char');
            road_Set = Trans_Set{1};
            roadnode_Set = Trans_Set{4};
            for i = 1:length(roadnode_Set)
                hash(roadnode_Set{i}.nodeID) = roadnode_Set{i}.uniqueID;
            end
            s = hash(road_Set{index}.Start_Node);
            t = hash(road_Set{index}.End_Node);
            G = addedge(G, s, t, road_Set{index}.Length);
        end
        
        % Add back node or edge back to the graph if fixed
        function commGraph = addCommGraph(Comm, commGraph, index,Dictionary)
            Cellline = Comm{4};
            s = Cellline{index}.connectedObj1;
            t = Cellline{index}.connectedObj2;
            temp1 = Dictionary(Cellline{index}.connectedObj1);
            temp2 = Dictionary(Cellline{index}.connectedObj2);
            temp1 = temp1{1};
            temp2 = temp2{1};
            weight = distance(temp1.Location(1), temp1.Location(2), temp2.Location(1),temp2.Location(2),referenceSphere('earth','km'));
            commGraph = addedge(commGraph, s, t, weight);
        end
        
        % Add back node or edge back to the graph if fixed
        function powerGraph = addPowerGraph(Power, powerGraph, index,Dictionary)
            Branch = Power{1};
            s = Branch{index}.connectedObj1;
            t = Branch{index}.connectedObj2;
            temp1 = Dictionary(Branch{index}.connectedObj1);
            temp2 = Dictionary(Branch{index}.connectedObj2);
            temp1 = temp1{1};
            temp2 = temp2{1};
            weight = distance(temp1.Location(1), temp1.Location(2), temp2.Location(1),temp2.Location(2),referenceSphere('earth','km'));
            powerGraph = addedge(powerGraph, s, t, weight);
        end
        
        % Compute Functionality based on graph status
        % (NOT BEING USED FOR NOW)
        %% functions for computing system functinality according to graph theory
        % Compute Functionality based on graph status
        % (NOT BEING USED FOR NOW)
%         function result = ComputeFunc(Graph, Start_Day, End_Day,result)
%             [G,Gaveragedegree,L,EGlob,CClosed,ELocClosed,COpen,ELocOpen] = Library2.computeGraphNetwork(Graph,adjacency(Graph),LinkDirectionChoice);
%             
%             result(1,Start_Day:End_Day) = Gaveragedegree;
%             result(2,Start_Day:End_Day) = L;
%             result(3,Start_Day:End_Day) = EGlob;
%         end

        function result = Functionality_GraphBasic(Graph, LinkDirectionChoice, Start_Day, End_Day,result)
            [G,Gaveragedegree,L,EGlob,CClosed,ELocClosed,COpen,ELocOpen] = Library2.computeGraphNetwork(Graph,adjacency(Graph),LinkDirectionChoice);
            
            result(1,Start_Day:End_Day) = Gaveragedegree;
            result(2,Start_Day:End_Day) = L;
            result(3,Start_Day:End_Day) = EGlob;
        end
%         function result = Functionality_GraphBasic(Graph, LinkDirectionChoice)
%             [G,Gaveragedegree,L,EGlob,CClosed,ELocClosed,COpen,ELocOpen] = Library2.computeGraphNetwork(Graph,adjacency(Graph),LinkDirectionChoice);
%             
%             result(1) = Gaveragedegree;
%             result(2) = L;
%             result(3) = EGlob;
%         end
%         
        
%         
        function SystemFunctionality = Functionality_WeightNetwork(Sys, Data) 
            count = 0;
            switch Sys
                % Transportation
                case 1
                    Transportation_Set = Data; 
                    Road_Set = Transportation_Set{1};
                    n = length(Road_Set);
                    for ii = 1:n
                        IF(ii) = Road_Set{ii}.Length; %InfluenceFactor as road segment length
%                         IF(ii) = Road_Set{ii}.Traffic; %InfluenceFactor as traffic 
%                         IF(ii) = Road_Set{ii}.Length * Road_Set{ii}.Traffic; %InfluenceFactor as traffic*length                    
                        if strcmp(Road_Set{ii}.Status,'Open')
                            count = count + IF(ii);
                        else 
                            count = count;
                        end
                    end       
                    
                case 2
                    Power_Set = Data;
                    Bus_Set = Power_Set{2};
                    n = length(Bus_Set);
                    for ii = 1:n
                        IF(ii) = Bus_Set{ii}.Capacity; %InfluenceFactor as bus capacity
                        if strcmp(Bus_Set{ii}.Status,'Open')
                            count = count + IF(ii);
                        else 
                            count = count;
                        end
                    end
                    
                case 3
                    Communication_Set = Data;
                     return;

            end
            
            SystemFunctionality = count/sum(IF);
                    
        end
            
        
        
        %% Functionality
        
        % Functionality of ths Power system = Percentage of Branches that have electricity
        % Calculate the functionality of power
        function Function = Functionality_PowerBasic(Power_Set)
            Bus_Set = Power_Set{1};  
            Num_Hous=length(Bus_Set);
            Num_Hous_Open=0;
            for i=1: Num_Hous
                if strcmp(Bus_Set{i}.Status,'Open')
                    Num_Hous_Open=Num_Hous_Open+1;
                else
                end
            end
            Function=Num_Hous_Open/Num_Hous;
        end
        
        % Functionality of ths Transportation system = Connectivity of each Points on the Map
        % Calculate the functionality of transportation
        function Function = Functionality_TransportationBasic(Trans)
            Bridge = Trans{2};
            
            score = 0;
            
            %             for i = 1:length(Road)
            %                 if strcmp(Road{i}.Status, 'Open')
            %                     score = score + 1;
            %                 elseif strcmp(Road{i}.Status, 'Stoped')
            %                     score = score + 0.5;
            %                 end
            %             end
            
            for i = 1:length(Bridge)
                if strcmp(Bridge{i}.Status, 'Open')
                    score = score + 1;
                else
                end
            end
            
            Function = score/length(Bridge);
        end
        
        % Functionality of ths Communication system = Connectivity of each Central Office
        % Calculated the functionality of communication
        function Function = Functionality_CommunicationBasic(Comm)
            total = 0;
            open = 0;
            for i = 1:length(Comm)
                for j = 1:length(Comm{i})
                    total = total + 1;
                    if strcmp(Comm{i}{j}.Status, 'Open')
                        open = open + 1;
                    end
                end
            end
            Function = open/total;
        end
        
        
        %% computer system resilience
        % INPUT - RessilienceMetric
        % 1. RessilienceMetric = 1 as resilience index (Reed et al. 2009)
        % 2. RessilienceMetric = 2 as resilience loss (Sun et al. 2018)
        % 3. RessilienceMetric = 3 as rapidity (Sun et al. 2018)
        %
        % Reed et al. (2009) "Methodology for Assessing the Resilience of
        % Networked Infrastructure", IEEE SYSTEMS JOURNAL, VOL. 3, NO. 2,
        % 174-180.  https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=4912342
        % Sun et al. (2018) "Resilience metrics and measurement methods
        % for transportation infrastructure: the state of the art". 
        % Sustainable and Resilient Infrastructure, DOI: 10.1080/23789689.2018.1448663.
        function Resilience = computeResilience(ResilienceMetricChoice, time_horizon, Functionality_Power, Functionality_Communication, Functionality_Transportation)
%             N = size(Functionality_Power,1); % total number of samples
%             Resilience_Power = zeros(1,N);
%             Resilience_Communication = zeros(1,N);
%             Resilience_Transportation = zeros(1,N);
            
            switch ResilienceMetricChoice
                case 1  % resilience index               
                    Resilience_Power = inv(time_horizon)*sum(Functionality_Power,2)';
                    Resilience_Communication = inv(time_horizon)*sum(Functionality_Communication,2)';
                    Resilience_Transportation = inv(time_horizon)*sum(Functionality_Transportation,2)';
                case 2 % resilience loss
                    Resilience_Power = sum(Functionality_Power,2)';
                    Resilience_Communication = sum(Functionality_Communication,2)';
                    Resilience_Transportation = sum(Functionality_Transportation,2)';
                case 3 % rapidity
                    N = size(Functionality_Power,1); % total number of samples
                    clearvars data; data = Functionality_Power;
                    for ii = 1:N
                        m1 = max(data(ii,:),[],2);
                        m2 = min(data(ii,:),[],2);
                        i1 = find(data(ii,:) == m1);
                        i2 = find(data(ii,:) == m2);
                        Resilience_Power = inv(i1-i2)*(m1-m2);
                    end
                    
                    clearvars data; data = Functionality_Communication;
                    for ii = 1:N
                        m1 = max(data(ii,:),[],2);
                        m2 = min(data(ii,:),[],2);
                        i1 = find(data(ii,:) == m1);
                        i2 = find(data(ii,:) == m2);
                        Resilience_Communication = inv(i1-i2)*(m1-m2);
                    end
                    
                    clearvars data; data = Functionality_Transportation;
                    for ii = 1:N
                        m1 = max(data(ii,:),[],2);
                        m2 = min(data(ii,:),[],2);
                        i1 = find(data(ii,:) == m1);
                        i2 = find(data(ii,:) == m2);
                        Resilience_Transportation = inv(i1-i2)*(m1-m2);
                    end
                    
            end
            
             Resilience{1} = Resilience_Power;
             Resilience{2} = Resilience_Communication;
             Resilience{3} = Resilience_Transportation;
            
        end
        
        function [FunctionalityStatistics, ResilienceStatistics] = computeStatistics(Functionality_Power, Functionality_Communication, Functionality_Transportation, Resilience)
        % FunctionalityStatistics = {Functionality_Statistics_Power, Functionality_Statistics_Communication, Functionality_Statistics_Transportation}
        % Functionality_Statistics_Power = [mean(FunctionalitySample1), % mean(FunctionalitySample2), ...;
        %                                    std(FunctionalitySample1), std(FunctionalitySample2), ...]
        
            clearvars data; data = Functionality_Power;              
            Functionality_Statistics_Power = [mean(data); std(data); min(data); max(data); prctile(data,25); prctile(data,50); prctile(data,75)];
            clearvars data; data = Functionality_Communication;              
            Functionality_Statistics_Communication = [mean(data); std(data); min(data); max(data); prctile(data,25); prctile(data,50); prctile(data,75)];
            clearvars data; data = Functionality_Transportation;              
            Functionality_Statistics_Transportation = [mean(data); std(data); min(data); max(data); prctile(data,25); prctile(data,50); prctile(data,75)];
            
            FunctionalityStatistics{1} = Functionality_Statistics_Power;
            FunctionalityStatistics{2} = Functionality_Statistics_Communication;
            FunctionalityStatistics{3} = Functionality_Statistics_Transportation;
            
            for ii = 1:3
                ResilienceStatistics{ii} = [mean(Resilience{ii}), std(Resilience{ii}), min(Resilience{ii}), max(Resilience{ii}), prctile(Resilience{ii},25),  prctile(Resilience{ii},50),  prctile(Resilience{ii},75)];
            end
            
        end
        
        
        %% Plot and Data Managment
        % Save the Data log to text file
        function SaveDataLog(num, Pow, Comm, Trans)
            % Field
            Branch= Pow{1};
            Bus= Pow{2};
            Generator= Pow{3};
            
            Centraloffice = Comm{2};
            Router = Comm{3};
            Cellline = Comm{4};
            CommunicationTower = Comm{5};
            
            Road = Trans{1};
            Bridge = Trans{2};
            TrafficLight = Trans{3};
            
            [~, name] = system('hostname');
            
            fileID = fopen(strcat('./', deblank(name), '/txt/data.txt'),'a');
            
            if num > 1
                fprintf(fileID,'\n');
            end
            
            fprintf(fileID,'Sample %3d:\n',num);
            fprintf(fileID,'Power System:\n');
            
            fprintf(fileID,'Generator:\n');
            fprintf(fileID,'Number  Location Status  Type\n');
            
            for i = 1:length(Generator)
                fprintf(fileID,'%-6d %-8s %-7s %-20s\n', Generator{i}.Number, strcat('[', num2str(Generator{i}.Location), ']'), Generator{i}.Status, Generator{i}.Type);
            end
            
            fprintf(fileID,'Bus:\n');
            fprintf(fileID,'Number Location Generator Status  Type\n');
            
            for i = 1:length(Bus)
                if isempty(Bus{i}.Generator)
                    gen = ' ';
                else
                    gen = num2str(Bus{i}.Generator);
                end
                fprintf(fileID,'%-6d %-8s %-9s %-7s %-20s\n', Bus{i}.Number, strcat('[', num2str(Bus{i}.Location), ']'), gen, Bus{i}.Status, Bus{i}.Type);
            end
            
            fprintf(fileID,'Branch:\n');
            fprintf(fileID,'Number Start_Location End_Location Status  Type\n');
            
            for i = 1:length(Branch)
                fprintf(fileID,'%-6d %-14s %-12s %-7s %-20s\n', Branch{i}.Number, strcat('[', num2str(Branch{i}.Start_Location), ']'), strcat('[', num2str(Branch{i}.End_Location), ']'), Branch{i}.Status, Branch{i}.Type);
            end
            
            fprintf(fileID,'Communication System:\n');
            
            
            fprintf(fileID,'Centraloffice:\n');
            fprintf(fileID,'Number Location Status  Type\n');
            
            for i = 1:length(Centraloffice)
                fprintf(fileID,'%-6d %-8s %-7s %-20s\n', Centraloffice{i}.Number, strcat('[', num2str(Centraloffice{i}.Location), ']'), Centraloffice{i}.Status, Centraloffice{i}.Type);
            end
            
            fprintf(fileID,'Router:\n');
            fprintf(fileID,'Number Location Status  Type\n');
            
            for i = 1:length(Router)
                fprintf(fileID,'%-6d %-8s %-7s %-20s\n', Router{i}.Number, strcat('[', num2str(Router{i}.Location), ']'), Router{i}.Status, Router{i}.Type);
            end
            
            fprintf(fileID,'Cellline:\n');
            fprintf(fileID,'Number Start_Location End_Location Status  Type\n');
            
            for i = 1:length(Cellline)
                fprintf(fileID,'%-6d %-14s %-12s %-7s %-20s\n', Cellline{i}.Number, strcat('[', num2str(Cellline{i}.Start_Location), ']'), strcat('[', num2str(Cellline{i}.End_Location), ']'), Cellline{i}.Status, Cellline{i}.Type);
            end
            
            fprintf(fileID,'CommunicationTower:\n');
            fprintf(fileID,'Number Location Status  Type\n');
            
            for i = 1:length(CommunicationTower)
                fprintf(fileID,'%-6d %-8s %-7s %-20s\n', CommunicationTower{i}.Number, strcat('[', num2str(CommunicationTower{i}.Location), ']'), CommunicationTower{i}.Status, CommunicationTower{i}.Type);
            end
            
            fprintf(fileID,'Transportation System:\n');
            
            fprintf(fileID,'Road:\n');
            fprintf(fileID,'Number Start_Location End_Location Status          Type\n');
            
            for i = 1:length(Road)
                fprintf(fileID,'%-6d %-14s %-12s %-15s %-20s\n', Road{i}.Number, strcat('[', num2str(Road{i}.Start_Location), ']'), strcat('[', num2str(Road{i}.End_Location), ']'), Road{i}.Status, Road{i}.Type);
            end
            
            fprintf(fileID,'Bridge:\n');
            fprintf(fileID,'Number Location Status  Type\n');
            
            for i = 1:length(Bridge)
                fprintf(fileID,'%-6d %-8s %-7s %-20s\n', Bridge{i}.Number, strcat('[', num2str(Bridge{i}.Location), ']'), Bridge{i}.Status, Bridge{i}.Type);
            end
            
            fprintf(fileID,'TrafficLight:\n');
            fprintf(fileID,'Number Location Status  Type\n');
            
            for i = 1:length(TrafficLight)
                fprintf(fileID,'%-6d %-8s %-7s %-20s\n', TrafficLight{i}.Number, strcat('[', num2str(TrafficLight{i}.Location), ']'), TrafficLight{i}.Status, TrafficLight{i}.Type);
            end
            
            fclose(fileID);
        end
        
        % Save the Schedule log to text file
        function SaveScheduleLog(sample, run, total_schedule, total_date)
            [~, name] = system('hostname');
            fileID = fopen(strcat('./', deblank(name), '/txt/schedule.txt'),'a');
            for i = 1:sample
                for j = 1:run
                    schedule = total_schedule{i};
                    
                    pow = schedule{1};
                    comm = schedule{2};
                    trans = schedule{3};
                    
                    if i > 1 || j > 1
                        fprintf(fileID,'\n');
                    end
                    
                    fprintf(fileID,'Sample %4d Run %4d:\n', i, j);
                    
                    fprintf(fileID,'Power System:\n');
                    fprintf(fileID,'%-20s %-5s %-5s\n','Compoment', 'Number', 'Date');
                    
                    for k = 1:length(pow)
                        tem = strsplit(pow{k},'/');
                        date = 0;
                        if ~isempty(total_date{(i-1)*run + run}{1})
                            date = total_date{(i-1)*run + run}{1}(k);
                        end
                        fprintf(fileID,'%-20s %-5s %-5s\n',char(tem(1)), char(tem(2)), num2str(date));
                    end
                    
                    fprintf(fileID,'Communication System:\n');
                    fprintf(fileID,'%-20s %-5s %-5s\n','Compoment', 'Number', 'Date');
                    
                    for k = 1:length(comm)
                        tem = strsplit(comm{k},'/');
                        date = 0;
                        if ~isempty(total_date{(i-1)*run + run}{2})
                            date = total_date{(i-1)*run + run}{2}(k);
                        end
                        fprintf(fileID,'%-20s %-5s %-5s\n',char(tem(1)), char(tem(2)), num2str(date));
                    end
                    
                    fprintf(fileID,'Transportation System:\n');
                    fprintf(fileID,'%-20s %-5s %-5s\n','Compoment', 'Number', 'Date');
                    
                    for k = 1:length(trans)
                        tem = strsplit(trans{k},'/');
                        date = 0;
                        if ~isempty(total_date{(i-1)*run + run}{3})
                            date = total_date{(i-1)*run + run}{3}(k);
                        end
                        fprintf(fileID,'%-20s %-5s %-5s\n',char(tem(1)), char(tem(2)), num2str(date));
                    end
                end
            end
            
            fclose(fileID);
        end
        
        % Save the Functionality log to text file
        function SaveFunctionalityLog(sample, run, time, Pow, Comm, Trans)
            [~, name] = system('hostname');
            fileID = fopen(strcat('./', deblank(name), '/txt/functionality.txt'),'a');
            
            for i = 1:sample
                for j = 1:run
                    if i > 1 || j > 1
                        fprintf(fileID,'\n');
                    end
                    
                    fprintf(fileID,'Sample %4d Run %4d:\n', i, j);
                    
                    fprintf(fileID,'%-17s', 'Day: ');
                    for k = 1:time
                        fprintf(fileID,'%-7s ', num2str(k));
                    end
                    fprintf(fileID,'\n');
                    
                    fprintf(fileID,'%-17s', 'Power: ');
                    for k = 1:length(Pow((i-1)*run + j,:))
                        fprintf(fileID,'%-7s ', num2str(Pow((i-1)*run + j, k)));
                    end
                    fprintf(fileID,'\n');
                    
                    fprintf(fileID,'%-17s', 'Communication: ');
                    for k = 1:length(Comm((i-1)*run + j,:))
                        fprintf(fileID,'%-7s ', num2str(Comm((i-1)*run + j, k)));
                    end
                    fprintf(fileID,'\n');
                    
                    fprintf(fileID,'%-17s', 'Transportation: ');
                    for k = 1:length(Trans((i-1)*run + j,:))
                        fprintf(fileID,'%-7s ', num2str(Trans((i-1)*run + j, k)));
                    end
                    fprintf(fileID,'\n');
                end
            end
            fclose(fileID);
        end
        
        % Plot all figures
        function PlotFigure(Nsamples, run, time_horizon, Functionality_Power, Functionality_Communication, Functionality_Transportation)
            % Power Figure
            [~, name] = system('hostname');
            p = figure('visible','off');
            
            for i=1:Nsamples*run
                subplot(2,1,1);
                plot([1:time_horizon], Functionality_Power(i,:));
                hold on
            end
            
            xlabel('Time (day)');
            ylabel('Power Functionality');
            title('Power System');
            
            if Nsamples>=2
                subplot(2,1,2);
                mf=mean(Functionality_Power);
                plot([1:time_horizon], mf(1,:));
                xlabel('Time (day)');
                ylabel('mean Power Functionality mean');
            end
            
            saveas(p,strcat('./', deblank(name), '/plot/Power.jpg'));
            
            % Comunication Figure
            c = figure('visible','off');
            
            for i=1:Nsamples*run
                subplot(2,1,1);
                plot([1:time_horizon], Functionality_Communication(i,:));
                hold on
            end
            
            xlabel('Time (day)');
            ylabel('Communication Functionality');
            title('Comunication System');
            
            if Nsamples>=2
                subplot(2,1,2);
                mf=mean(Functionality_Communication);
                plot([1:time_horizon], mf(1,:));
                xlabel('Time (day)');
                ylabel('mean Communication Functionality mean');
            end
            
            saveas(c,strcat('./', deblank(name), '/plot/Comunication.jpg'));
            
            % Transportation Figure
            t = figure('visible','off');
            
            for i=1:Nsamples*run
                subplot(2,1,1);
                plot([1:time_horizon], Functionality_Transportation(i,:));
                hold on
            end
            
            xlabel('Time (day)');
            ylabel('Transportation Functionality');
            title('Transportation System');
            
            if Nsamples>=2
                subplot(2,1,2);
                mf=mean(Functionality_Transportation);
                plot([1:time_horizon], mf(1,:));
                xlabel('Time (day)');
                ylabel('mean Transportation Functionality mean');
            end
            saveas(t,strcat('./', deblank(name), '/plot/Transportation.jpg'));
        end
        
        
        
        
        
        
        % Reset Data
        function [Power, Comm, Trans, Dictionary,Neighborhood] = ResetData(filename)
            clear Total;
            load(filename);
            Power = Total{1};
            Comm = Total{2};
            Trans = Total{3};
            Dictionary = Total{4};
            Neighborhood = Total{5};
        end
        
        % Clean old .txt .jpg .mat files
        function CleanOldData()
            [~, name] = system('hostname');
            ans = exist(deblank(name),'dir');
            if ans == 7
                rmdir(deblank(name), 's');
            end
        end
        
        % Create Folder
        function CreateFolder()
            [~, name] = system('hostname');
            x = exist(deblank(name),'dir');
            if x ~= 7
                mkdir(deblank(name));
            end
            
            filename = strcat('./', deblank(name),'/mat');
            x = exist(filename,'dir');
            if x ~= 7
                mkdir(filename);
            end
            
            filename = strcat('./', deblank(name),'/txt');
            x = exist(filename,'dir');
            if x ~= 7
                mkdir(filename);
            end
            
            filename = strcat('./', deblank(name),'/plot');
            x = exist(filename,'dir');
            if x ~= 7
                mkdir(filename);
            end
        end
        
        %% Read Input File
        function [power, trans, comm, Neighborhood_Set] = readInput(filename, pow_check, comm_check, trans_check, Pow, Trans, Comm, Dictionary, Neighborhood_Set)
            tmp = strsplit(filename,'.');
            name = tmp{1};
            type = tmp{2};
            %
            
            
            if strcmp(type, 'xlsx')
                [num,txt,raw] = xlsread(filename);
            elseif strcmp(type, 'csv')
                table = readtable(filename);
            end
            
            % Field
            Branch_Set= Pow{1};
            Bus_Set = Pow{2};
            Generator_Set = Pow{3};
            
            Centraloffice_Set = Comm{2};
            Router_Set = Comm{3};
            Cellline_Set = Comm{4};
            CommunicationTower_Set = Comm{5};
            
            Road_Set = Trans{1};
            Bridge_Set = Trans{2};
            TrafficLight_Set = Trans{3};
            RoadNode_Set = Trans{4};
            Task_Set = {};
            
            centraloffice_check = comm_check{2};
            communicationtower_check = comm_check{3};
            bridge_check = trans_check{1};
            trafficlight_check = trans_check{2};
            road_check = trans_check{3};
            
            index_Branch = length(Branch_Set) + 1;
            index_Generator = length(Generator_Set) + 1;
            index_Bus = length(Bus_Set) + 1;
            index_Centraloffice = length(Centraloffice_Set) + 1;
            index_Communicationtower = length(CommunicationTower_Set) + 1;
            index_Road = length(Road_Set) + 1;
            index_Bridge = length(Bridge_Set) + 1;
            index_TrafficLight = length(TrafficLight_Set) + 1;
            index_RoadNode = length(RoadNode_Set) + 1;
            index_Neighborhood = length(Neighborhood_Set) + 1;
            index_task = 1;
            
            
            % PowerPlant
            if strcmp('PowerPlants', name)
                for i = 2:length(raw)
                    try
                        if ~isKey(pow_check, raw(i,1)) && ~isempty(txt(i,1))
                            keySet = char(txt(i,1));
                            valueSet = 1;
                            newMap = containers.Map(keySet,valueSet);
                            pow_check = [pow_check; newMap];
                            
                            try
                                if ~isnan(num(i - 1,1))
                                    cap = num(i - 1,1);
                                else
                                    message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 2');
                                    error(message);
                                end
                            catch exception
                                msg = getReport(exception, 'basic');
                                disp(msg);
                                return;
                            end
                            
                            try
                                if ~isempty(txt(i,3))
                                    type = char(txt(i,3));
                                else
                                    message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 3');
                                    error(message);
                                end
                            catch exception
                                msg = getReport(exception, 'basic');
                                disp(msg);
                                return;
                            end
                            
                            try
                                if ~isnan(num(i - 1,4))
                                    startlocation = num(i - 1,4);
                                else
                                    message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 3');
                                    error(message);
                                end
                            catch exception
                                msg = getReport(exception, 'basic');
                                disp(msg);
                                return;
                            end
                            
                            try
                                if ~isnan(num(i - 1,3))
                                    endlocation = num(i - 1,3);
                                else
                                    message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                                    error(message);
                                end
                            catch exception
                                msg = getReport(exception, 'basic');
                                disp(msg);
                                return;
                            end
                            
                            disp(index_Generator);
                            Generator_Set{index_Generator} = Generator(index_Generator, [startlocation, endlocation]);
                            Bus_Set{index_Bus} = Bus(index_Bus, cap, type, keySet, [startlocation, endlocation], Generator_Set{index_Generator}.uniqueID);
                            Generator_Set{index_Generator}.Bus = Bus_Set{index_Bus}.uniqueID;
                            
                            Dictionary(Bus_Set{index_Bus}.uniqueID) = Bus_Set(index_Bus);
                            Dictionary(Generator_Set{index_Generator}.uniqueID) = Generator_Set(index_Generator);
                            
                            
                            index_Bus = index_Bus + 1;
                            index_Generator = index_Generator + 1;
                        else
                            message = strcat('ERROR: Empty Name or Name already exist in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                            error(message);
                        end
                    catch exception
                        msg = getReport(exception, 'basic');
                        disp(msg);
                        return;
                    end
                end
            end
            
            % Bus
            if strcmp('Substations', name)
                for i = 2:length(raw)
                    try
                        if ~isKey(pow_check, raw(i,1)) && ~isempty(txt(i,1))
                            keySet = char(txt(i,1));
                            valueSet = 1;
                            newMap = containers.Map(keySet,valueSet);
                            pow_check = [pow_check; newMap];
                            
                            try
                                if ~isnan(num(i - 1,1))
                                    cap = num(i - 1,1);
                                else
                                    message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 2');
                                    error(message);
                                end
                            catch exception
                                msg = getReport(exception, 'basic');
                                disp(msg);
                                return;
                            end
                            
                            try
                                if ~isempty(txt(i,3))
                                    type = char(txt(i,3));
                                else
                                    message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 3');
                                    error(message);
                                end
                            catch exception
                                msg = getReport(exception, 'basic');
                                disp(msg);
                                return;
                            end
                            
                            try
                                if ~isnan(num(i - 1,4))
                                    startlocation = num(i - 1,4);
                                else
                                    message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                                    error(message);
                                end
                            catch exception
                                msg = getReport(exception, 'basic');
                                disp(msg);
                                return;
                            end
                            
                            try
                                if ~isnan(num(i - 1,3))
                                    endlocation = num(i - 1,3);
                                else
                                    message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 5');
                                    error(message);
                                end
                            catch exception
                                msg = getReport(exception, 'basic');
                                disp(msg);
                                return;
                            end
                            
                            Bus_Set{index_Bus} = Bus(index_Bus, cap, type, keySet, [startlocation, endlocation]);
                            
                            Dictionary( Bus_Set{index_Bus}.uniqueID) =  Bus_Set(index_Bus);
                            index_Bus = index_Bus + 1;
                        else
                            message = strcat('ERROR: Empty Name or Name already exist in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                            error(message);
                        end
                    catch exception
                        msg = getReport(exception, 'basic');
                        disp(msg);
                        return;
                    end
                end
            end
            
            % Branch
            if strcmp('Power_Systems_Connectivity', name)
                for i = 2:length(raw)
                    try
                        if ~isempty(txt(i,1)) && ~isempty(txt(i,2)) && ~isnan(num(i - 1,1)) && ~isempty(txt(i,4))
                            name1 = char(txt(i,1));
                            name2 = char(txt(i,2));
                            cap = num(i - 1,1);
                            type = char(txt(i, 4));
                            index1 = 0;
                            index2 = 0;
                            
                            for j = 1:length(Bus_Set)
                                if strcmp(Bus_Set{j}.Name, name1)
                                    index1 = j;
                                end
                                
                                if strcmp(Bus_Set{j}.Name, name2)
                                    index2 = j;
                                end
                            end
                            
                            try
                                start_location = Bus_Set{index1}.Location;
                                end_location = Bus_Set{index2}.Location;
                                
                                if strcmp(Bus_Set{index1}.Type, 'Gas') || strcmp(Bus_Set{index1}.Type, 'Nuclear') || strcmp(Bus_Set{index1}.Type, 'Coal') || strcmp(Bus_Set{index2}.Type, 'Gas') || strcmp(Bus_Set{index2}.Type, 'Nuclear') || strcmp(Bus_Set{index2}.Type, 'Coal')
                                    proprity = 1;
                                else
                                    proprity = 2;
                                end
                                
                                Branch_Set{index_Branch} = Branch(index_Branch, start_location, end_location, cap, type, proprity, Bus_Set{index1}.uniqueID,  Bus_Set{index2}.uniqueID);
                                %Bus_Set{index1}.Branch = [Bus_Set{index1}.Branch, index_Branch];
                                %Bus_Set{index2}.Branch = [Bus_Set{index2}.Branch, index_Branch];
                                
                                
                                %Dictionary(Branch_Set{index_Branch}.uniqueID) = Branch_Set(index_Branch);
                                index_Branch = index_Branch + 1;
                            catch exception
                                C = {'Missing data!!', name1, 'or', name2, 'does not exist!'};
                                str = strjoin(C);
                                error(str);
                            end
                        else
                            message = strcat('ERROR: Empty Name or Name already exist in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                            error(message);
                        end
                    catch exception
                        msg = getReport(exception, 'basic');
                        disp(msg);
                        return;
                    end
                end
            end
            
            
            % Central Office
            if strcmp('CentralOffices', name)
                for i = 1:height(table)
                    try
                        if  ~isempty(table(i,1)) && ~isempty(table(i,2)) && ~isempty(table(i,3)) && ~isempty(table(i,4)) && ~isKey(centraloffice_check, cell2mat(table2cell(table(i,3))))
                            keySet = cell2mat(table2cell(table(i,3)));
                            valueSet = 1;
                            newMap = containers.Map(keySet,valueSet);
                            centraloffice_check = [centraloffice_check; newMap];
                            
                            Centraloffice_Set{index_Centraloffice} = Centraloffice(index_Centraloffice, [cell2mat(table2cell(table(i,1))), cell2mat(table2cell(table(i,2)))]);
                            Centraloffice_Set{index_Centraloffice}.Company = cell2mat(table2cell(table(i,4)));
                            Centraloffice_Set{index_Centraloffice}.Code = cell2mat(table2cell(table(i,3)));
                            Dictionary(Centraloffice_Set{index_Centraloffice}.uniqueID) = Centraloffice_Set(index_Centraloffice);
                            index_Centraloffice = index_Centraloffice + 1;
                            
                        else
                            message = strcat('ERROR: Empty Value or Value already exist in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                            error(message);
                        end
                    catch exception
                        msg = getReport(exception, 'basic');
                        disp(msg);
                        return;
                    end
                end
            end
            
            % Communication Tower
            if strcmp('CommunicationTowers', name)
                for i = 1:height(table)
                    try
                        if  ~isempty(table(i,1)) && ~isempty(table(i,2)) && ~isempty(table(i,3)) && ~isempty(table(i,4)) && ~isempty(table(i,6)) && ~isempty(table(i,9)) && ~isempty(table(i,12)) && ~isempty(table(i,15)) && ~isempty(table(i,16)) &&~isempty(table(i,17)) && ~isempty(table(i,18)) && ~isKey(communicationtower_check, cell2mat(table2cell(table(i,1))))
                            keySet = cell2mat(table2cell(table(i,1)));
                            valueSet = 1;
                            newMap = containers.Map(keySet,valueSet);
                            communicationtower_check = [communicationtower_check; newMap];
                            
                            CommunicationTower_Set{index_Communicationtower} = CommunicationTower(index_Communicationtower, [cell2mat(table2cell(table(i,16))), cell2mat(table2cell(table(i,17)))]);
                            CommunicationTower_Set{index_Communicationtower}.CommunicationTowerID = cell2mat(table2cell(table(i,1)));
                            CommunicationTower_Set{index_Communicationtower}.Tract = sprintf('%d',cell2mat(table2cell(table(1,3))));
                            CommunicationTower_Set{index_Communicationtower}.Comment = cell2mat(table2cell(table(i,18)));
                            CommunicationTower_Set{index_Communicationtower}.BackupPower = cell2mat(table2cell(table(i,15)));
                            CommunicationTower_Set{index_Communicationtower}.Usage = cell2mat(table2cell(table(i,12)));
                            CommunicationTower_Set{index_Communicationtower}.Owner = cell2mat(table2cell(table(i,9)));
                            CommunicationTower_Set{index_Communicationtower}.City = cell2mat(table2cell(table(i,6)));
                            CommunicationTower_Set{index_Communicationtower}.Name = cell2mat(table2cell(table(i,4)));
                            CommunicationTower_Set{index_Communicationtower}.UtilFcltyClass = cell2mat(table2cell(table(i,2)));
                            Dictionary(CommunicationTower_Set{index_Communicationtower}.uniqueID) = CommunicationTower_Set(index_Communicationtower);
                            index_Communicationtower = index_Communicationtower + 1;
                        else
                            message = strcat('ERROR: Empty Value or Value already exist in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                            error(message);
                        end
                    catch exception
                        msg = getReport(exception, 'basic');
                        disp(msg);
                        return;
                    end
                end
            end
            
            % Bridge
            if strcmp('Bridges', name)
                for i = 2:length(txt)
                    try
                        if  ~isempty(raw(i,2)) && ~isempty(raw(i,3)) && ~isempty(raw(i,4)) && ~isempty(raw(i,11)) && ~isempty(raw(i,10)) && ~isempty(raw(i,13)) && ~isempty(raw(i,12))
                            keySet = char(txt(i,18));
                            valueSet = 1;
                            newMap = containers.Map(keySet,valueSet);
                            bridge_check = [bridge_check; newMap];
                            
                            Bridge_Set{index_Bridge} = Bridge(index_Bridge, [num(i-1,2), num(i-1,3)], char(txt(i,18)));

%                             Bridge_Set{index_Bridge}.BridgeID = char(txt(i,4));
%                             Bridge_Set{index_Bridge}.CensusTract = num(i-1,5);
                            Bridge_Set{index_Bridge}.Name = char(txt(i,7));
                            Bridge_Set{index_Bridge}.Owner = char(txt(i,58));
                            Bridge_Set{index_Bridge}.NoOfCarryLinkID=num(i-1,8);
                            Bridge_Set{index_Bridge}.CarryLinkID=[num(i-1,9:11)];
                            Bridge_Set{index_Bridge}.NoOfCrossLinkID=num(i-1,12);
                            Bridge_Set{index_Bridge}.CrossLinkID=[num(i-1,13:15)];                           
                            Bridge_Set{index_Bridge}.CTY_CODE=num(i-1,17);
                            Bridge_Set{index_Bridge}.FEATINT=char(txt(i-1,24));                            
                            if isnan(num(i-1,66))
%                                 error('Width Input Error');
                                  num(i-1,66)=0;
                            end
                            Bridge_Set{index_Bridge}.Width = num(i-1,66);
                            if isnan(num(i-1,33))
                                error('MainSpans Input Error');
                            end
                            Bridge_Set{index_Bridge}.MainSpans = num(i-1,33);
                            if isnan(num(i-1,34))
                                error('AppSpans Input Error');
                            end
                            Bridge_Set{index_Bridge}.AppSpans = num(i-1,34);
                            if isnan(num(i-1,36))
                                num(i-1,36)=0;
                            end
							Bridge_Set{index_Bridge}.MaxSpanLength= num(i-1,36);
							if isnan(num(i-1,127))
                                error('SkewAngle Input Error');
                            end
                            Bridge_Set{index_Bridge}.SkewAngle = num(i-1,127);
                            Bridge_Set{index_Bridge}.Year = num(i-1,29);
                            Bridge_Set{index_Bridge}.Traffic = num(i-1,148);
%                             Bridge_Set{index_Bridge}.Cost = num(i-1,17);
                            Dictionary(Bridge_Set{index_Bridge}.uniqueID) = Bridge_Set(index_Bridge);
                            
                            index_Bridge = index_Bridge + 1;
                        else
                            message = strcat('ERROR: Empty Value or Value already exist in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                            error(message);
                        end
                    catch exception
                        msg = getReport(exception, 'basic');
                        disp(msg);
                        return;
                    end
                end
            end

                       % Read Bridge with sub-components
            if startsWith(name,'subBridge')
                sub_id = strsplit(name,'_');
                sub_id = sub_id{2};
                bridge = Dictionary(sub_id);
                bridge = bridge{1};
                bridge.HasSub = 1;
                abutmentFoundation_index = 1;
                %Left abutment foundation
                if table{1,2} > 0
                    for i = 1:table{1,2}
                        bridge.AbutmentFoundSet = [bridge.AbutmentFoundSet,AbutmentFoundation(i, bridge.Location, 'left')];
                        Dictionary(bridge.AbutmentFoundSet(abutmentFoundation_index).uniqueID) = bridge.AbutmentFoundSet(abutmentFoundation_index);
                        abutmentFoundation_index = abutmentFoundation_index + 1;
                    end
                end
                %right abutment foundation
                if table{2,2} > 0
                    for i = 1:table{2,2}
                        bridge.AbutmentFoundSet = [bridge.AbutmentFoundSet,AbutmentFoundation(i, bridge.Location, 'right')];
                        Dictionary(bridge.AbutmentFoundSet(abutmentFoundation_index).uniqueID) = bridge.AbutmentFoundSet(abutmentFoundation_index);
                        abutmentFoundation_index = abutmentFoundation_index + 1;                        
                    end
                end      
                abutment_index = 1;
                %Left abutment
                if table{3,2} > 0
                    for i = 1:table{3,2}
                        bridge.AbutmentSet = [bridge.AbutmentSet,Abutment(i, bridge.Location, 'left')];
                        Dictionary(bridge.AbutmentSet(abutment_index).uniqueID) = bridge.AbutmentSet(abutment_index);
                        abutment_index = abutment_index + 1;  
                    end
                end               
                %right abutment
                if table{4,2} > 0
                    for i = 1:table{4,2}
                        bridge.AbutmentSet = [bridge.AbutmentSet,Abutment(i, bridge.Location, 'right')];
                        Dictionary(bridge.AbutmentSet(abutment_index).uniqueID) = bridge.AbutmentSet(abutment_index);
                        abutment_index = abutment_index + 1;  
                    end
                end  
                bearing_index = 1;
                %'Rocker bearing 
                if table{5,2} > 0
                    for i = 1:table{5,2}
                        bridge.BearingSet = [bridge.BearingSet,Bearing(i,bridge.Location,'Rocker')];
                        Dictionary(bridge.BearingSet(bearing_index).uniqueID) = bridge.BearingSet(bearing_index);
                        bearing_index = bearing_index + 1;
                    end
                end
                %'Fixed bearing'
                if table{6,2} > 0
                    for i = 1:table{6,2}
                        bridge.BearingSet = [bridge.BearingSet,Bearing(i,bridge.Location,'Fixed')];
                        Dictionary(bridge.BearingSet(bearing_index).uniqueID) = bridge.BearingSet(bearing_index);
                        bearing_index = bearing_index + 1;
                    end
                end     
                %deck
                deck_index = 1
                if table{7,2} > 0
                    for i = 1:table{7,2}
                       bridge.DeckSet = [bridge.DeckSet,Deck(i,bridge.Location)];
                       Dictionary(bridge.BearingSet(deck_index).uniqueID) = bridge.DeckSet(deck_index);
                       deck_index = deck_index + 1;                       
                    end
                end
                %approach slab
                slab_index = 1
                if table{8,2} > 0
                    for i = 1:table{8,2}
                        bridge.SlabSet = [bridge.SlabSet,ApproachSlab(i,bridge.Location,'NA')];
                        Dictionary(bridge.SlabSet(slab_index).uniqueID) = bridge.SlabSet(slab_index);
                        slab_index = slab_index + 1;
                    end
                end
                %column foundation
                columnFoundation_index = 1;
                if table{9,2} > 0
                    for i = 1:table{9,2}
                        %left
                        bridge.ColumnFoundSet = [bridge.ColumnFoundSet,ColumnFoundation(i,bridge.Location,'left')];
                        Dictionary(bridge.ColumnFoundSet(columnFoundation_index).uniqueID) = bridge.ColumnFoundSet(columnFoundation_index);
                        columnFoundation_index = columnFoundation_index + 1;
                        %right
                        bridge.ColumnFoundSet = [bridge.ColumnFoundSet,ColumnFoundation(i,bridge.Location,'right')];
                        Dictionary(bridge.ColumnFoundSet(columnFoundation_index).uniqueID) = bridge.ColumnFoundSet(columnFoundation_index);
                        columnFoundation_index = columnFoundation_index + 1;
                    end
                end
                %column 
                column_index = 1;
                if table{10,2} > 0
                    for i = 1:table{10,2}
                        bridge.ColumnSet = [bridge.ColumnSet,Column(i,bridge.Location,'left')];
                        Dictionary(bridge.ColumnSet(column_index).uniqueID) = bridge.ColumnSet(column_index);
                        column_index = column_index + 1;
                        bridge.ColumnSet = [bridge.ColumnSet,Column(i,bridge.Location,'right')];
                        Dictionary(bridge.ColumnSet(column_index).uniqueID) = bridge.ColumnSet(column_index);
                        column_index = column_index + 1;
                    end
                end 
                
            end 
            
            
            % TrafficLights
            if strcmp('TrafficLights', name)
                for i = 2:length(txt)
                    try
                        if  ~isempty(raw(i,2)) && ~isempty(raw(i,3)) && ~isempty(raw(i,4))
                            keySet = char(txt(i,9));
                            valueSet = 1;
                            newMap = containers.Map(keySet,valueSet);
                            trafficlight_check = [trafficlight_check; newMap];
                            
                            TrafficLight_Set{index_TrafficLight} = TrafficLight(index_TrafficLight, [num(i-1,7), num(i-1,8)]);
                            TrafficLight_Set{index_TrafficLight}.MapKey = char(txt(i,9));
                            TrafficLight_Set{index_TrafficLight}.MajorStreet = char(txt(i,14));
                            TrafficLight_Set{index_TrafficLight}.MinorStreet = char(txt(i,16));
                            Dictionary(TrafficLight_Set{index_TrafficLight}.uniqueID) = TrafficLight_Set(index_TrafficLight);
                            
                            index_TrafficLight = index_TrafficLight + 1;
                        else
                            message = strcat('ERROR: Empty Value or Value already exist in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                            error(message);
                        end
                    catch exception
                        msg = getReport(exception, 'basic');
                        disp(msg);
                        return;
                    end
                end
            end
            
            % Road
            if strcmp('RoadLink', name)
                for i = 2:length(raw)
                    try
                        if  ~isempty(raw(i,1))                     
                            keySet = char(txt(i,1));
                            valueSet = 1;
                            newMap = containers.Map(keySet,valueSet);
                            road_check = [road_check; newMap];
                            
                            Road_Set{index_Road} = Road(index_Road,txt(i,2), num(i-1,4), txt(i,3), num(i-1,5));                      
                            Road_Set{index_Road}.AADT = num(i-1,6);                
                            Road_Set{index_Road}.numLanes = num(i-1,7);
                            Road_Set{index_Road}.Length = num(i-1,8);
                            Road_Set{index_Road}.Speedlimit = num(i-1,9);
                            Dictionary(Road_Set{index_Road}.uniqueID) = Road_Set(index_Road);
                            
                            load newroadlinks.mat
                            Road_Set{index_Road}.Bridge_Carr  = bridgeIDcarry{i-1}';
                            Road_Set{index_Road}.Bridge_Cross = bridgeIDcross{i-1}';
                            Road_Set{index_Road}.TrafficLight = trafficlightID{i-1}';

                            index_Road = index_Road + 1;
                        else
                            message = strcat('ERROR: Empty Value or Value already exist in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                            error(message);
                        end
                    catch exception
                        msg = getReport(exception, 'basic');
                        disp(msg);
                        return;
                    end
                end
            end
            
            % Road Node
            if strcmp('RoadNode', name)
                for i = 1:length(num)
                    try
                        if  ~isempty(num(i,1))
                            try
                                if ~isempty(num(i,1))
                                    nodeID = num(num(i,1));
                                else
                                    message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 3');
                                    error(message);
                                end
                            catch exception
                                msg = getReport(exception, 'basic');
                                disp(msg);
                                return;
                            end
                            try
                                if ~isnan(num(i,2))
                                    latitude = num(i,2);
                                else
                                    message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 3');
                                    error(message);
                                end
                            catch exception
                                msg = getReport(exception, 'basic');
                                disp(msg);
                                return;
                            end
                            
                            try
                                if ~isnan(num(i,3))
                                    longtitude = num(i,3);
                                else
                                    message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                                    error(message);
                                end
                            catch exception
                                msg = getReport(exception, 'basic');
                                disp(msg);
                                return;
                            end
                            
                            RoadNode_Set{index_RoadNode} = RoadNode(nodeID, [latitude, longtitude], nodeID);
                            Dictionary(RoadNode_Set{index_RoadNode}.uniqueID) = RoadNode_Set(index_RoadNode);
                            
                            index_RoadNode = index_RoadNode + 1;
                        else
                            message = strcat('ERROR: Empty Name or Name already exist in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                            error(message);
                        end
                    catch exception
                        msg = getReport(exception, 'basic');
                        disp(msg);
                        return;
                    end
                end
            end
            
            % Neightborhood
            if strcmp('Neighborhood', name)
                for i = 1:height(table)
                    try
                        if  ~isempty(table(i,1)) && ~isempty(table(i,2)) && ~isempty(table(i,3)) && ~isempty(table(i,4))
                            Neighborhood_Set{index_Neighborhood} = Neighborhood(index_Neighborhood, [cell2mat(table2cell(table(i,4))), cell2mat(table2cell(table(i,5)))], cell2mat(table2cell(table(i,2))), cell2mat(table2cell(table(i,3))), cell2mat(table2cell(table(i,6))), cell2mat(table2cell(table(i,8))), cell2mat(table2cell(table(i,14))), cell2mat(table2cell(table(i,15))));
                            Dictionary(Neighborhood_Set{index_Neighborhood}.uniqueID) = Neighborhood_Set(index_Neighborhood);
                            index_Neighborhood = index_Neighborhood + 1;
                        else
                            message = strcat('ERROR: Empty Value or Value already exist in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                            error(message);
                        end
                    catch exception
                        msg = getReport(exception, 'basic');
                        disp(msg);
                        return;
                    end
                end
            end
            
            
            
            power = {Branch_Set, Bus_Set, Generator_Set,{},{}};
            comm = {{}, Centraloffice_Set, Router_Set, Cellline_Set, CommunicationTower_Set,{}};
            trans = {Road_Set, Bridge_Set, TrafficLight_Set, RoadNode_Set,{}};
            
        end
        
        % Create and generate transmissionTower based on substation and
        % branch data
        function Power = createTransmissionTower(Power, Dictionary)
            Branch_Set= Power{1};
            Bus_Set = Power{2};
            TransmissionTower_Set = Power{4};
            NewBranch_Set = {};
            
            TransmissionTower_index = 1;
            NewBranch_index = 1;
            
            
            for i = 1:length(Branch_Set)
                temp = Branch_Set{i};
                cap = temp.Capacity;
                type = temp.Type;
                proprity = temp.Priority;
                obj1 = temp.connectedObj1;
                obj2 = temp.connectedObj2;
                end_location = temp.End_Location;
                start_location = temp.Start_Location;
                [dis,az] = distance(temp.Start_Location(1), temp.Start_Location(2), temp.End_Location(1),temp.End_Location(2),referenceSphere('earth','km'));
                num = dis/3;
                %disp(num);
                if num > 1
                    for j = 1:floor(num)
                        endTemp = [76, 40];
                        TransmissionTower_Set{TransmissionTower_index} = TransmissionTower(TransmissionTower_index,endTemp);
                        Dictionary(TransmissionTower_Set{TransmissionTower_index}.uniqueID) = TransmissionTower_Set(TransmissionTower_index);
                        if j == 1
                            NewBranch_Set{NewBranch_index} = Branch(NewBranch_index, start_location, endTemp, cap, type, proprity, obj1,  TransmissionTower_Set{TransmissionTower_index}.uniqueID);
                            busTemp = Dictionary(obj1);
                            busTemp{1}.Branch = [busTemp{1}.Branch, NewBranch_index];
                        else
                            NewBranch_Set{NewBranch_index} = Branch(NewBranch_index, TransmissionTower_Set{TransmissionTower_index - 1}.Location, endTemp, cap, type, proprity, TransmissionTower_Set{TransmissionTower_index - 1}.uniqueID,  TransmissionTower_Set{TransmissionTower_index}.uniqueID);
                            TransmissionTower_Set{TransmissionTower_index - 1}.Branch = [TransmissionTower_Set{TransmissionTower_index - 1}.Branch,NewBranch_index];
                        end
                        Dictionary(NewBranch_Set{NewBranch_index}.uniqueID) = NewBranch_Set(NewBranch_index);
                        TransmissionTower_Set{TransmissionTower_index}.Branch = [TransmissionTower_Set{TransmissionTower_index}.Branch,NewBranch_index];
                        NewBranch_index = NewBranch_index + 1;
                        TransmissionTower_index = TransmissionTower_index + 1;
                        if j == floor(num)
                            NewBranch_Set{NewBranch_index} = Branch(NewBranch_index, TransmissionTower_Set{TransmissionTower_index - 1}.Location, end_location, cap, type, proprity, TransmissionTower_Set{TransmissionTower_index - 1}.uniqueID,  obj2);
                            Dictionary(NewBranch_Set{NewBranch_index}.uniqueID) = NewBranch_Set(NewBranch_index);
                            NewBranch_index = NewBranch_index + 1;
                            busTemp = Dictionary(obj2);
                            busTemp{1}.Branch = [busTemp{1}.Branch, NewBranch_index];
                        end
                    end
                else
                    NewBranch_Set{NewBranch_index} = Branch_Set{i};
                    busTemp = Dictionary(obj1);
                    busTemp{1}.Branch = [busTemp{1}.Branch, NewBranch_index];
                    busTemp = Dictionary(obj2);
                    busTemp{1}.Branch = [busTemp{1}.Branch, NewBranch_index];
                    NewBranch_index = NewBranch_index + 1;
                end
            end
            Power{1} = NewBranch_Set;
            Power{4} = TransmissionTower_Set;
        end
        
        %% Helper
        % count damaged
        function number = countDamaged(Set)
            number = 0;
            for i = 1:length(Set)
                if strcmp(Set{i}.Status,'Damaged')
                    number = number + 1;
                end
            end
        end
        
        % Get repairation time
        function time = getRepairationTime(num, Object, Power_Set, Communication_Set, Transportation_Set)
            Branch= Power_Set{1};
            Bus= Power_Set{2};
            Generator= Power_Set{3};
            
            Centraloffice = Communication_Set{2};
            Router = Communication_Set{3};
            Cellline = Communication_Set{4};
            CommunicationTower = Communication_Set{5};
            
            Road = Transportation_Set{1};
            Bridge = Transportation_Set{2};
            TrafficLight = Transportation_Set{3};
            
            tem = strsplit(Object,'/');
            name = tem{1};
            number = str2num(tem{2});
            
            
            if strcmp(name, 'Branch')
                if num == 1
                    time = Branch{number}.Recovery(1);
                elseif num == 2
                    time = Branch{number}.WorkingDays;
                end
            end
            
            if strcmp(name, 'Bus')
                if num == 1
                    time = Bus{number}.Recovery(1);
                elseif num == 2
                    time = Bus{number}.WorkingDays;
                end
            end
            
            if strcmp(name, 'Generator')
                if num == 1
                    time = Generator{number}.Recovery(1);
                elseif num == 2
                    time = Generator{number}.WorkingDays;
                end
            end
            
            
            if strcmp(name, 'Centraloffice')
                if num == 1
                    time = Centraloffice{number}.Recovery(1);
                elseif num == 2
                    time = Centraloffice{number}.WorkingDays;
                end
            end
            
            if strcmp(name, 'Router')
                if num == 1
                    time = Router{number}.Recovery(1);
                elseif num == 2
                    time = Router{number}.WorkingDays;
                end
            end
            
            if strcmp(name, 'Cellline')
                if num == 1
                    time = Cellline{number}.Recovery(1);
                elseif num == 2
                    time = Cellline{number}.WorkingDays;
                end
            end
            
            if strcmp(name, 'CommunicationTower')
                if num == 1
                    time = CommunicationTower{number}.Recovery(1);
                elseif num == 2
                    time = CommunicationTower{number}.WorkingDays;
                end
            end
            
            if strcmp(name, 'Road')
                if num == 1
                    time = Road{number}.Recovery(1);
                elseif num == 2
                    time = Road{number}.WorkingDays;
                end
            end
            
            if strcmp(name, 'Bridge')
                if num == 1
                    time = Bridge{number}.Recovery(1);
                elseif num == 2
                    time = Bridge{number}.WorkingDays;
                end
            end
            
            if strcmp(name, 'TrafficLight')
                if num == 1
                    time = TrafficLight{number}.Recovery(1);
                elseif num == 2
                    time = TrafficLight{number}.WorkingDays;
                end
            end
        end
        
        function result = getDependency(Object, Dictionary)
            result = 0;
            if Library.getUniqueId(Object,0) ~= -99
                tem = Dictionary(Library.getUniqueId(Object));
                if iscell(tem)
                    temp = tem{1}.predecessorComponent;
                else
                    temp = tem.predecessorComponent;
                end
                for i = 1:length(temp)
                    tem = Dictionary(temp(i));
                    tem = tem{1};
                    if tem.WorkingDays > 0
                        result = 1;
                        return;
                    end
                end
            else
                result = 1;
            end
        end
        
        % Get Resource usage of object by name and index
        function result = getResource(Object, Dictionary, resourceIndex, flag)
            if flag
                temp = Dictionary(Library.getUniqueId(Object, 1));
            else
                temp = Dictionary(Library.getUniqueId(Object, 0));
                
            end
            if iscell(temp)
                result = temp{1}.Resources(resourceIndex);
            else
                result = temp.Resources(resourceIndex);
                result = result{1};
            end
        end
        
        % Get UniqueId from schedule
        function uniqueId = getUniqueId(Object, flag)
            tem = strsplit(Object,'/');
            if length(tem) == 2
                uniqueId = strcat(tem{1}, tem{2});
            elseif length(tem) == 3
                uniqueId = tem{3};
            elseif length(tem) == 4 && flag
                uniqueId = strcat(tem{1}, tem{2});
            elseif length(tem) == 5 && flag
                uniqueId = tem{3};
            else
                uniqueId = -99;
            end
            return;
        end
        
        % Groubi optimize function
        function [x, fval, exitflag] = intlinprog(f, intcon, A, b, Aeq, beq, lb, ub)
            %INTLINPROG A mixed integer linear programming example using the
            %   Gurobi MATLAB interface
            %
            %   This example is based on the intlinprog interface defined in the
            %   MATLAB Optimization Toolbox. The Optimization Toolbox
            %   is a registered trademark of The MathWorks, Inc.
            %
            %   x = INTLINPROG(f,intcon,A,b) solves the problem:
            %
            %   minimize     f'*x
            %   subject to   A*x <= b
            %                x(j) integer, when j is in the vector
            %                intcon of integer constraints
            %
            %   x = INTLINPROG(f,intcon,A,b,Aeq,beq) solves the problem:
            %
            %   minimize     f'*x
            %   subject to     A*x <= b,
            %                Aeq*x == beq
            %                x(j) integer, where j is in the vector
            %                intcon of integer constraints
            %
            %   x = INTLINPROG(f,intcon,A,b,Aeq,beq,lb,ub) solves the problem:
            %
            %   minimize     f'*x
            %   subject to     A*x <= b,
            %                Aeq*x == beq,
            %          lb <=     x <= ub.
            %                x(j) integer, where j is in the vector
            %                intcon of integer constraints
            %
            %   You can set lb(j) = -inf, if x(j) has no lower bound,
            %   and ub(j) = inf, if x(j) has no upper bound.
            %
            %   [x, fval] = INTLINPROG(f, intcon, A, b) returns the objective value
            %   at the solution. That is, fval = f'*x.
            %
            %   [x, fval, exitflag] = INTLINPROG(f, intcon, A, b) returns an exitflag
            %   containing the status of the optimization. The values for
            %   exitflag and corresponding status codes are:
            %    2 - Solver stopped prematurely. Integer feasible point found.
            %    1 - Optimal solution found.
            %    0 - Solver stopped prematurely. No integer feasible point found.
            %   -2 - No feasible point found.
            %   -3 - Problem is unbounded.
            
            if nargin < 4
                error('intlinprog(f, intcon, A, b)')
            end
            
            if nargin > 8
                error('intlinprog(f, intcon, A, b, Aeq, beq, lb, ub)');
            end
            
            if ~isempty(A)
                n = size(A, 2);
            elseif nargin > 5 && ~isempty(Aeq)
                n = size(Aeq, 2);
            else
                error('No linear constraints specified')
            end
            
            if ~issparse(A)
                A = sparse(A);
            end
            
            if nargin > 4 && ~issparse(Aeq)
                Aeq = sparse(Aeq);
            end
            
            model.obj = f;
            model.vtype = repmat('C', n, 1);
            model.vtype(intcon) = 'I';
            
            if nargin < 5
                model.A = A;
                model.rhs = b;
                model.sense = '<';
            else
                model.A = [A; Aeq];
                model.rhs = [b; beq];
                model.sense = [repmat('<', size(A,1), 1); repmat('=', size(Aeq,1), 1)];
            end
            
            if nargin < 7
                model.lb = -inf(n,1);
            else
                model.lb = lb;
            end
            
            if nargin == 8
                model.ub = ub;
            end
            
            params.outputflag = 0;
            params.timelimit = 100;
            
            result = gurobi(model, params);
            
            
            if strcmp(result.status, 'OPTIMAL')
                exitflag = 1;
            elseif strcmp(result.status, 'INTERRUPTED')
                if isfield(result, 'x')
                    exitflag = 2;
                else
                    exitflag = 0;
                end
            elseif strcmp(result.status, 'INF_OR_UNBD')
                params.dualreductions = 0;
                result = gurobi(model, params);
                if strcmp(result.status, 'INFEASIBLE')
                    exitflag = -2;
                elseif strcmp(result.status, 'UNBOUNDED')
                    exitflag = -3;
                else
                    exitflag = nan;
                end
            else
                exitflag = nan;
            end
            
            
            if isfield(result, 'x')
                x = result.x;
            else
                x = nan(n,1);
            end
            
            if isfield(result, 'objval')
                fval = result.objval;
            else
                fval = nan;
            end
        end
        
        % Create Hash map for task types
        function M = createHash(matFile)
            temp = load(matFile);
            num = temp.num;
            keySet = [];
            valueSet = [];
            for i = 1: height(num)
                keySet(i) = num{i,1};
                temp = {num{i,2},num{i,3},num{i,4},num{i,5},num{i,6},num{i,7},num{i,8},num{i,9},num{i,10},num{i,11}};
                valueSet{i} = temp;
            end
            M = containers.Map(keySet,valueSet);
        end
        
        % Create Hash map for task types
        function M = hashTaskDmageLevel(matFile)
            temp = load(matFile);
            a = temp.a;
            keySet = [];
            valueSet = [];
            for i = 1:length(a)
                keySet(i) = i;
                temp = {};
                for j = 1:length(a{i})
                    for k = 1:length(a{i}{j})
                        temp{j}{k} = a{i}{j}{k};
                    end
                end
                valueSet{i} = temp;
            end
            M = containers.Map(keySet,valueSet);
        end
        
        function assignFragility(Power_Set,  Transportation_Set, Communication_Set)
            Branch= Power_Set{1};
            Bus= Power_Set{2};
            Generator= Power_Set{3};
            TransmissionTower = Power_Set{4};
            
            Centraloffice = Communication_Set{2};
            Router = Communication_Set{3};
            Cellline = Communication_Set{4};
            CommunicationTower = Communication_Set{5};
            
            Road = Transportation_Set{1};
            Bridge = Transportation_Set{2};
            TrafficLight = Transportation_Set{3};
            
            load('fragility_Branch.mat');
            load('fragility_Bridge.mat');
            load('fragility_Bus.mat');
            load('fragility_CellLine.mat');
            load('fragility_CentralOffice.mat');
            load('fragility_CommunicationTower.mat');
            load('fragility_Generator.mat');
            load('fragility_PowerPlant.mat');
            load('fragility_Road.mat');
            load('fragility_Router.mat');
            load('fragility_Substation.mat');
            load('fragility_TrafficLight.mat');
            load('fragility_TransmissionTower.mat');
            
            for i = 1:length(TransmissionTower)
                Library.singleFrag(TransmissionTower{i}, fragility_TransmissionTower);
            end
            for i = 1:length(TrafficLight)
                Library.singleFrag(TrafficLight{i}, fragility_TrafficLight);
            end
            for i = 1:length(Router)
                Library.singleFrag(Router{i}, fragility_Router);
            end
            for i = 1:length(Generator)
                Library.singleFrag(Generator{i}, fragility_Generator);
            end
            for i = 1:length(CommunicationTower)
                Library.singleFrag(CommunicationTower{i}, fragility_CommunicationTower);
            end
            for i = 1:length(Cellline)
                Library.singleFrag(Cellline{i}, fragility_CellLine);
            end
            for i = 1:length(Bus)
                Library.singleFrag(Bus{i}, fragility_Bus);
            end
            for i = 1:length(Branch)
                %                 Library.branchFrag(Branch{i}, fragility_Branch);
                Library.singleFrag(Branch{i}, fragility_Branch);
            end
            for i = 1:length(Centraloffice)
                %                 Library.centralFrag(Centraloffice{i}, fragility_Centraloffice);
                Library.singleFrag(Centraloffice{i}, fragility_CentralOffice);
            end
            for i = 1:length(Road)
                %                 Library.roadFrag(Road{i}, fragility_Road);
                Library.singleFrag(Road{i}, fragility_Road);
            end
            for i = 1:length(Bridge)
                %                 Library.bridgeFrag(Bridge{i}, fragility_Bridge);
                Library.singleFrag(Bridge{i}, fragility_Bridge);
                
                if Bridge{i}.HasSub == 1
                    for j = 1:length(Bridge{i}.ColumnSet)
                        Library.singleFrag(Bridge{i}.ColumnSet(j), fragility_Bridge);
                    end
                    for j = 1:length(Bridge{i}.ColumnFoundSet)
                        Library.singleFrag(Bridge{i}.ColumnFoundSet(j), fragility_Bridge);
                    end
                    for j = 1:length(Bridge{i}.AbutmentSet)
                        Library.singleFrag(Bridge{i}.AbutmentSet(j), fragility_Bridge);
                    end
                    for j = 1:length(Bridge{i}.AbutmentFoundSet)
                        Library.singleFrag(Bridge{i}.AbutmentFoundSet(j), fragility_Bridge);
                    end
                    for j = 1:length(Bridge{i}.GirderSet)
                        Library.singleFrag(Bridge{i}.GirderSet(j), fragility_Bridge);
                    end
                    for j = 1:length(Bridge{i}.BearingSet)
                        Library.singleFrag(Bridge{i}.BearingSet(j), fragility_Bridge);
                    end
                    for j = 1:length(Bridge{i}.DeckSet)
                        Library.singleFrag(Bridge{i}.DeckSet(j), fragility_Bridge);
                    end
                    for j = 1:length(Bridge{i}.SlabSet)
                        Library.singleFrag(Bridge{i}.SlabSet(j), fragility_Bridge);
                    end
                end                
                
                
                
            end
        end
        
        %Assing one fragility model for all types
        function singleFrag(Object, fragVector)
            for j = 1:8
                rol = idivide(j+1, int32(2), 'floor');
                col = rem(j,2);
                if col == 0
                    col = 2;
                end
                Object.Fragility(rol,col) = fragVector(j);
            end
        end
        
        %Specific assignments by type
        function branchFrag(Object, fragVector)
            for j = 1:8
                rol = idivide(j+1, int32(2), 'floor');
                col = rem(j,2);
                if col == 0
                    col = 2;
                end
                switch Object.type
                    case 'null'
                        Object.Fragility(rol,col) = fragVector(j);
                end
            end
        end
        
        %Assign Recovery Matrix for each object (Doesn't affect objects
        %other than generator after the implementation of task system)
        function assignRecovery (Power_Set,  Transportation_Set, Communication_Set)
            Branch= Power_Set{1};
            Bus= Power_Set{2};
            Generator= Power_Set{3};
            
            
            Centraloffice = Communication_Set{2};
            Router = Communication_Set{3};
            Cellline = Communication_Set{4};
            CommunicationTower = Communication_Set{5};
            
            Road = Transportation_Set{1};
            Bridge = Transportation_Set{2};
            TrafficLight = Transportation_Set{3};
            
            ros = load('restoration_Branch.mat');
            restoration_Branch = ros.restoration_Branch;
            ros = load('restoration_Bridge.mat');
            restoration_Bridge = ros.restoration_Bridge;
            ros = load('restoration_Bus.mat');
            restoration_Bus = ros.restoration_Bus;
            ros = load('restoration_CellLine.mat');
            restoration_CellLine = ros.restoration_CellLine;
            ros = load('restoration_CentralOffice.mat');
            restoration_CentralOffice = ros.restoration_CentralOffice;
            ros = load('restoration_CommunicationTower.mat');
            restoration_CommunicationTower = ros.restoration_CommunicationTower;
            ros = load('restoration_Generator.mat');
            restoration_Generator = ros.restoration_Generator;
            ros = load('restoration_PowerPlant.mat');
            restoration_PowerPlant = ros.restoration_PowerPlant;
            ros = load('restoration_Road.mat');
            restoration_Road = ros.restoration_Road;
            ros = load('restoration_Router.mat');
            restoration_Router = ros.restoration_Router;
            ros = load('restoration_Substation.mat');
            restoration_Substation = ros.restoration_Substation;
            ros = load('restoration_TrafficLight.mat');
            restoration_TrafficLight = ros.restoration_TrafficLight;
            ros = load('restoration_TransmissionTower.mat');
            restoration_TransmissionTower = ros.restoration_TransmissionTower;
            for i = 1:length(TrafficLight)
                Library.singleRec(TrafficLight{i}, restoration_TrafficLight);
            end
            for i = 1:length(Router)
                Library.singleRec(Router{i}, restoration_Router);
            end
            for i = 1:length(Generator)
                Library.singleRec(Generator{i}, restoration_Generator);
            end
            for i = 1:length(CommunicationTower)
                Library.singleRec(CommunicationTower{i}, restoration_CommunicationTower);
            end
            for i = 1:length(Cellline)
                Library.singleRec(Cellline{i}, restoration_CellLine);
            end
            for i = 1:length(Bus)
                Library.singleRec(Bus{i}, restoration_Bus);
            end
            for i = 1:length(Branch)
                %                 Library.branchFrag(Branch{i}, fragility_Branch);
                Library.singleRec(Branch{i}, restoration_Branch);
            end
            for i = 1:length(Centraloffice)
                %                 Library.centralFrag(Centraloffice{i}, fragility_Centraloffice);
                Library.singleRec(Centraloffice{i}, restoration_CentralOffice);
            end
            for i = 1:length(Road)
                %                 Library.roadFrag(Road{i}, fragility_Road);
                Library.singleRec(Road{i}, restoration_Road);
            end
            for i = 1:length(Bridge)
                %                 Library.bridgeFrag(Bridge{i}, fragility_Bridge);
                Library.singleRec(Bridge{i}, restoration_Bridge);
                
                if Bridge{i}.HasSub == 1
                    for j = 1:length(Bridge{i}.ColumnSet)
                        Library.singleRec(Bridge{i}.ColumnSet(j), restoration_Bridge);
                    end
                    for j = 1:length(Bridge{i}.ColumnFoundSet)
                        Library.singleRec(Bridge{i}.ColumnFoundSet(j), restoration_Bridge);
                    end
                    for j = 1:length(Bridge{i}.AbutmentSet)
                        Library.singleRec(Bridge{i}.AbutmentSet(j), restoration_Bridge);
                    end
                    for j = 1:length(Bridge{i}.AbutmentFoundSet)
                        Library.singleRec(Bridge{i}.AbutmentFoundSet(j), restoration_Bridge);
                    end
                    for j = 1:length(Bridge{i}.GirderSet)
                        Library.singleRec(Bridge{i}.GirderSet(j), restoration_Bridge);
                    end
                    for j = 1:length(Bridge{i}.BearingSet)
                        Library.singleRec(Bridge{i}.BearingSet(j), restoration_Bridge);
                    end
                    for j = 1:length(Bridge{i}.DeckSet)
                        Library.singleRec(Bridge{i}.DeckSet(j), restoration_Bridge);
                    end
                    for j = 1:length(Bridge{i}.SlabSet)
                        Library.singleRec(Bridge{i}.SlabSet(j), restoration_Bridge);
                    end
                end         
                
            end
        end
        
        % Helper function for recovery assignment, when there's only one
        % type for that object
        function singleRec(Object, recVector)
            for j = 1:8
                rol = idivide(j+1, int32(2), 'floor');
                col = rem(j,2);
                if col == 0
                    col = 2;
                end
                Object.RecoveryMatrix(rol,col) = recVector(j);
            end
        end
        
        % Assign power functional dependecy for each objects in communication system
        function [Transportation_Set, Communication_Set] = assignPowerToTransComm(Power_Set, Transportation_Set,Communication_Set, Dictionary)
            Bus= Power_Set{2};
            
            TrafficLight = Transportation_Set{3};
            
            Centraloffice = Communication_Set{2};
            Cellline = Communication_Set{4};
            CommunicationTower = Communication_Set{5};
            
            Bus_Location = [];
            
            for i = 1: length(Bus)
                Bus_Location = [Bus_Location; Bus{i}.Location];
            end
            
            for i = 1:length(TrafficLight)
                Idx = knnsearch(Bus_Location, TrafficLight{i}.Location,'K',1);
                TrafficLight{i}.Bus = Bus{Idx(1)}.uniqueID;
            end
            
            for i = 1:length(Centraloffice)
                Idx = knnsearch(Bus_Location, Centraloffice{i}.Location,'K',1);
                Centraloffice{i}.Bus = Bus{Idx(1)}.uniqueID;
            end
            
            for i = 1:length(Cellline)
                Idx = knnsearch(Bus_Location, Cellline{i}.Start_Location,'K',1);
                Cellline{i}.Bus = Bus{Idx(1)}.uniqueID;
            end
            
            for i = 1:length(CommunicationTower)
                Idx = knnsearch(Bus_Location, CommunicationTower{i}.Location,'K',1);
                CommunicationTower{i}.Bus = Bus{Idx(1)}.uniqueID;
            end
            
            Transportation_Set{3} = TrafficLight;
            
            Communication_Set{2} = Centraloffice;
            Communication_Set{2} = Centraloffice;
            Communication_Set{5} = CommunicationTower;
        end
        
        % Construct and link cellines between objects in communication
        % system
        function Communication_Set = assignCellLine ( Communication_Set, Dictionary)
            
            Centraloffice = Communication_Set{2};
            Cellline_Set = Communication_Set{4};
            CommunicationTower = Communication_Set{5};
            index_Cellline = 1;
            
            Central_location = [];
            
            for i = 1: length(Centraloffice)
                Central_location = [Central_location; Centraloffice{i}.Location];
            end
            
            
            %Connect Central office to Central Office
            for i = 1: length(Centraloffice)
                Idx = knnsearch(Central_location, Centraloffice{i}.Location,'K',20);
                for j = 2:20
                    if length(Centraloffice{i}.CentralOffice) > 2
                        break;
                    end
                    if length(Centraloffice{Idx(j)}.CentralOffice) > 2
                        continue;
                    end
                    Cellline_Set{index_Cellline} = Cellline(index_Cellline, Centraloffice{i}.Location, Centraloffice{Idx(j)}.Location, Centraloffice{i}.uniqueID, Centraloffice{Idx(j)}.uniqueID);
                    Dictionary(Cellline_Set{index_Cellline}.uniqueID) = Cellline_Set(index_Cellline);
                    
                    %record objects that got connected with
                    Centraloffice{i}.Cellline = [Centraloffice{i}.Cellline, Cellline_Set{index_Cellline}.uniqueID];
                    Centraloffice{Idx(j)}.Cellline = [Centraloffice{Idx(j)}.Cellline, Cellline_Set{index_Cellline}.uniqueID];
                    Centraloffice{i}.CentralOffice = [Centraloffice{i}.CentralOffice, Centraloffice{Idx(j)}.uniqueID];
                    Centraloffice{Idx(j)}.CentralOffice = [Centraloffice{Idx(j)}.CentralOffice, Centraloffice{i}.uniqueID];
                    
                    index_Cellline = index_Cellline + 1;
                end
            end
            
            for i = 1:length(CommunicationTower)
                Idx = knnsearch(Central_location, CommunicationTower{i}.Location,'K',2);
                for j = 1:2
                    Cellline_Set{index_Cellline} = Cellline(index_Cellline, CommunicationTower{i}.Location, Centraloffice{Idx(j)}.Location, CommunicationTower{i}.uniqueID, Centraloffice{Idx(j)}.uniqueID);
                    Dictionary(Cellline_Set{index_Cellline}.uniqueID) = Cellline_Set(index_Cellline);
                    
                    Centraloffice{Idx(j)}.Cellline = [Centraloffice{Idx(j)}.Cellline, Cellline_Set{index_Cellline}.uniqueID];
                    CommunicationTower{i}.Cellline = [CommunicationTower{i}.Cellline, Cellline_Set{index_Cellline}.uniqueID];
                    Centraloffice{Idx(j)}.CommTower = [Centraloffice{Idx(j)}.CommTower, CommunicationTower{i}.uniqueID];
                    CommunicationTower{i}.Centraloffice = [CommunicationTower{i}.Centraloffice, Centraloffice{Idx(j)}.uniqueID];
                    index_Cellline = index_Cellline + 1;
                end
            end
            
            
            Communication_Set{4} = Cellline_Set;
            
        end
        
        function SysFuncInterdependenceHelper(Set, Dictionary, System_Dependent_Factor)
            for i = 1:length(Set) - 1
                
                for j = 1:length(Set{i})
                    if strcmp(Set{i}{1}.Class,'RoadNode')
                        break;
                    end
                    if ~strcmp(Set{i}{1}.Status, 'Damaged')
                        continue;
                    end
                    tasks = Set{i}{j}.taskUniqueIds;
                    sum = 0;
                    for k = 1:length(tasks)
                        temp = Dictionary(tasks{k});
                        temp.WorkingDays = temp.WorkingDays * System_Dependent_Factor;
                        sum = sum + temp.WorkingDays;
                    end
                    Set{i}{j}.WorkingDays = sum;
                end
            end
        end
        
        % Modify the recovery time based on system functionality
        function SysFuncInterdependence(Power_Set, Communication_Set, Transportation_Set, System_Dependent_Factor, Dictionary)
            Library.SysFuncInterdependenceHelper(Power_Set, Dictionary, System_Dependent_Factor);
            Library.SysFuncInterdependenceHelper(Communication_Set, Dictionary, System_Dependent_Factor);
            Library.SysFuncInterdependenceHelper(Transportation_Set, Dictionary, System_Dependent_Factor);
        end
        
        % Create graph for transportation system based on road and
        % roadnodes
        function G = graphTheoryTrans(Trans_Set,Dictionary)
            hash = containers.Map('KeyType','double','ValueType','char');
            
            road_Set = Trans_Set{1};
            roadnode_Set = Trans_Set{4};
            Neighborhood = Trans_Set{5};
            for i = 1:length(roadnode_Set)
                hash(roadnode_Set{i}.nodeID) = roadnode_Set{i}.uniqueID;
            end
            s = [];
            t = [];
            weights = [];
            for i = 1:length(road_Set)
                s{i} = hash(road_Set{i}.Start_Node);
                t{i} = hash(road_Set{i}.End_Node);
                weights{i} = road_Set{i}.Length;
            end
            for i = 1:length(Neighborhood)
                s{i + length(road_Set)} = Neighborhood{i}.RoadNode;
                t{i+ length(road_Set)} = Neighborhood{i}.Neighborhood;
                temp1 = Dictionary(Neighborhood{i}.Neighborhood);
                temp2 = Dictionary(Neighborhood{i}.RoadNode);
                temp1 = temp1{1};
                temp2 = temp2{1};
                weights{i+ length(road_Set)} = distance(temp1.Location(1), temp1.Location(2), temp2.Location(1),temp2.Location(2),referenceSphere('earth','km'));
            end
            
            G = digraph(s,t,cell2mat(weights));
            
            
        end
        
        % Create graph for communication system based on cellines and
        % connected objects
        function G = graphTheoryComm(Comm_Set, Dictionary)
            Cellline = Comm_Set{4};
            Neighborhood = Comm_Set{6};
            s = [];
            t = [];
            weights = [];
            for i = 1:length(Cellline)
                s{i} = Cellline{i}.connectedObj1;
                t{i} = Cellline{i}.connectedObj2;
                temp1 = Dictionary(Cellline{i}.connectedObj1);
                temp2 = Dictionary(Cellline{i}.connectedObj2);
                temp1 = temp1{1};
                temp2 = temp2{1};
                weights{i} = distance(temp1.Location(1), temp1.Location(2), temp2.Location(1),temp2.Location(2),referenceSphere('earth','km'));
            end
            
            for i = 1:length(Neighborhood)
                s{i + length(Cellline)} = Neighborhood{i}.Neighborhood;
                t{i+ length(Cellline)} = Neighborhood{i}.CentralTower;
                temp1 = Dictionary(Neighborhood{i}.Neighborhood);
                temp2 = Dictionary(Neighborhood{i}.CentralTower);
                temp1 = temp1{1};
                temp2 = temp2{1};
                weights{i+ length(Cellline)} = distance(temp1.Location(1), temp1.Location(2), temp2.Location(1),temp2.Location(2),referenceSphere('earth','km'));
            end
            G = digraph(s,t,cell2mat(weights));
            
            
        end
        
        % Create graph for power system based on branches substations and
        % transTowers
        function G = graphTheoryPower(Power_Set,Dictionary)
            Branch = Power_Set{1};
            Neighborhood = Power_Set{5};
            s = [];
            t = [];
            weights = [];
            for i = 1:length(Branch)
                s{i} = Branch{i}.connectedObj1;
                t{i} = Branch{i}.connectedObj2;
                temp1 = Dictionary(Branch{i}.connectedObj1);
                temp2 = Dictionary(Branch{i}.connectedObj2);
                temp1 = temp1{1};
                temp2 = temp2{1};
                weights{i} = distance(temp1.Location(1), temp1.Location(2), temp2.Location(1),temp2.Location(2),referenceSphere('earth','km'));
            end
            
            for i = 1:length(Neighborhood)
                s{i + length(Branch)} = Neighborhood{i}.Neighborhood;
                t{i+ length(Branch)} = Neighborhood{i}.Bus;
                temp1 = Dictionary(Neighborhood{i}.Neighborhood);
                temp2 = Dictionary(Neighborhood{i}.Bus);
                temp1 = temp1{1};
                temp2 = temp2{1};
                weights{i+ length(Branch)} = distance(temp1.Location(1), temp1.Location(2), temp2.Location(1),temp2.Location(2),referenceSphere('earth','km'));
            end
            G = digraph(s,t,cell2mat(weights));
            
            %
        end
        
        % Link neighborhood with the nearest nodes for each system
        function [Transportation_Set, Communication_Set, Power_Set, Neighborhood_Set] = linkNeighborhood(Power_Set, Transportation_Set,Communication_Set, Dictionary, Neighborhood_Set)
            Centraloffice = Communication_Set{2};
            Bus= Power_Set{2};
            roadNode = Transportation_Set{4};
            
            PowerLink_Set = [];
            TransLink_Set = [];
            CommLink_Set = [];
            
            index_PowerLink = 1;
            index_TransLink = 1;
            index_CommLink = 1;
            
            Central_location = [];
            Bus_location = [];
            roadNode_location = [];
            
            for i = 1: length(Centraloffice)
                Central_location = [Central_location; Centraloffice{i}.Location];
            end
            
            for i = 1: length(Bus)
                Bus_location = [Bus_location; Bus{i}.Location];
            end
            
            for i = 1: length(roadNode)
                roadNode_location = [roadNode_location; roadNode{i}.Location];
            end
            
            for i = 1:length(Neighborhood_Set)
                Idx = knnsearch(Bus_location, Neighborhood_Set{i}.Location,'K',1);
                PowerLink_Set{index_PowerLink} = Neighborhood_Power_Link(index_PowerLink, Neighborhood_Set{i}.Location, Bus{Idx(1)}.Location, Neighborhood_Set{i}.uniqueID, Bus{Idx(1)}.uniqueID);
                Dictionary(PowerLink_Set{index_PowerLink}.uniqueID) = PowerLink_Set(index_PowerLink);
                
                Neighborhood_Set{i}.Bus = Bus{Idx(1)}.uniqueID;
                Neighborhood_Set{i}.Neighborhood_Power_Link = PowerLink_Set{index_PowerLink}.uniqueID;
                Bus{Idx(1)}.Neighborhood{end+1}  = Neighborhood_Set{i}.uniqueID;
                Bus{Idx(1)}.PopulationServed = Bus{Idx(1)}.PopulationServed + Neighborhood_Set{i}.Population;
                Bus{Idx(1)}.Neighborhood_Power_Link{end+1}  = PowerLink_Set{index_PowerLink}.uniqueID;
                
                index_PowerLink = index_PowerLink + 1;
            end
            
            for i = 1:length(Neighborhood_Set)
                Idx = knnsearch(Central_location, Neighborhood_Set{i}.Location,'K',1);
                CommLink_Set{index_CommLink} = Neighborhood_Comm_Link(index_CommLink, Neighborhood_Set{i}.Location, Centraloffice{Idx(1)}.Location, Neighborhood_Set{i}.uniqueID, Centraloffice{Idx(1)}.uniqueID);
                Dictionary(CommLink_Set{index_CommLink}.uniqueID) = CommLink_Set(index_CommLink);
                
                Neighborhood_Set{i}.Centraloffice = Centraloffice{Idx(1)}.uniqueID;
                Neighborhood_Set{i}.Neighborhood_Comm_Link = CommLink_Set{index_CommLink}.uniqueID;
                Centraloffice{Idx(1)}.PopulationServed = Centraloffice{Idx(1)}.PopulationServed + Neighborhood_Set{i}.Population;
                Centraloffice{Idx(1)}.Neighborhood{end+1}   = Neighborhood_Set{i}.uniqueID;
                Centraloffice{Idx(1)}.Neighborhood_Comm_Link{end+1}   = CommLink_Set{index_CommLink}.uniqueID;
                
                index_CommLink = index_CommLink + 1;
            end
            
            for i = 1:length(Neighborhood_Set)
                Idx = knnsearch(roadNode_location, Neighborhood_Set{i}.Location,'K',1);
                TransLink_Set{index_TransLink} = Neighborhood_Trans_Link(index_TransLink, Neighborhood_Set{i}.Location, roadNode{Idx(1)}.Location, Neighborhood_Set{i}.uniqueID, roadNode{Idx(1)}.uniqueID);
                Dictionary(TransLink_Set{index_TransLink}.uniqueID) = TransLink_Set(index_TransLink);
                
                Neighborhood_Set{i}.RoadNode = roadNode{Idx(1)}.uniqueID;
                Neighborhood_Set{i}.Neighborhood_Trans_Link = TransLink_Set{index_TransLink}.uniqueID;
                roadNode{Idx(1)}.Neighborhood{end+1} = Neighborhood_Set{i}.uniqueID;
                roadNode{Idx(1)}.Neighborhood_Trans_Link{end+1}   = TransLink_Set{index_TransLink}.uniqueID;
                
                index_TransLink = index_TransLink + 1;
            end
            Communication_Set{6} = CommLink_Set;
            Transportation_Set{5} = TransLink_Set;
            Power_Set{5} = PowerLink_Set;
            
            
            
        end
        
        % Assign restoration tasks for specific damaged object based on its
        % task and damagelevel
        function [Set,taskIndex] = assignTask(Set,index,sumTaskHash, sumDamageTaskHash,Dictionary,taskIndex)
            task_Set = {};
            parentType = Set{index}.Class;
            parentUniqueId = Set{index}.uniqueID;
            DamageTempTaskHash = sumDamageTaskHash('Bridge');
            tempTaskHash = sumTaskHash('Bridge');
            switch Set{index}.Class
                case 'Bridge'
                case 'Road'
                    DamageTempTaskHash = sumDamageTaskHash('Road');
                    tempTaskHash = sumTaskHash('Road');
                case 'TrafficLight'
                    DamageTempTaskHash = sumDamageTaskHash('TrafficLight');
                    tempTaskHash = sumTaskHash('TrafficLight');
                case 'Bus'
                    DamageTempTaskHash = sumDamageTaskHash('Bus');
                    tempTaskHash = sumTaskHash('Bus');
                case 'Branch'
                    DamageTempTaskHash = sumDamageTaskHash('Branch');
                    tempTaskHash = sumTaskHash('Branch');
                case 'CentralOffice'
                    DamageTempTaskHash = sumDamageTaskHash('CentralOffice');
                    tempTaskHash = sumTaskHash('CentralOffice');
                case 'CommunicationTower'
                    DamageTempTaskHash = sumDamageTaskHash('CommunicationTower');
                    tempTaskHash = sumTaskHash('CommunicationTower');
                case 'CommLine'
                    DamageTempTaskHash = sumDamageTaskHash('CommLine');
                    tempTaskHash = sumTaskHash('CommLine');
                case 'TransmissionTower'
                    DamageTempTaskHash = sumDamageTaskHash('TransmissionTower');
                    tempTaskHash = sumTaskHash('TransmissionTower');
                otherwise
                    
            end
            tasks = DamageTempTaskHash(Set{index}.DamageLevel);
            predecessorTask = [];
            if length(tasks) == 1
                tasks = tasks{1};
            else
                x = rand * length(tasks) + 1;
                tasks = tasks{floor(x)};
            end
            for j = 1:length(tasks)
                for k = 1:length(tasks{j})
                    idNeed = tasks{j}{k};
                    
                    tempTask = tempTaskHash(idNeed);
                    task = Task(taskIndex, idNeed,[tempTask{6},tempTask{7},tempTask{8},tempTask{9}],tempTask{2},tempTask{3},tempTask{4},tempTask{5}{1},tempTask{1},tempTask{10},parentType,parentUniqueId);
                    TemppredecessorTask{k} = task.uniqueID;
                    z = j;
                    task.predecessorTask = predecessorTask;
                    Set{index}.taskUniqueIds{end+1} = task.uniqueID;
                    Dictionary(task.uniqueID) = task;
                    task_Set{end + 1} = task;
                    taskIndex = taskIndex + 1;
                end
                predecessorTask = horzcat(predecessorTask,TemppredecessorTask);
            end
        end
        
        % Read in libraries for task and hash them together
        function  [sumTaskHash, sumDamageTaskHash] = setUpHashes()
            bridgeTaskHash = Library.createHash('bridgeTasks.mat');
            subbridgeTaskHash =Library.createHash('subBridgeTasks.mat');
            roadTaskHash = Library.createHash('roadTasks.mat');
            trafficLightTaskHash = Library.createHash('trafficLightTasks.mat');
            busTaskHash = Library.createHash('busTasks.mat');
            branchTaskHash = Library.createHash('branchTasks.mat');
            centralOfficeTaskHash = Library.createHash('centralOfficeTasks.mat');
            commTowerTaskHash = Library.createHash('commTowerTasks.mat');
            commLineTaskHash = Library.createHash('commLineTasks.mat');
            transTowerTaskHash = Library.createHash('transTowerTasks.mat');
            
            keySet = {'Bridge', 'Road', 'TrafficLight', 'Bus', 'Branch','CentralOffice', 'CommunicationTower', 'CommLine', 'TransmissionTower'};
%             valueSet={bridgeTaskHash,roadTaskHash,trafficLightTaskHash,busTaskHash,branchTaskHash,centralOfficeTaskHash,commTowerTaskHash,commLineTaskHash, transTowerTaskHash};
%             sumTaskHash = containers.Map(keySet,valueSet);
            newKeySet = [keySet,'subBridge'];
            valueSet={bridgeTaskHash,roadTaskHash,trafficLightTaskHash,busTaskHash,branchTaskHash,centralOfficeTaskHash,commTowerTaskHash,commLineTaskHash, transTowerTaskHash,subbridgeTaskHash};
            sumTaskHash = containers.Map(newKeySet,valueSet);
            
            DamageBridgeTaskHash = Library.hashTaskDmageLevel('DamageBridgeTasks');
            DamageRoadTaskHash = Library.hashTaskDmageLevel('DamageRoadTasks');
            DamageTrafficLightTaskHash = Library.hashTaskDmageLevel('DamageTrafficLightTasks');
            DamageBusTaskHash = Library.hashTaskDmageLevel('DamageBusTasks');
            DamageBranchTaskHash = Library.hashTaskDmageLevel('DamageBranchTasks');
            DamageCentralOfficeTaskHash = Library.hashTaskDmageLevel('DamageCentralOfficeTasks');
            DamageCommTowerTaskHash = Library.hashTaskDmageLevel('DamageCommTowerTasks');
            DamageCommLineTaskHash = Library.hashTaskDmageLevel('DamageCommLineTasks');
            DamageTransTowerTaskHash = Library.hashTaskDmageLevel('DamageTransTowerTasks');
            
            valueSet={DamageBridgeTaskHash,DamageRoadTaskHash,DamageTrafficLightTaskHash,DamageBusTaskHash,DamageBranchTaskHash,DamageCentralOfficeTaskHash,DamageCommTowerTaskHash,DamageCommLineTaskHash,DamageTransTowerTaskHash};
            sumDamageTaskHash = containers.Map(keySet,valueSet);
            
            %subcomponent
            DamageAbutmentTaskHash = Library.hashTaskDmageLevel('DamageAbutment.mat');
            DamageAbutmentFoundationTaskHash = Library.hashTaskDmageLevel('DamageAbutmentFoundation.mat');
            DamageApproachSlabTaskHash = Library.hashTaskDmageLevel('DamageApproachSlab.mat');
            DamageBearingTaskHash = Library.hashTaskDmageLevel('DamageBearing.mat');
            DamageColumnTaskHash = Library.hashTaskDmageLevel('DamageColumn.mat');
            DamageColumnFoundationTaskHash = Library.hashTaskDmageLevel('DamageColumnFoundation.mat');

            newKeySet = [keySet,'Abutment','AbutmentFoundation','ApproachSlab','Bearing','Column','ColumnFoundation']
            valueSet={DamageBridgeTaskHash,DamageRoadTaskHash,DamageTrafficLightTaskHash,DamageBusTaskHash,DamageBranchTaskHash,DamageCentralOfficeTaskHash,DamageCommTowerTaskHash,DamageCommLineTaskHash,DamageTransTowerTaskHash,DamageAbutmentTaskHash,DamageAbutmentFoundationTaskHash,DamageApproachSlabTaskHash,DamageBearingTaskHash,DamageColumnTaskHash,DamageColumnFoundationTaskHash};
            sumDamageTaskHash = containers.Map(newKeySet,valueSet);
            
        end
        
        function Set = getWorkDays(Set, i,Dictionary)
            tasks = Set{i}.taskUniqueIds;
            sumWorkDay = 0;
            flag = 0;
            for j = 1:length(tasks)
                temp = Dictionary(tasks{j});
                if iscell(temp)
                    temp = temp{1};
                end
                if temp.WorkingDays > 0
                    if flag == 0
                        Set{i}.currentWorking = temp.uniqueID;
                        Set{i}.Functionality = temp.taskFunctionality;
                        flag = 1;
                    end
                    sumWorkDay = sumWorkDay + temp.WorkingDays;
                end
            end
            Set{i}.WorkingDays = sumWorkDay;
        end
        
        % Sample a recovery duration for one single task
        function [samples] = simulatervLHS(samples,type,par)
            
            switch char(type)
                case 'dete'
                    samples=ones(length(samples),1)*par(1);
                case 'norm'
                    samples = norminv(samples,par(1),par(2));
                case 'logn'
                    sigmaN=sqrt(log(1+(par(2)/par(1))^2));
                    muN=log(par(1))-0.5*sigmaN^2;
                    samples = logninv(samples,muN,sigmaN);
                case 'Uniform/2'
                    samples=samples*(par(2)-par(1))+par(1);
                case 'triangular/1'
                    caso=samples<(par(3)-par(1))/(par(2)-par(1));
                    samples=(par(1)+sqrt(samples*(par(2)-par(1))*(par(3)-par(1))))    .*caso +...
                        (par(2)-sqrt((1-samples)*(par(2)-par(1))*(par(2)-par(3)))).*(~caso);
                case 'Triangular/1'
                    caso=samples<(par(3)-par(1))/(par(2)-par(1));
                    samples=(par(1)+sqrt(samples*(par(2)-par(1))*(par(3)-par(1))))    .*caso +...
                        (par(2)-sqrt((1-samples)*(par(2)-par(1))*(par(2)-par(3)))).*(~caso);
                case 'empi'
                    [ecdf_y,ecdf_x] = ecdf(par);
                    samples = interp1(ecdf_y,ecdf_x,samples,'linear');
                    
                otherwise
                    errordlg('This distribution has not been implemented yet','Code terminated')
            end
        end
        
        function taskTable = createTaskTable(Dictionary)
            key = keys(Dictionary);
            taskTable = {};
            for i = 1:length(key)
                temp = Dictionary(key{i});
                if iscell(temp)
                    temp = temp{1};
                end
                if strcmp(temp.Class, 'Task')
                    taskTable(end + 1,:) = {objTemp.uniqueID,objTemp.parentType,objTemp.parentUniqueID,objTemp.taskID,objTemp.taskDescription,objTemp.durationMin,objTemp.durationMax,objTemp.durationMode,objTemp.durationType,objTemp.WorkingDays,objTemp.Resources{1},objTemp.Resources{2},objTemp.Resources{3},objTemp.Resources{4}};
                end
            end
        end
        
        function taskTable = createTaskTableIndividual(Dictionary,sys)
            taskTable = {};
            if strcmp(sys, 'Power')
                taskTable = Library.createTaskTableIndividualHelper(taskTable, Dictionary , 'Branch');
                taskTable = Library.createTaskTableIndividualHelper(taskTable, Dictionary , 'Bus');
                taskTable = Library.createTaskTableIndividualHelper(taskTable, Dictionary , 'TransmissionTower');
            elseif strcmp(sys, 'Transportation')
                taskTable = Library.createTaskTableIndividualHelper(taskTable, Dictionary , 'Road');
                taskTable = Library.createTaskTableIndividualHelper(taskTable, Dictionary , 'Bridge');
                taskTable = Library.createTaskTableIndividualHelper(taskTable, Dictionary , 'TrafficLight');
            elseif strcmp(sys, 'Communication')
                taskTable = Library.createTaskTableIndividualHelper(taskTable, Dictionary , 'CentralOffice');
                taskTable = Library.createTaskTableIndividualHelper(taskTable, Dictionary , 'Router');
                taskTable = Library.createTaskTableIndividualHelper(taskTable, Dictionary , 'Cellline');
                taskTable = Library.createTaskTableIndividualHelper(taskTable, Dictionary , 'CommunicationTower');
            end
        end

        function taskTable = createTaskTableIndividualHelper(taskTable, Dictionary, class)
            key = keys(Dictionary);
            for i = 1:length(key)
                temp = Dictionary(key{i});
                if iscell(temp)
                    temp = temp{1};
                end
                if strcmp(temp.Class, 'Task') && strcmp(temp.parentType, class)
                    taskTable(end + 1,:) = {temp.uniqueID,temp.parentType,temp.parentUniqueID,temp.taskID,temp.taskDescription,temp.durationMin,temp.durationMax,temp.durationMode,temp.durationType,temp.WorkingDays,temp.Resources{1},temp.Resources{2},temp.Resources{3},temp.Resources{4}};
                end
            end
        end
        
        function lookupTable = addToLookupTable(lookupTable, objTemp, startDate,isTask)
            if isTask ~= 1
                objTemp = objTemp{1};
            end
            if strcmp(objTemp.Class,'Task')
                
                lookupTable(end + 1,:) = {objTemp.uniqueID,objTemp.parentType,objTemp.parentUniqueID,objTemp.taskID,objTemp.taskDescription,objTemp.durationMin,objTemp.durationMax,objTemp.durationMode,objTemp.durationType,startDate,objTemp.WorkingDays,startDate + objTemp.WorkingDays};
            else
                lookupTable(end + 1,:) = {objTemp.uniqueID, -1,'',-1,-1,-1,'',startDate,objTemp.WorkingDays,startDate + objTemp.WorkingDays,'',''};
            end
        end
        
        function funcTable = initialFuncTable(Pow, Comm, Trans,funcTable,time_horizon,Neighborhood)
            % Initiallize functionality table (func vs time for all objects)
            funcTable = Library.initialFuncTableHelper(Pow,time_horizon, funcTable);
            funcTable = Library.initialFuncTableHelper(Comm,time_horizon, funcTable);
            funcTable = Library.initialFuncTableHelper(Trans,time_horizon, funcTable);
            for i = 1:length(Neighborhood)
                if strcmp(Neighborhood{i}.Status, 'Stoped')
                    funcTable(Neighborhood{i}.uniqueID) = zeros(1,time_horizon);
                end
            end
        end
        
        function funcTable = initialFuncTableHelper(Set,time_horizon, funcTable)
            for i = 1:length(Set) - 1
                for j = 1:length(Set{i})
                    if strcmp(Set{i}{1}.Class,'RoadNode')
                        break;
                    end
                    if strcmp(Set{i}{j}.Status, 'Damaged') || strcmp(Set{i}{j}.Status, 'Stoped')
                        funcTable(Set{i}{j}.uniqueID) = zeros(1,time_horizon);
                    end
                end
            end
        end
        
        function printedFuncTable = printFuncTable(funcTable, time_horizon)
            key = keys(funcTable);
            printedFuncTable = cell(length(key),time_horizon + 1);
            for i = 1:length(key)
                printedFuncTable{i,1} = key{i};
                temp = funcTable(key{i});
                for j = 1:length(temp)
                    printedFuncTable{i,j + 1} = temp(j);
                end
            end
        end
        
        function [taskSet,indexTable] = countTask(Dictionary)
            indexTable = containers.Map('KeyType','char','ValueType','double');
            taskSet = {};
            key = keys(Dictionary);
            for i = 1:length(key)
                temp = Dictionary(key{i});
                if iscell(temp)
                    temp = temp{1};
                end
                if strcmp(temp.Class, 'Task')
                    taskSet{end + 1} = temp.uniqueID;
                    indexTable(temp.uniqueID) = length(taskSet);
                end
            end
        end
        
        function [taskSet,indexTable] = countTaskIndividual(Dictionary, class,taskSet,indexTable)
            key = keys(Dictionary);
            for i = 1:length(key)
                temp = Dictionary(key{i});
                if iscell(temp)
                    temp = temp{1};
                end
                if strcmp(temp.Class, 'Task') && strcmp(temp.parentType, class)
                    taskSet{end + 1} = temp.uniqueID;
                    indexTable(temp.uniqueID) = length(taskSet);
                end
            end
        end
        
        function precedenceTable = createPreTable(Dictionary)
            
            [taskSet,indexTable] = Library.countTask(Dictionary);
            taskCount = length(taskSet);
            precedenceTable = cell(taskCount + 1, taskCount + 1);
            for i = 1:taskCount
                temp = taskSet{i};
                precedenceTable{1, i+1} = temp;
                precedenceTable{i+1, 1} = temp;
            end
            for i = 1:taskCount
                temp = Dictionary(taskSet{i});
                if iscell(temp)
                    temp = temp{1};
                end
                precedenceTable(i+1,2:end) = {0};
                if ~isempty(temp.predecessorTask)
                    tasks = temp.predecessorTask;
                    for j = 1:length(tasks)
                        index = indexTable(tasks{j});
                        precedenceTable{i+1, index + 1} = 1;
                    end
                end
            end
        end
        
        function precedenceTable = createPreTableIndividual(Dictionary, sys)
            indexTable = containers.Map('KeyType','char','ValueType','double');
            taskSet = {};
            if strcmp(sys, 'Power')
                [taskSet,indexTable] = Library.countTaskIndividual(Dictionary, 'Branch',taskSet,indexTable);
                [taskSet,indexTable] = Library.countTaskIndividual(Dictionary, 'Bus',taskSet,indexTable);
                [taskSet,indexTable] = Library.countTaskIndividual(Dictionary, 'TransmissionTower',taskSet,indexTable);
            elseif strcmp(sys, 'Transportation')
                [taskSet,indexTable] = Library.countTaskIndividual(Dictionary, 'Road',taskSet,indexTable);
                [taskSet,indexTable] = Library.countTaskIndividual(Dictionary, 'Bridge',taskSet,indexTable);
                [taskSet,indexTable] = Library.countTaskIndividual(Dictionary, 'TrafficLight',taskSet,indexTable);
            elseif strcmp(sys, 'Communication')
                [taskSet,indexTable] = Library.countTaskIndividual(Dictionary, 'CentralOffice',taskSet,indexTable);
                [taskSet,indexTable] = Library.countTaskIndividual(Dictionary, 'Router',taskSet,indexTable);
                [taskSet,indexTable] = Library.countTaskIndividual(Dictionary, 'Cellline',taskSet,indexTable);
                [taskSet,indexTable] = Library.countTaskIndividual(Dictionary, 'CommunicationTower',taskSet,indexTable);
            end
            taskCount = length(taskSet);
            precedenceTable = cell(taskCount + 1, taskCount + 1);
            for i = 1:taskCount
                temp = taskSet{i};
                precedenceTable{1, i+1} = temp;
                precedenceTable{i+1, 1} = temp;
            end
            for i = 1:taskCount
                temp = Dictionary(taskSet{i});
                if iscell(temp)
                    temp = temp{1};
                end
                precedenceTable(i+1,2:end) = {0};
                if ~isempty(temp.predecessorTask)
                    tasks = temp.predecessorTask;
                    for j = 1:length(tasks)
                        index = indexTable(tasks{j});
                        precedenceTable{i+1, index + 1} = 1;
                    end
                end
            end
        end
        
        function totalPopulation = countPopulation(Dictionary)
            key = keys(Dictionary);
            totalPopulation = 0;
            for i = 1:length(key)
                temp = Dictionary(key{i});
                if iscell(temp)
                    temp = temp{1};
                end
                if strcmp(temp.Class, 'Neighborhood')
                    totalPopulation = totalPopulation + temp.Population;
                end
            end
        end
        
        function [totalPopulation,neighbourPowFunc,neighbourCommFunc,neighbourTransFunc] = neighbourFunc(Dictionary)
            key = keys(Dictionary);
            totalPopulation = 0;
            totalHasPow = 0;
            totalHasComm = 0;
            totalHasTrans = 0;
            for i = 1:length(key)
                temp = Dictionary(key{i});
                if iscell(temp)
                    temp = temp{1};
                end
                if strcmp(temp.Class, 'Neighborhood')
                    if temp.PowerStatus == 1
                        totalHasPow = totalHasPow + temp.Population;
                    end
                    if temp.CommStatus == 1
                        totalHasComm = totalHasComm + temp.Population;
                    end
                    if temp.TransStatus == 1
                        totalHasTrans = totalHasTrans + temp.Population;
                    end
                    totalPopulation = totalPopulation + temp.Population;
                end
            end
            neighbourPowFunc = totalHasPow / totalPopulation;
            neighbourCommFunc = totalHasComm / totalPopulation;
            neighbourTransFunc = totalHasTrans / totalPopulation;
        end
        
        function Trans = assignRoadToRoadNode(Trans,Dictionary)
            Road_Set = Trans{1};
            for i = 1:length(Road_Set)
                roadTemp = Road_Set{i};
                nodeStart = Dictionary(strcat('RoadNode',num2str(roadTemp.Start_Node)));
                nodeEnd = Dictionary(strcat('RoadNode',num2str(roadTemp.End_Node)));
                nodeStart = nodeStart{1};
                nodeEnd = nodeEnd{1};
                nodeStart.Roads{end+1} = roadTemp.uniqueID;
                nodeEnd.Roads{end+1} = roadTemp.uniqueID;
            end
        end
        
        % Rank Power system
        
        
        %% Old
        function return_Schedule = CleanOld(Current, Pow, Comm, Trans, Max_Power, Max_Comm, Max_Trans, system)
            Branch= Pow{1};
            Bus= Pow{2};
            Generator= Pow{3};
            
            Antenna = Comm{1};
            Centraloffice = Comm{2};
            Router = Comm{3};
            Cellline = Comm{4};
            CommunicationTower = Comm{5};
            
            Road = Trans{1};
            Bridge = Trans{2};
            TrafficLight = Trans{3};
            
            tmp = Current;
            
            
            for i = 1:length(tmp)
                if ~isempty(tmp{i})
                    if system == 1
                        for j = 1:length(Max_Power)
                            resourceNeed = Library.getResourceOld(tmp{i}, Pow, Comm, Trans);
                            Max_Power(j) = Max_Power(j) + resourceNeed;
                        end
                    elseif system == 2
                        for j = 1:length(Max_Comm)
                            resourceNeed = Library.getResourceOld(tmp{i}, Pow, Comm, Trans);
                            Max_Comm(j) = Max_Comm(j) + resourceNeed;
                        end
                    elseif system == 3
                        for j = 1:length(Max_Trans)
                            resourceNeed = Library.getResourceOld(tmp{i}, Pow, Comm, Trans);
                            Max_Trans(j) = Max_Trans(j) + resourceNeed;
                        end
                    end
                    tem = strsplit(tmp{i},'/');
                    if strcmp(tem{1}, 'Branch') && Branch{str2double(tem{2})}.WorkingDays <= 0
                        Branch{str2double(tem{2})}.WorkingDays = 0;
                        Current{i} = [];
                    elseif strcmp(tem{1}, 'Bus') && Bus{str2double(tem{2})}.WorkingDays <= 0
                        Bus{str2double(tem{2})}.WorkingDays = 0;
                        Current{i} = [];
                    elseif strcmp(tem{1}, 'Generator') && Generator{str2double(tem{2})}.WorkingDays <= 0
                        Generator{str2double(tem{2})}.WorkingDays = 0;
                        Current{i} = [];
                    elseif strcmp(tem{1}, 'Antenna') && Antenna{str2double(tem{2})}.WorkingDays <= 0
                        Antenna{str2double(tem{2})}.WorkingDays = 0;
                        Current{i} = [];
                    elseif strcmp(tem{1}, 'Centraloffice') && Centraloffice{str2double(tem{2})}.WorkingDays <= 0
                        Centraloffice{str2double(tem{2})}.WorkingDays = 0;
                        Current{i} = [];
                    elseif strcmp(tem{1}, 'Router') && Router{str2double(tem{2})}.WorkingDays <= 0
                        Router{str2double(tem{2})}.WorkingDays = 0;
                        Current{i} = [];
                    elseif strcmp(tem{1}, 'Cellline') && Cellline{str2double(tem{2})}.WorkingDays <= 0
                        Cellline{str2double(tem{2})}.WorkingDays = 0;
                        Current{i} = [];
                    elseif strcmp(tem{1}, 'CommunicationTower') && CommunicationTower{str2double(tem{2})}.WorkingDays <= 0
                        CommunicationTower{str2double(tem{2})}.WorkingDays = 0;
                        Current{i} = [];
                    elseif strcmp(tem{1}, 'Road') && Road{str2double(tem{2})}.WorkingDays <= 0
                        Road{str2double(tem{2})}.WorkingDays = 0;
                        Current{i} = [];
                    elseif strcmp(tem{1}, 'Bridge') && Bridge{str2double(tem{2})}.WorkingDays <= 0
                        Bridge{str2double(tem{2})}.WorkingDays = 0;
                        Current{i} = [];
                    elseif strcmp(tem{1}, 'TrafficLight') && TrafficLight{str2double(tem{2})}.WorkingDays <= 0
                        TrafficLight{str2double(tem{2})}.WorkingDays = 0;
                        Current{i} = [];
                        
                        
                    end
                end
            end
            return_Schedule = Current;
        end
        function result = getResourceOld(Object, Power_Set, Communication_Set, Transportation_Set)
            Branch= Power_Set{1};
            Bus= Power_Set{2};
            Generator= Power_Set{3};
            
            Antenna = Communication_Set{1};
            Centraloffice = Communication_Set{2};
            Router = Communication_Set{3};
            Cellline = Communication_Set{4};
            CommunicationTower = Communication_Set{5};
            
            Road = Transportation_Set{1};
            Bridge = Transportation_Set{2};
            TrafficLight = Transportation_Set{3};
            
            tem = strsplit(Object,'/');
            name = tem{1};
            number = str2num(tem{2});
            result =1;
        end
        function WorkingProcessOld(Current, Pow, Comm, Trans, Days)
            Branch= Pow{1};
            Bus= Pow{2};
            Generator= Pow{3};
            
            Antenna = Comm{1};
            Centraloffice = Comm{2};
            Router = Comm{3};
            Cellline = Comm{4};
            CommunicationTower = Comm{5};
            
            Road = Trans{1};
            Bridge = Trans{2};
            TrafficLight = Trans{3};
            
            for i = 1:length(Current)
                if ~isempty(Current{i})
                    tem = strsplit(Current{i},'/');
                    if strcmp(tem{1}, 'Branch')
                        Branch{str2double(tem{2})}.WorkingDays = Branch{str2double(tem{2})}.WorkingDays - Days;
                        %                         fprintf('Branch %d : %d\n', str2double(tem{2}), Branch{str2double(tem{2})}.WorkingDays);
                    elseif strcmp(tem{1}, 'Bus')
                        if Bus{str2double(tem(2))}.WorkingDays < Days
                        end
                        Bus{str2double(tem{2})}.WorkingDays = Bus{str2double(tem{2})}.WorkingDays - Days;
                        %                         fprintf('Bus %d : %d\n', str2double(tem{2}), Bus{str2double(tem{2})}.WorkingDays);
                    elseif strcmp(tem{1}, 'Generator')
                        Generator{str2double(tem{2})}.WorkingDays = Generator{str2double(tem{2})}.WorkingDays - Days;
                        %                         fprintf('Generator %d : %d\n', str2double(tem{2}), Generator{str2double(tem{2})}.WorkingDays);
                    elseif strcmp(tem{1}, 'Centraloffice')
                        Centraloffice{str2double(tem{2})}.WorkingDays = Centraloffice{str2double(tem{2})}.WorkingDays - Days;
                        %                         fprintf('Centraloffice %d : %d\n', str2double(tem{2}), Centraloffice{str2double(tem{2})}.WorkingDays);
                    elseif strcmp(tem{1}, 'Router')
                        Router{str2double(tem{2})}.WorkingDays = Router{str2double(tem{2})}.WorkingDays - Days;
                        %                         fprintf('Router %d : %d\n', str2double(tem{2}), Router{str2double(tem{2})}.WorkingDays);
                    elseif strcmp(tem{1}, 'Cellline')
                        Cellline{str2double(tem{2})}.WorkingDays = Cellline{str2double(tem{2})}.WorkingDays - Days;
                        %                         fprintf('Cellline %d : %d\n', str2double(tem{2}), Cellline{str2double(tem{2})}.WorkingDays);
                    elseif strcmp(tem{1}, 'CommunicationTower')
                        CommunicationTower{str2double(tem{2})}.WorkingDays = CommunicationTower{str2double(tem{2})}.WorkingDays - Days;
                        %                         fprintf('Cellline %d : %d\n', str2double(tem{2}), Cellline{str2double(tem{2})}.WorkingDays);
                    elseif strcmp(tem{1}, 'Road')
                        Road{str2double(tem{2})}.WorkingDays = Road{str2double(tem{2})}.WorkingDays - Days;
                        %                         fprintf('Road %d : %d\n', str2double(tem{2}), Road{str2double(tem{2})}.WorkingDays);
                    elseif strcmp(tem{1}, 'Bridge')
                        %Bridge{str2double(tem{2})}.WorkingDays = Bridge{str2double(tem{2})}.WorkingDays - Days;
                        %                         fprintf('Bridge %d : %d\n', str2double(tem{2}), Bridge{str2double(tem{2})}.WorkingDays);
                    elseif strcmp(tem{1}, 'TrafficLight')
                        TrafficLight{str2double(tem{2})}.WorkingDays = TrafficLight{str2double(tem{2})}.WorkingDays - Days;
                        %                         fprintf('TrafficLight %d : %d\n', str2double(tem{2}), TrafficLight{str2double(tem{2})}.WorkingDays);
                    end
                end
            end
            
            
            %                         disp('-----------------------------------');
        end
        function graphTheory(Trans_Set)
            hash = containers.Map('KeyType','double','ValueType','double');
            
            input_node = [];
            input_road = [];
            roadnode_Set = Trans_Set{4};
            road_Set = Trans_Set{1};
            for i = 1:length(roadnode_Set)
                input_node{i, 1} = roadnode_Set{i}.Location(1);
                input_node{i, 2} = roadnode_Set{i}.Location(2);
                hash(roadnode_Set{i}.nodeID) = i;
            end
            for i = 1:length(road_Set)
                index1 = hash(road_Set{i}.Start_Location(1));
                index2 = hash(road_Set{i}.End_Location(1));
                input_road{i, 1} = index1;
                input_road{i, 2} = index2;
            end
            
            %grPlot(cell2mat(input_node),cell2mat(input_road),'g');
        end
        function [returnCurrent, returnSchedule] = AddCurrentWorkingOld(Max, Current, Schedule, Dictionary)
            index = 1;
            for i = 1:Max
                if i <= length(Current)
                    if ~isempty(Current{i})
                        continue;
                    end
                end
                found = 0;
                while found == 0 && index <= length(Schedule)
                    tem = strsplit(Schedule{index},'/');
                    if length(tem) == 3
                        tasktemp = Dictionary(tem{3});
                        flag = 0;
                        for j = 1:length(tasktemp.predecessorTask)
                            if(Dictionary(tasktemp.predecessorTask{j}).WorkingDays > 0)
                                flag = 1;
                                break;
                            end
                        end
                        
                        
                        if flag ~= 0
                            index = index + 1;
                            continue;
                        end
                        if tasktemp.WorkingDays == 0
                            disp('Add Task Temp');
                            disp(tasktemp);
                        end
                    end
                    if length(tem) == 2 || length(tem) == 3
                        Schedule{index} = strcat(Schedule{index},'/Working/dummy');
                        Current{i} = Schedule{index};
                        found = 1;
                    end
                    index = index + 1;
                end
            end
            
            returnCurrent = Current;
            returnSchedule = Schedule;
        end
        
        %         function [Power, Comm, Trans] = Repairation(time_horizon, Interdependence_Num, ReSchedule_Num, Max_Power, Max_Comm, Max_Trans, Power_Func_Num, Trans_Func_Num, Comm_Func_Num, Schedule_Power, Schedule_Comm, Schedule_Trans, Power_Set, Communication_Set, Transportation_Set, Dictionary, System_Dependent_Factor, transGraph, powerGraph, commGraph,Neighborhood,Seperate_Scheduling)
%             %Branch_Set = Power_Set{1};
%             %temp = Dictionary(Branch_Set{1}.uniqueID);
%             %temp{1}.WorkingDays = 100;
%             %disp(Branch_Set{1});
%             %subplot(1,3,1);
%             %plot(transGraph,'Layout','force');
%             %subplot(1,3,2);
%             %plot(powerGraph,'Layout','force');
%             %subplot(1,3,3);
%             %plot(commGraph,'Layout','force');
%             lookupTable = {};
%             [totalPopulation,PowFunc,CommFunc,TransFunc] = Library.neighbourFunc(Dictionary);
%             
%             funcTable = containers.Map('KeyType','char','ValueType','any');
%             funcTable = Library.initialFuncTable(Power_Set, Communication_Set, Transportation_Set,funcTable,time_horizon,Neighborhood);
%             neighbourPowFunc = zeros(1,time_horizon);
%             neighbourCommFunc = zeros(1,time_horizon);
%             neighbourTransFunc = zeros(1,time_horizon);
%             Power = zeros(1,time_horizon);
%             Comm = zeros(1,time_horizon);
%             Trans = zeros(1,time_horizon);
%             TransTest = zeros(4,time_horizon);
%             CurrentWorking_Power = {};
%             CurrentWorking_Comm = {};
%             CurrentWorking_Trans = {};
%             
%             finish = 0;
%             Start_Day = 1;
%             End_Day = 1;
%             flag = 0;
%             ploti= 0;
%             
%             total_damaged = length(Schedule_Power) + length(Schedule_Comm) + length(Schedule_Trans);
%             total_fixed = 0;
%             need_reschedule = 0;
%             
%             % Calculate actual repair time
%             
%             while finish == 0
%                 
%                 % Add Damaged Component to Current Working List Based on
%                 % Resource Constraint
%                 [CurrentWorking_Power, Schedule_Power, Max_Power,lookupTable] = Library.AddCurrentWorking(Max_Power, CurrentWorking_Power, Schedule_Power, Dictionary,lookupTable,Start_Day);
%                 [CurrentWorking_Comm, Schedule_Comm, Max_Comm,lookupTable] = Library.AddCurrentWorking(Max_Comm, CurrentWorking_Comm, Schedule_Comm, Dictionary,lookupTable,Start_Day);
%                 [CurrentWorking_Trans, Schedule_Trans, Max_Trans,lookupTable] = Library.AddCurrentWorking(Max_Trans, CurrentWorking_Trans, Schedule_Trans, Dictionary,lookupTable,Start_Day);
%                 
%                 % Calculation inerdependence and the working days
%                 %Interface.InterdependenceFactor(Interdependence_Num, CurrentWorking_Power, CurrentWorking_Comm, CurrentWorking_Trans, Power_Set, Communication_Set, Transportation_Set);
%                 
%                 % Find Day for the Component take shorest time
%                 Days = Library.FindMinDays(CurrentWorking_Power, CurrentWorking_Comm, CurrentWorking_Trans, Power_Set, Communication_Set, Transportation_Set,Dictionary);
%                 % Updating the Working Days for Current Working Component
%                 
%                 Library.WorkingProcess(CurrentWorking_Power, Dictionary, Days);
%                 Library.WorkingProcess(CurrentWorking_Comm, Dictionary, Days);
%                 Library.WorkingProcess(CurrentWorking_Trans, Dictionary, Days);
%                 
%                 if Days ~= 0
%                     if Days == 1
%                         End_Day = End_Day + 1;
%                     else
%                         End_Day = End_Day + ceil(Days);
%                     end
%                 else
%                     End_Day = time_horizon;
%                     finish = 1;
%                 end
%                 % Calculated Functionality
%                 [Trans_Fun, Pow_Fun, Comm_Fun] = Interface1.Functionality(Power_Func_Num, Trans_Func_Num, Comm_Func_Num, Power_Set, Communication_Set, Transportation_Set);
%                 if Interdependence_Num == 1
%                     if flag == 0 && Trans_Fun < 0.8
%                         Library.SysFuncInterdependence(Power_Set, Communication_Set, Transportation_Set, System_Dependent_Factor, Dictionary);
%                         flag = 1;
%                     elseif flag == 1 && Trans_Fun > 0.8
%                         Restore_Factor = 1 / System_Dependent_Factor;
%                         Library.SysFuncInterdependence(Power_Set, Communication_Set, Transportation_Set, Restore_Factor, Dictionary);
%                         flag = 2;
%                     else
%                         Library.SysFuncInterdependence(Power_Set, Communication_Set, Transportation_Set, 1, Dictionary);
%                         
%                     end
%                 else
%                     Library.SysFuncInterdependence(Power_Set, Communication_Set, Transportation_Set, 1, Dictionary);
%                 end
%                 
%                 
%                 
%                 [CurrentWorking_Power,Max_Power] = Library.Clean(CurrentWorking_Power, Dictionary, Max_Power);
%                 [CurrentWorking_Comm,Max_Comm] = Library.Clean(CurrentWorking_Comm, Dictionary, Max_Comm);
%                 [CurrentWorking_Trans,Max_Trans] = Library.Clean(CurrentWorking_Trans, Dictionary, Max_Trans);
%                 
%                 
%                 % Update the Status for reparied Component
%                 [need_reschedule, total_fixed, transGraph, powerGraph, commGraph,Power_Set, Communication_Set, Transportation_Set,funcTable] = Library.UpdateStatus(Power_Set, Communication_Set, Transportation_Set, total_damaged, total_fixed, need_reschedule,Dictionary, transGraph, powerGraph, commGraph,funcTable,End_Day);
%                 
%                 if ReSchedule_Num ~= 0
%                     if need_reschedule == 1
%                         need_reschedule = 2;
%                         Schedule = {Schedule_Power, Schedule_Comm, Schedule_Trans};
%                         Schedule = Interface1.RepairReSchedule(ReSchedule_Num, Schedule, time_horizon, Max_Power, Max_Trans, Max_Comm, Power_Set, Communication_Set, Transportation_Set);
%                         Schedule_Power = Schedule{1};
%                         Schedule_Comm = Schedule{2};
%                         Schedule_Trans = Schedule{3};
%                     end
%                 end
%                 
%                 [totalPopulation,PowFunc,CommFunc,TransFunc] = Library.neighbourFunc(Dictionary);% Propotion of population that has power/comm/trans
%                 neighbourPowFunc(Start_Day:End_Day) = PowFunc;
%                 neighbourCommFunc(Start_Day:End_Day) = CommFunc;
%                 neighbourTransFunc(Start_Day:End_Day) = TransFunc;
%                 Trans(Start_Day:End_Day) = Trans_Fun;
%                 Power(Start_Day:End_Day) = Pow_Fun;
%                 Comm(Start_Day:End_Day) = Comm_Fun;
%                 %p = plot(commGraph,'Layout','force');
%                 %saveas(p,strcat('./test/Comm', num2str(ploti),'.jpg'));
%                 %p = plot(powerGraph,'Layout','force');
%                 %saveas(p,strcat('./test/Power', num2str(ploti),'.jpg'));
%                 TransTest = Library.ComputeFunc(transGraph, Start_Day, End_Day,TransTest);
%                 ploti = ploti + 1;
%                 
%                 Start_Day = End_Day + 1;
%             end
%             
%             % Error Check
%             filename = strcat('lookupTable.mat');
%             save(filename, 'lookupTable');
%             printedFuncTable = Library.printFuncTable(funcTable, time_horizon);
%             filename = strcat('printedFuncTable.mat');
%             save(filename, 'printedFuncTable');
%             if Power(time_horizon) ~= 1
%                 disp('ERROR 1: Functionality Power');
%             end
%             
%             if Comm(time_horizon) ~= 1
%                 disp('ERROR 2: Functionality Communication');
%             end
%             
%             if Trans(time_horizon) ~= 1
%                 disp('ERROR 3: Functionality Transportation');
%             end
%             
%         end
%     
        
        %% Test Functions
        function Count(Set)
            count = 0;
            for i = 1:length(Set)
                for j = 1:length(Set{i})
                    if ~strcmp(Set{i}{j}.Status, 'Open')
                        disp(Set{i}{j});
                        count = count + 1;
                    end
                end
            end
            disp(count);
        end
        function CountTotal(Set1,Set2,Set3)
            Set = {Set1,Set2,Set3};
            for k = 1:length(Set)
                count = 0;
                for i = 1:length(Set{k})
                    for j = 1:length(Set{k}{i})
                        if ~strcmp(Set{k}{i}{j}.Status, 'Open')
                            count = count + 1;
                        end
                    end
                end
                disp(count);
            end
        end
        function CountZeros(Current, Dictionary)
            for i = 1:length(Current)
                if ~isempty(Current{i})
                    temp = Dictionary(Library.getUniqueId(Current{i}, 1));
                    if iscell(temp)
                        temp = temp{1};
                    end
                    if temp.WorkingDays <= 0
                        disp('WARNING....');
                        disp(Current{i});
                        disp(temp);
                    end
                end
            end
        end
        function WrapperCountZeros(a,b,c,Dictionary,num)
            disp(num);
            Library.CountZeros(a,Dictionary);
            Library.CountZeros(b,Dictionary);
            Library.CountZeros(c,Dictionary);
        end
    end
end
