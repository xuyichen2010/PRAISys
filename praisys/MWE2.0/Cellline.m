classdef Cellline<SystemGeneral & handle
    properties (SetAccess=public)
        Start_Location=[];
        End_Location=[];
        Capacity;
        connectedObj1;
        connectedObj2;
        Bus;
        taskUniqueIds = [];
    end
    
    methods
        %Constructor initializes proerty values with input arguments
%         function Bus=Bus(Number, Start_Location, End_Location, Priority)
%             Bus.Number=Number;
%             Bus.Start_Location=[Bus.Start_Location, Start_Location];
%             Bus.End_Location=[Bus.End_Location, End_Location];
%             Bus.Priority=Priority;
%         end
        
        function obj=Cellline(Number, Start_Location, End_Location, obj1, obj2)
            if nargin == 5
                args{1} = Number;
                args{2} = 'Cellline_A';
                args{3} = 'Cellline';
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.Start_Location=[obj.Start_Location, Start_Location];
            obj.End_Location=[obj.End_Location, End_Location];
            obj.connectedObj1 = obj1;
            obj.connectedObj2 = obj2;
            
        end
        
        %Display Selected information about the account
        function getStatement(Cellline)
            disp('----------------------------')
            disp(['Bus:', num2str(Cellline.Number)])
            disp(['CurrentStatus:', Cellline.Status])
            disp(['Recovery:', num2str(Cellline.Recovery)])
            disp(['DamageLevel:', num2str(Cellline.DamageLevel)])
            disp('----------------------------')
        end       
    end
end