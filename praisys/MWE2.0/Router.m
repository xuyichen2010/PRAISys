classdef Router<handle & SystemGeneral
    properties (SetAccess=public)
        Location = [];
        Bus;
        taskUniqueIds = [];
    end
    
    methods
        %Constructor initializes proerty values with input arguments
        function obj=Router(Number, Location, Type, Priority)
            if nargin == 4
                args{1} = Number;
                args{2} = Type;
                args{3} = 'Router';
                args{4} = Priority;
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.Location=[obj.Location, Location];
        end
        
        %Display Selected information about the account
        function getStatement(Rout)
            disp('----------------------------')
            disp(['Router:', num2str(Rout.Number)])
            disp(['CurrentStatus:', Rout.Status])
            disp('----------------------------')
        end       
    end
end