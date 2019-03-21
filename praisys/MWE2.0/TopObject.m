classdef TopObject<handle & matlab.mixin.Heterogeneous
    properties (SetAccess=public)
        Number;
        Type;
        WorkingDays;
        StartDate;
        Recovery =[10,20];
        Class;
        
        EndDate;
        Resources = [1,2,2,1];
        uniqueID;
        predecessorComponent = [];
        RecoveryMatrix = zeros(4,2);

    end
    
    methods
    function obj = TopObject(varargin) %Counstructor
        if nargin == 1
            obj.Number = varargin{1};
        elseif nargin == 2
            obj.Number = varargin{1};
            obj.Class = varargin{2};
            obj.uniqueID = strcat(obj.Class,num2str(obj.Number));
        elseif nargin == 3
            obj.Number = varargin{1};
            obj.Type = varargin{2};
            obj.Class = varargin{3};
            obj.uniqueID = strcat(obj.Class,num2str(obj.Number));
        elseif nargin == 4
            obj.Number = varargin{1};
            obj.Class = varargin{2};
            obj.Resources = varargin{3};
            obj.uniqueID = strcat(obj.Class,num2str(obj.Number));
        end
    end

    end
end