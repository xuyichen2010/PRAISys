classdef SystemGeneral<handle & TopObject
    properties (SetAccess=public)
        Status = 'Open';
        Priority;
        DamageLevel;
        Interdependence_Factor;
        Functionality = 1;
        Fragility = zeros(4,2);
        currentWorking;
    end
    
    methods
        function obj = SystemGeneral(varargin) %Counstructor
            p = -1;
            if nargin == 1
                args{1} = varargin{1};
            elseif nargin == 2
                args{1} = varargin{1};
                args{2} = varargin{2};
            elseif nargin == 3
                args{1} = varargin{1};
                args{2} = varargin{2};
                args{3} = varargin{3};
            elseif nargin == 4
                args{1} = varargin{1};
                args{2} = varargin{2};
                args{3} = varargin{3};
                p = varargin{4};
            end
            obj = obj@TopObject(args{:});
            if(p ~= -1)
                obj.Priority = p;
            end
        end
    end
end