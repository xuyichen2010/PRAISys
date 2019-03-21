classdef Task<handle & TopObject
    properties (SetAccess=public)
        taskType;
        taskDescription;
        taskID;
        taskSubObject;
        predecessorTask = [];
        durationMin;
        durationMax;
        durationMode;
        durationType;
        taskFunctionality;
        parentType;
        parentUniqueID;

        
    end
    
    methods
        function obj = Task(varargin) %Counstructor
                args{1} = varargin{1};
                args{2} = 'Task';
                args{3} = varargin{3};
                args{4} = 'Dummy';
            obj = obj@TopObject(args{:});
            obj.taskID = varargin{2};
            obj.durationType = varargin{4};
            obj.durationMin = varargin{5};
            obj.durationMax = varargin{6};
            obj.durationMode = varargin{7};
            obj.taskDescription = varargin{8};
            obj.taskFunctionality = varargin{9};
            obj.parentType = varargin{10};
            obj.parentUniqueID = varargin{11};
        end
    end
end