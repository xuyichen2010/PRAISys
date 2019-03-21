classdef RoadNode<SystemGeneral
     properties (SetAccess=public)
        Location=[];
        Roads = {};
        nodeID;
        Neighborhood = [];
        Neighborhood_Trans_Link = [];
    end
    
    methods
        %Constructor initializes proerty values with input arguments
%         function Bus=Bus(Number, Start_Location, End_Location, Priority)
%             Bus.Number=Number;
%             Bus.Start_Location=[Bus.Start_Location, Start_Location];
%             Bus.End_Location=[Bus.End_Location, End_Location];
%             Bus.Priority=Priority;
%         end
        
        function obj=RoadNode(Number, Location, nodeID)
            if nargin == 3
                args{1} = Number;
                args{2} = 'RoadNode_A';
                args{3} = 'RoadNode';
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.Location = Location;
            obj.nodeID = nodeID;
        end
        
        %Display Selected information about the account
        function getStatement(RoadNode)
            disp('----------------------------')
            disp(['Bus:', num2str(RoadNode.Number)])
            disp(['CurrentStatus:', RoadNode.Status])
            disp(['Recovery:', num2str(RoadNode.Recovery)])
            disp(['DamageLevel:', num2str(RoadNode.DamageLevel)])
            disp('----------------------------')
        end       
    end
end