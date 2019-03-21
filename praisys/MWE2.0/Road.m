classdef Road<handle & SystemGeneral
    %   Road in Transportation System
    %   Detailed explanation goes here
    
    properties (SetAccess=public)
        Start_Location;
        End_Location;
        Start_Node;
        End_Node;
        Bridge_Carr = [];
        Bridge_Cross = [];
        FreeFlow;
        AADT;
        Length;
        Speedlimit;
        TrafficLight = [];
        Capacity;
        HighwaySeg;
        SegmentCla;
        Name;
        CountyFips;
        numLanes;
        Bus;
        Branch;
        Cellline;
        taskUniqueIds = [];
    end
    
    methods
        %   Constructor initializes proerty values with input arguments
%         function Rd = Road(Number, Type, Start_Location,End_Location,Priority)
%             Rd.Number = Number;
%             Rd.Type = Type;
%             Rd.Start_Location = Start_Location;
%             Rd.End_Location = End_Location;
%             Rd.Priority=Priority;
%             switch Type
%                 case 'Road_A'
%                     Rd.Recovery = [25,4];
%                 
%                 case 'Road_B'
%                     Rd.Recovery = [18,3];
%             end
%         end

        function obj = Road(Number, Start_Location,Start_Node, End_Location,End_Node)
            if nargin == 5
                args{1} = Number;
                args{2} = 'Road_A';
                args{3} = 'Road';
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.Start_Location = Start_Location;
            obj.End_Location = End_Location;
            obj.Start_Node = Start_Node;
            obj.End_Node = End_Node;

        end
        
        %   Display Selected information about the account
        function getStatement(Rd)
            disp('----------------------------')
            disp(['Road:', num2str(Rd.Number)])
            disp(['Status:', Rd.Status])
            disp(['Type:', Rd.Type])
            disp(['Start Location:', num2str(Rd.Start_Location)]);
            disp(['End Location:', num2str(Rd.End_Location)]);
            disp(['Bridge_Carr:', num2str(Rd.Bridge_Carr)]);
            disp(['Bridge_Cross:', num2str(Rd.Bridge_Cross)]);
            disp(['TrafficLight:', num2str(Rd.TrafficLight)]);
            disp(['Priority:', num2str(Rd.Priority)]);
            disp(['Functionality:', num2str(Rd.Functionality)]);
            disp(['WorkingDays:', num2str(Rd.WorkingDays)]);
            disp('----------------------------')
        end
        
        %   Add information to Road
        function addBridgeCarr(Rd,Bridge)
            Rd.Bridge_Carr=[Rd.Bridge_Carr,Bridge];
        end
        
        function addBridgeCross(Rd,Bridge)
            Rd.Bridge_Cross=[Rd.Bridge_Cross,Bridge];
        end
        
        function addTrafficLightRoad(Rd,TL)
            Rd.TrafficLight=[Rd.TrafficLight,TL];
        end
        
        function addCapacity(Rd,Capacity)
            Rd.Capacity = Capacity;
        end
    end
end

