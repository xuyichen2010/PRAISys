classdef Generator<SystemGeneral & handle
    properties (SetAccess=public)
        Location=[];
        Centraloffice;
        Bus;
        taskUniqueIds = [];
    end
    
    
    methods
        %Constructor initializes proerty values with input arguments
%         function Gen=Generator(Number, Location,Priority)
%             Gen.Number=Number;
%             Gen.Location=Location;
%             Gen.Priority=Priority;
%         end
        
        function obj=Generator(Number, Location)
            if nargin == 2
                args{1} = Number;
                args{2} = 'Generator_A';
                args{3} = 'Generator';
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.Location = Location;
        end
        
        %Display Selected information about the account
        function getStatement(Gen)
            disp('----------------------------')
            disp(['Generator:', num2str(Gen.Number)])
            disp(['CurrentStatus:', Gen.Status])
            disp(['Recovery:', num2str(Gen.Recovery)])
            disp(['DamageLevel:', num2str(Gen.DamageLevel)])
            disp('----------------------------')
        end
    end
end