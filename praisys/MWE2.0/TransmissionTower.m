classdef TransmissionTower<SystemGeneral & handle
    properties (SetAccess=public)
        Location=[];
        Branch;
        taskUniqueIds = [];
    end
    
    
    methods
        %Constructor initializes proerty values with input arguments
%         function Bran=Branch(Number, Location, Priority)
%             Bran.Number=Number;
%             Bran.Location=Location;
%             Bran.Priority=Priority;
%         end
        
        function obj = TransmissionTower(varargin)
            if nargin == 2
                
                args{1} = varargin{1};
                args{2} = 'TypeR';
                args{3} = 'TransmissionTower';
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.Location = varargin{2};
        end
        

        
    end
end