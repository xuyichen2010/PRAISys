classdef TrafficLight<SystemGeneral &handle
    %   Bridge in Transportation System
    %   Detailed explanation goes here
    
    properties (SetAccess=public)
        Location;
        Bus;
        MapKey;
        MajorStreet;
        MinorStreet;
        Destructible = 0;
        taskUniqueIds = [];
        Battery = 0;
    end
    
    methods
        %   Constructor initializes proerty values with input arguments
%         function TL = TraficLight(Number,Location, Branch,Type,Priority)
%             TL.Number = Number;
%             TL.Location = Location;
%             TL.Branch = Branch;
%             TL.Type = Type;
%             TL.Priority=Priority;
%         end
        
        function obj = TrafficLight(Number,Location)
            if nargin == 2
                args{1} = Number;
                args{2} = 'TrafficLight_A';
                args{3} = 'TrafficLight';
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.Location = Location;
        end
        
        %   Display Selected information about the account
        function getStatement(Br)
            disp('----------------------------')
            disp(['Trafic Light:', num2str(Br.Number)])
            disp(['CurrentStatus:', Br.Status])
            disp('----------------------------')
        end
    end
end