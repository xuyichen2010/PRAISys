classdef Deck<SystemGeneral & handle
    properties (SetAccess=public)
        Location=[];
        Name;
        taskUniqueIds = [];
    end
    
    
    methods
        %Constructor initializes proerty values with input arguments
%         function Bran=Branch(Number, Location, Priority)
%             Bran.Number=Number;
%             Bran.Location=Location;
%             Bran.Priority=Priority;
%         end
        
        function obj = Deck(Number,Location)
            if nargin == 2
                args{1} = Number;
                args{2} = "Deck"
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.Location = Location;
        end
        
        %Display Selected information about the account
        function getStatement(cl)
            disp('----------------------------')
            disp(['CurrentStatus:', cl.Status])
            disp(['Recovery:', num2str(cl.Recovery)])
            disp(['DamageLevel:', num2str(cl.DamageLevel)])
            disp('----------------------------')
        end
        

        
    end
end