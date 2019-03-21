classdef Branch<SystemGeneral & handle
    properties (SetAccess=public)
        Start_Location=[];
        End_Location=[];
        Capacity;
        Bus;
        connectedObj1;
        connectedObj2;
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
        
        function obj=Branch(Number, Start_Location, End_Location, Capacity, Type, Priority, obj1, obj2)
            if nargin == 8
                args{1} = Number;
                args{2} = Type;
                args{3} = 'Branch';
                args{4} = Priority;
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.Start_Location=[obj.Start_Location, Start_Location];
            obj.End_Location=[obj.End_Location, End_Location];
            obj.Capacity = Capacity;
            obj.connectedObj1 = obj1;
            obj.connectedObj2 = obj2;
            
        end
        
        %Display Selected information about the account
        function getStatement(Branch)
            disp('----------------------------')
            disp(['Bus:', num2str(Branch.Number)])
            disp(['CurrentStatus:', Branch.Status])
            disp(['Recovery:', num2str(Branch.Recovery)])
            disp(['DamageLevel:', num2str(Branch.DamageLevel)])
            disp('----------------------------')
        end       
    end
end