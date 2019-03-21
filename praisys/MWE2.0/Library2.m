classdef Library2
    methods(Static)

        
        
        %% damage evaluation
        
        % DamageEval function needs to be replaced by a new fragility
        % analysis function. 
        function DamageEval(cell,Event,IM,IMx,IMy)
            
            switch cell{1}.Class
                case {'Branch', 'Generator', 'Antenna', 'Centraloffice', 'Router', 'CommunicationTower'}
%                     
                    for i = 1:size(cell,2)
                        Intensity = interp2(IMx,IMy,IM,cell{i}.Location(1),cell{i}.Location(2));
                        % assign probabilty of failure we can improve it later
                         Prob_Failure = Library2.Prob_Failure(Intensity,cell{i}); 
                            Y = [1, Prob_Failure, 0];
                            aa = rand;
                            index = -1;
                            for idx = 1:length(Y)-1
                                if lt((aa - Y(idx))*(aa > Y(idx + 1)),0) 
                                    index = idx;
                                end
                            end

                            cell{i}.DamageLevel = index;
                             if isempty(cell{i}.DamageLevel)
                                tmp = 0;
                            end
                            Library2.Recovery(cell{i});
                            if cell{i}.DamageLevel > 1 
                                cell{i}.Status='Damaged';
                            end
                            
                    end                    
                    
                case {'Road' 'Cellline', 'Bus'}
                    for i = 1:size(cell,2)
                        Intensity=interp2(IMx,IMy,IM,cell{i}.Start_Location(1),cell{i}.Start_Location(2));
%                         Intensity=Intensity + interp2(IMx,IMy,IM,cell{i}.End_Location(1),cell{i}.End_Location(2));
                        % assign probabilty of failure we can improve it later
                         Prob_Failure = Library2.Prob_Failure(Intensity,cell{i}); 
                            Y = [1, Prob_Failure, 0];
                            aa = rand;
                            index = -1;
                            for idx = 1:length(Y)-1
                                if lt((aa - Y(idx))*(aa > Y(idx + 1)),0) 
                                    index = idx;
                                end
                            end

                            cell{i}.DamageLevel = index;
                            if isempty(cell{i}.DamageLevel)
                                tmp = 0;
                            end
                            Library2.Recovery(cell{i});
                            if cell{i}.DamageLevel > 1 
                                cell{i}.Status='Damaged';
                            end
                        
                    end
                case {'TrafficLight', 'Bridge'}
                    for i = 1:size(cell,2)
                        if cell{i}.Destructible == 1
                            Intensity = interp2(IMx,IMy,IM,cell{i}.Location(1),cell{i}.Location(2));
                            % assign probabilty of failure we can improve it later
                            Prob_Failure = Library3.Bridge_Prob_Failure(Intensity,cell{i}); 
                            Y = [1, Prob_Failure, 0];
                           aa = rand;
                            index = -1;
                            for idx = 1:length(Y)-1
                                if lt((aa - Y(idx))*(aa > Y(idx + 1)),0) 
                                    index = idx;
                                end
                            end

                            cell{i}.DamageLevel = index; 
                             if isempty(cell{i}.DamageLevel)
                                tmp = 0;
                            end
                            Library2.Recovery(cell{i});
                            if cell{i}.DamageLevel > 1 
                                cell{i}.Status='Damaged';
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
            
        end
        
        % Compute recovery time based on damage state for further scheduler computation
        function Recovery(Object)
            if Object.DamageLevel == 1     % no damage
                Object.Recovery = [0,0];
            elseif Object.DamageLevel==2 % slight damage
                Object.Recovery = Object.RecoveryMatrix(1,:);
            elseif Object.DamageLevel==3 % moderate damage
                Object.Recovery = Object.RecoveryMatrix(2,:);    
            elseif Object.DamageLevel==4 % extensive damage
                Object.Recovery = Object.RecoveryMatrix(3,:);
            elseif Object.DamageLevel==5 % complete damage
                Object.Recovery = Object.RecoveryMatrix(4,:);    
            end
            if isempty(Object.Recovery)
                tmp =0;
            end
        end
        
        
%         function PlotFigureFunctionality(time_horizon, Functionality_Statistics_Power, Functionality_Statistics_Communication, Functionality_Statistics_Transportation);
%             lw = 2;            
%             
%             ps = figure('visible','off');
%             idx = 3; plot([1:time_horizon], Functionality_Statistics_Power(idx,:),'r:');
%             hold on, idx = 4; plot([1:time_horizon], Functionality_Statistics_Power(idx,:),'k-','LineWidth',lw);
%             hold on, idx = 5; plot([1:time_horizon], Functionality_Statistics_Power(idx,:),'b:');
%             legend('25%','50%','75%')
%             xlabel('Time (day)');
%             ylabel('Power Functionality ');
%             title('Power System Percentiles');
%             
%             cs = figure('visible','off');
%             idx = 3; plot([1:time_horizon], Functionality_Statistics_Communication(idx,:),'r:');
%             hold on, idx = 4; plot([1:time_horizon], Functionality_Statistics_Communication(idx,:),'k-','LineWidth',lw);
%             hold on, idx = 5; plot([1:time_horizon], Functionality_Statistics_Communication(idx,:),'b:');
%             legend('25%','50%','75%')
%             xlabel('Time (day)');
%             ylabel('Communication Functionality ');
%             title('Communication System Percentiles');
%   
%             ts = figure('visible','off');
%             idx = 3; plot([1:time_horizon], Functionality_Statistics_Transportation(idx,:),'r:');
%             hold on, idx = 4; plot([1:time_horizon], Functionality_Statistics_Transportation(idx,:),'k-','LineWidth',lw);
%             hold on, idx = 5; plot([1:time_horizon], Functionality_Statistics_Transportation(idx,:),'b:');
%             legend('25%','50%','75%')
%             xlabel('Time (day)');
%             ylabel('Transportation Functionality ');
%             title('Transportation System Percentiles');
%             
%             saveas(ps,'./plot/PowerStatistics.jpg');
%             saveas(cs,'./plot/CommunicationStatistics.jpg');
%             saveas(ts,'./plot/TransportationStatistics.jpg');
%             
%         end
%         
%         function PlotFigureResilience(Resilience_Power, Resilience_Communication, Resilience_Transportation)
%             RImean = [mean(Resilience_Power), mean(Resilience_Communication), mean(Resilience_Transportation)];
%             RIstd = [std(Resilience_Power), std(Resilience_Communication), std(Resilience_Transportation)];
%         
%         ri = figure('visible','off');
%         bar(1:3, RImean,...
%             'FaceColor',[0 .5 .5],...
%             'EdgeColor',[0 .9 .9],...
%             'LineWidth',0.5);
%         hold on, errorbar(1:3, RImean, RIstd,...
%             '-s',... %'MarkerSize',10,...
%             'MarkerEdgeColor','red','MarkerFaceColor','red');
%         ylim([0.5,1.1]);
%         
%         saveas(ri,'./plot/Resilience.jpg');
%         end
%      

        % plot functionality recovery for 3 systems at different percentiles: 
        % 0, 25%, 50%, 75%, and 100%
        function PlotFigureFunctionality(time_horizon, FunctionalityStatistics)
            
            
            Functionality_Statistics_Power = FunctionalityStatistics{1};
            Functionality_Statistics_Communication = FunctionalityStatistics{2};
            Functionality_Statistics_Transportation = FunctionalityStatistics{3};
            
            lw = 2;   
            [~, name] = system('hostname');
            
            
            ps = figure('visible','off');
            idx = 3; plot([1:time_horizon], Functionality_Statistics_Power(idx,:),'b-');
            hold on, idx = 5; plot([1:time_horizon], Functionality_Statistics_Power(idx,:),'r:');
            hold on, idx = 6; plot([1:time_horizon], Functionality_Statistics_Power(idx,:),'k-','LineWidth',lw);
            hold on, idx = 7; plot([1:time_horizon], Functionality_Statistics_Power(idx,:),'r:');
            hold on, idx = 4; plot([1:time_horizon], Functionality_Statistics_Power(idx,:),'b-');
            legend('0','25%','50%','75%','100%')
            xlabel('Time (day)');
            ylabel('Power Functionality ');
            title('Power System Percentiles');
            
            cs = figure('visible','off');
            idx = 3; plot([1:time_horizon], Functionality_Statistics_Communication(idx,:),'b-');
            hold on,idx = 5; plot([1:time_horizon], Functionality_Statistics_Communication(idx,:),'r:');
            hold on, idx = 6; plot([1:time_horizon], Functionality_Statistics_Communication(idx,:),'k-','LineWidth',lw);
            hold on, idx = 7; plot([1:time_horizon], Functionality_Statistics_Communication(idx,:),'r:');
            hold on, idx = 4; plot([1:time_horizon], Functionality_Statistics_Communication(idx,:),'b-');
            legend('0','25%','50%','75%','100%')
            xlabel('Time (day)');
            ylabel('Communication Functionality ');
            title('Communication System Percentiles');
  
            ts = figure('visible','off');
            idx = 3; plot([1:time_horizon], Functionality_Statistics_Transportation(idx,:),'b-');
            hold on, idx = 5; plot([1:time_horizon], Functionality_Statistics_Transportation(idx,:),'r:');
            hold on, idx = 6; plot([1:time_horizon], Functionality_Statistics_Transportation(idx,:),'k-','LineWidth',lw);
            hold on, idx = 7; plot([1:time_horizon], Functionality_Statistics_Transportation(idx,:),'r:');
            hold on, idx = 4; plot([1:time_horizon], Functionality_Statistics_Transportation(idx,:),'b-');
            legend('0','25%','50%','75%','100%')
            xlabel('Time (day)');
            ylabel('Transportation Functionality ');
            title('Transportation System Percentiles');
            
            saveas(ps,strcat('./', deblank(name),'/plot/PowerStatistics.jpg'));
            saveas(cs,strcat('./', deblank(name),'/plot/CommunicationStatistics.jpg'));
            saveas(ts,strcat('./', deblank(name),'/plot/TransportationStatistics.jpg'));
            
        end
        
        function PlotFigureResilience(ResilienceStatistics)
            RImean = [ResilienceStatistics{1}(1), ResilienceStatistics{2}(1), ResilienceStatistics{3}(1)];
            RIstd = [ResilienceStatistics{1}(2), ResilienceStatistics{2}(2), ResilienceStatistics{3}(2)];
        
            [~, name] = system('hostname');
            ri = figure('visible','off');
            bar(1:3, RImean,...
                'FaceColor',[0 .5 .5],...
                'EdgeColor',[0 .9 .9],...
                'LineWidth',0.5);
            hold on, errorbar(1:3, RImean, RIstd,...
                '-s',... %'MarkerSize',10,...
                'MarkerEdgeColor','red','MarkerFaceColor','red');
            ylim([0,1.1]);       
            xnames = {'Power'; 'Communication'; 'Transportation'};
            set(gca,'xticklabel',xnames)
            ylabel('Resilience')
            saveas(ri,strcat('./', deblank(name), '/plot/Resilience.jpg'));

        end
        function PlotFigureFunctionalityObject(time_horizon,startTime,Qobject)
            [nsample,nrun] = size(startTime);
            tt = linspace(1,time_horizon,time_horizon);
            
            for is = 1:nsample
                for ir = 1:nrun
                    nobj = size(startTime{is,ir},1);
                    
                    
                    for iobj = 1:nobj
                        h = figure('visible','off');
                        plot(Qobject{iobj});
                        xlabel('time');
                        ylabel('Object Functionality');
                        saveas(h,sprintf('./plot/FunctionalityRecoverySamples_Object%d.jpg',iobj));
                    end
            
                end
            end
            
            
        end
        
        
        function Qobject = ComputeObjectFunctionality(time_horizon,startTime,Nsamples)
            
            [nsample,nrun] = size(startTime);
            tt = linspace(1,time_horizon,time_horizon);
            for is = 1:nsample
                for ir = 1:nrun
                    nobj = size(startTime{is,ir},1);
                    inum = (is-1)*Nsamples + ir;
                    
                    for iobj = 1:nobj
                        lbt = startTime{is,ir}{iobj,3};
                        ubt = startTime{is,ir}{iobj,4};
                        if ubt>lbt
                            x = [lbt,ubt];
                            v = [0,1];
                            xq = linspace(lbt,ubt,ubt-lbt+1);
                            Qobject{iobj}(lbt:ubt,inum) = interp1(x,v,xq)';
                            Qobject{iobj}(1:lbt-1,inum) = zeros(lbt-1,1)';                        
                            Qobject{iobj}(ubt+1:time_horizon,inum) = ones(time_horizon-ubt,1)';
                        else
                            Qobject{iobj}(1:lbt,inum) = zeros(lbt,1)'; 
                            Qobject{iobj}(ubt+1:time_horizon,inum) = ones(time_horizon-ubt,1)'; 
                        end
                    end
                    
                end
            end
            
        end
        
        function [returnPow, returnComm, returnTrans, output] = FindStartEndDays(Pow, Comm, Trans, Schedule, startDate)
%             startTimeP = [];
            
            % Field
            
            Branch = Pow{1};
            Bus = Pow{2};
            Generator = Pow{3};
            
            Antenna = Comm{1};
            Centraloffice = Comm{2};
            Router = Comm{3};
            Cellline = Comm{4};
            CommunicationTower = Comm{5};
            
            Road = Trans{1};
            Bridge = Trans{2};
            TrafficLight = Trans{3};
            
            % tem
            tem =  strsplit(Schedule,'/');
            name = tem{1};
            number = str2num(tem{2});

            if strcmp(name, 'Branch')
                Branch{number}.StartDate = startDate;
                output = {Branch{number}.Class, Branch{number}.Number, Branch{number}.StartDate, Branch{number}.StartDate+Branch{number}.WorkingDays};
            end
            
            if strcmp(name, 'Bus')
                Bus{number}.StartDate = startDate;
                output = {Bus{number}.Class, Bus{number}.Number, Bus{number}.StartDate, Bus{number}.StartDate+Bus{number}.WorkingDays};
            end
            
            if strcmp(name, 'Generator')
                Generator{number}.StartDate = startDate;
                output = {Generator{number}.Class, Generator{number}.Number, Generator{number}.StartDate, Generator{number}.StartDate+Generator{number}.WorkingDays};
            end
            
            if strcmp(name, 'Antenna')
                Antenna{number}.StartDate = startDate;
                output = {Antenna{number}.Class, Antenna{number}.Number, Antenna{number}.StartDate, Antenna{number}.StartDate+Antenna{number}.WorkingDays};
            end
            
            if strcmp(name, 'Centraloffice')
                Centraloffice{number}.StartDate = startDate;
                output = {Centraloffice{number}.Class, Centraloffice{number}.Number, Centraloffice{number}.StartDate, Centraloffice{number}.StartDate+Centraloffice{number}.WorkingDays};
            end
            
            if strcmp(name, 'Router')
                Router{number}.StartDate = startDate;
                output = {Router{number}.Class, Router{number}.Number, Router{number}.StartDate, Router{number}.StartDate+Router{number}.WorkingDays};
            end
            
            if strcmp(name, 'Cellline')
                Cellline{number}.StartDate = startDate;
                output = {Cellline{number}.Class, Cellline{number}.Number, Cellline{number}.StartDate, Cellline{number}.StartDate+Cellline{number}.WorkingDays};
            end
            
            if strcmp(name, 'CommunicationTower')
                CommunicationTower{number}.StartDate = startDate;
                output = {CommunicationTower{number}.Class, CommunicationTower{number}.Number, CommunicationTower{number}.StartDate, CommunicationTower{number}.StartDate+CommunicationTower{number}.WorkingDays};
            end
            
            if strcmp(name, 'Road')
                Road{number}.StartDate = startDate;
                output = {Road{number}.Class, Road{number}.Number, Road{number}.StartDate, Road{number}.StartDate+Road{number}.WorkingDays};
            end
            
            if strcmp(name, 'Bridge')
                Bridge{number}.StartDate = startDate;
                output = {Bridge{number}.Class, Bridge{number}.Number, Bridge{number}.StartDate, Bridge{number}.StartDate+Bridge{number}.WorkingDays};
            end
            
            if strcmp(name, 'TrafficLight')
                TrafficLight{number}.StartDate = startDate;
                output = {TrafficLight{number}.Class, TrafficLight{number}.Number, TrafficLight{number}.StartDate, TrafficLight{number}.StartDate+TrafficLight{number}.WorkingDays};
            end
            
            returnPow = Pow;
            returnComm = Comm;
            returnTrans = Trans; 
%             disp(output);
        end
             
        
        
        %%=====================================================================
        % graph theory related computations
        % V (scalar/matrix) - nodes
        % E (matrix) - edges and weight(s)
        % Graph properties at node level
        %   degree (scalar) (0,+inf)
        %   centrality (scalar) - (betweenness and closeness, etc.)[0,1]
        % Graph properties at network level:
        %   Gaveragedegree (scalar) - average value of all node degree in the network (0,+inf)
        %   L (scalar) - characteristic path length (0,+inf)
        %   EGlob (scalar) - global efficiency [0,1]
        %   CClosed (scalar) - clustering coefficient (closed neighborhood) [0,1]
        %   ELocClosed (scalar) - local efficiency (closed neighborhood) [0,1]
        %   COpen (scalar) - clustering coefficient (open neighborhood) [0,1]
        %   ELocOpen (scalar) - local efficiency (open neighborhood) [0,1]
        %%=====================================================================
        %FUNCTIONS:
        % 1.buildGraph: build Adjacency matrix and graph from V and E
        % "choice" in buildGraph: choice=1(graph) for graph with undirectional
        % edge, choice = 2(digraph) for directional edge
        % 2.computeGraphNetwork: compute graph functionality: (1) graph properties
        % related to nodes, such as degree, centrality (betweenness and
        % closeness, etc.) and (2) graph properties related to the network
        % (suing function of graphProperties ).
        % 3.removeObjectGraph: remove nodes or edges to represent the
        % damamged objects in step 2
        % 4.addObjectGraph: add nodes and edges to represent restored
        % objects in step 4
        % 5.graphProperties (): compute the following graph properties at 
        % the network level.
        % 6.subgraphs: compute adjacency matrices for each vertex in a graph
        % 7.parseInputs: a supporting function to test input as an
        % adjacency matrix or not
        %%=====================================================================
         function [G Adjacency] = buildGraph(V,E,choice)
            % G: graph
            % choice: 1=graph(undirectional), 2=digraph(directional)
            % Adjacency: adjacency matrix
            % Degree: degree of very node
            % AverageDegree: average degree 
            % Closeness
            % Betweenness
            % Distance: Shortest path distances of all node pairs
            [m,n] = size(E);
            nnode = length(unique(V));
            EdgeLength = E(:,3);
            Adjacency = zeros(nnode,nnode);    
            
            switch choice
                case 1 
                    %disp('Graph with undirected edges')
                    %% adjacency matrix
                    for ii = 1:m
                        idx1 = E(ii,1);
                        idx2 = E(ii,2);
                        Adjacency(idx1,idx2) = EdgeLength(ii);
                        Adjacency(idx2,idx1) = EdgeLength(ii);
                    end
                    
                    %% graph related computations         
                    G = graph(Adjacency);
                case 2
                    %disp('Graph with directed edges')
                    for ii = 1:m
                        idx1 = E(ii,1);
                        idx2 = E(ii,2);
                        Adjacency(idx1,idx2) = EdgeLength(ii);
                       
                    end
                    G = digraph(Adjacency);
            end   
         end
        
         function [G,Gaveragedegree,L,EGlob,CClosed,ELocClosed,COpen,ELocOpen] = computeGraphNetwork(G,Adjacency,LinkDirectionChoice)
             % G: graph
             % LinkDirectionChoice: 1=graph(undirectional), 2=digraph(directional)
             % Adjacency: adjacency matrix

            EdgeLength = G.Edges.Weight;
 
            switch LinkDirectionChoice
                case 1
                    G.Nodes.degree = degree(G);
                    G.Nodes.closeness = centrality(G,'closeness','Cost',EdgeLength);
                    G.Nodes.betweenness = centrality(G,'betweenness','Cost',EdgeLength);
                    G.Nodes.ShortestDistance = distances(G,'Method','positive');
                    
                                     
                    % system topology functionality 
                    Gaveragedegree = mean(G.Nodes.degree);
                    [L,EGlob,CClosed,ELocClosed,COpen,ELocOpen] = Library2.graphProperties(Adjacency);
                                       
                case 2
                    G.Nodes.indegree = centrality(G,'indegree');
                    G.Nodes.outdegree = centrality(G,'outdegree');
                    G.Nodes.incloseness = centrality(G,'incloseness','Cost',EdgeLength);
                    G.Nodes.outcloseness = centrality(G,'outcloseness','Cost',EdgeLength);
                    G.Nodes.betweenness = centrality(G,'betweenness','Cost',EdgeLength);
                    G.Nodes.ShortestDistance = distances(G,'Method','positive');     
                    
                    % system topology functionality 
                    Gaveragedegree = mean(G.Nodes.indegree);
                    [L,EGlob,CClosed,ELocClosed,COpen,ELocOpen] = Library2.graphProperties(Adjacency);
                                
            end
            
            
        end
        
        
        
        function H = addObjectGraph(G,choice,addNodeID, addEdgeID)
            % addNodeID: a vector of node ID to add
            % addEdgeID: a matrix of edge to add
            % addEdgeID(:,1): starting nodes of the added edges
            % addEdgeID(:,2): ending nodes of the added edges
            % addEdgeID(:,3): lengths of the added edges
            
            nadd = length(addNodeID);
            sadd = addEdgeID(:,1);
            tadd = addEdgeID(:,2); 
            wadd = addEdgeID(:,3);
            H = addnode(G,nadd);
            H = addedge(H,sadd,tadd,wadd);
            H = library.computeGraphNetwork(H,choice);
        end
        
        function H = removeObjectGraph(G,choice,removeNodeID, removeEdgeID)
            srmv = removeEdgeID(:,1);
            trmv = removeEdgeID(:,2);
            H = rmedge(G,srmv, trmv);
            H = rmnode(H,removeNodeID);
            H = library.computeGraphNetwork(H,choice); 
        end
        
        
        function [ L, EGlob, CClosed, ELocClosed, COpen, ELocOpen ] = graphProperties(varargin)
        % graphProperties: compute properties of a graph from its adjacency matrix
        % usage: [L,EGlob,CClosed,ELocClosed,COpen,ELocOpen] = graphProperties(A);
        % arguments: 
        %   A (nxn) - adjacency matrix of a graph G
        %
        %   L (scalar) - characteristic path length
        %   EGlob (scalar) - global efficiency
        %   CClosed (scalar) - clustering coefficient (closed neighborhood)
        %   ELocClosed (scalar) - local efficiency (closed neighborhood)
        %   COpen (scalar) - clustering coefficient (open neighborhood)
        %   ELocOpen (scalar) - local efficiency (open neighborhood)
        %
        % author: Nathan D. Cahill
        % email: nathan.cahill@rit.edu
        % date: 10 April 2014

        % get adjacency matrix from list of inputs
        A = Library2.parseInputs(varargin{:});

        % get number of vertices
        n = size(A,1);

        % shortest path distances between each node
        D = graphallshortestpaths(A);

        % characteristic path length
        L = sum(D(:))/(n*(n-1));

        % global efficiency
        EGlob = (sum(sum(1./(D+eye(n)))) - n)/(n*(n-1));

        % subgraphs of G induced by the neighbors of each vertex
        [MClosed,kClosed,MOpen,kOpen] = Library2.subgraphs(A);

        % local clustering coefficient in each subgraph
        [CLocClosed,CLocOpen] = deal(zeros(n,1));
            for i = 1:n
                CLocClosed(i) = sum(MClosed{i}(:))/...
                    (numel(kClosed{i})*(numel(kClosed{i})-1));
                CLocOpen(i) = sum(MOpen{i}(:))/...
                    (numel(kOpen{i})*(numel(kOpen{i})-1));
            end

        % clustering coefficients
        CClosed = mean(CLocClosed);
        COpen = mean(CLocOpen);

        % local efficiency of each subgraph
        [ELocSGClosed,ELocSGOpen] = deal(zeros(n,1));
            for i = 1:n
                % distance matrix and number of vertices for current subgraph
                DSGClosed = graphallshortestpaths(MClosed{i});
                DSGOpen = graphallshortestpaths(MOpen{i});
                nSGClosed = numel(kClosed{i});
                nSGOpen = numel(kOpen{i});
                % efficiency of current subgraph
                ELocSGClosed(i) = (sum(sum(1./(DSGClosed+eye(nSGClosed)))) - nSGClosed)/...
                    (nSGClosed*(nSGClosed-1));
                ELocSGOpen(i) = (sum(sum(1./(DSGOpen+eye(nSGOpen)))) - nSGOpen)/...
                    (nSGOpen*(nSGOpen-1));
            end

        % local efficiency of graph
        ELocClosed = mean(ELocSGClosed);
        ELocOpen = mean(ELocSGOpen);

        end

        function A = parseInputs(varargin)
        % parseInputs: test that input is an adjacency matrix
        % check number of inputs
        narginchk(1,1);
        % get first input
        A = varargin{1};

            % test to make sure A is a square matrix
            if ~isnumeric(A) || ~ismatrix(A) || size(A,1)~=size(A,2)
                error([mfilename,':ANotSquare'],'Input must be a square matrix.');
            end
            % test to make sure A only contains zeros and ones
            if any((A~=0)&(A~=1))
                error([mfilename,':ANotValid'],...
                    'Input matrix must contain only zeros and ones.');
            end
            % change A to sparse if necessary
            if ~issparse(A)
                A = sparse(A);
            end

        end

        function [MClosed,kClosed,MOpen,kOpen] = subgraphs(A)
        % subgraphs: compute adjacency matrices for each vertex in a graph
        % usage: [MClosed,kClosed,MOpen,kOpen] = subgraphs(A);
        %
        % arguments: 
        %   A - (nxn) adjacency matrix of a graph G
        %
        %   MClosed, MOpen - (nx1) cell arrays containing adjacency matrices of the 
        %       subgraphs corresponding to neighbors of each vertex. For example, 
        %       MClosed{j} is the adjacency matrix of the subgraph of G 
        %       corresponding to the closed neighborhood of the jth vertex of G, 
        %       and kClosed{j} is the list of vertices of G that are in the 
        %       subgraph (and represent the corresponding rows/columns of 
        %       MClosed{j})
        %       
        % author: Nathan D. Cahill
        % email: nathan.cahill@rit.edu
        % date: 10 Apr 2014

        % number of vertices
        n = size(A,1);

        % initialize indices of neighboring vertices, and adjacency matrices
        [kClosed,kOpen] = deal(cell(n,1));
        [MClosed,MOpen] = deal(cell(n,1));

        % loop through each vertex, determining its neighbors
            for i=1:n

                % find indices of neighbors of vertex v_i
                k1 = find(A(i,:)); % vertices with edge beginning at v_i
                k2 = find(A(:,i)); % vertices with edge ending at v_i
                kOpen{i} = union(k1,k2); % vertices in neighborhood of v_i
                kClosed{i} = union(kOpen{i},i);

                % extract submatrix describing adjacency of neighbors of v_i
                MOpen{i} = A(kOpen{i},kOpen{i});
                MClosed{i} = A(kClosed{i},kClosed{i});

            end

        end 

        
        
    end 
        
        
end    
        
        
        
        
        
        
        
        
        
        
        
        
        
        