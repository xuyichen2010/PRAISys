classdef Bus<SystemGeneral & handle
    properties (SetAccess=public)
        Location=[];
        Name;
        Generator;
        Centraloffice;
        Capacity;
        Line_In;
        Branch = [];
        Road;
        Neighborhood = [];
        Neighborhood_Power_Link = [];
        taskUniqueIds = [];
        PopulationServed = 0;
    end
    
    
    methods
        %Constructor initializes proerty values with input arguments
%         function Bran=Branch(Number, Location, Priority)
%             Bran.Number=Number;
%             Bran.Location=Location;
%             Bran.Priority=Priority;
%         end
        
        function obj = Bus(varargin)
            if nargin == 6 ||nargin == 5
                
                args{1} = varargin{1};
                args{2} = varargin{3};
                args{3} = 'Bus';
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.Location = varargin{5};
            obj.Name = varargin{4};
            obj.Capacity = varargin{2};
            if nargin == 6
            obj.Generator = varargin{6};
            end
        end
        
        %Display Selected information about the account
        function getStatement(Bus)
            disp('----------------------------')
            disp(['Branch:', num2str(Bus.Number)])
            disp(['CurrentStatus:', Bus.Status])
            disp(['Recovery:', num2str(Bus.Recovery)])
            disp(['DamageLevel:', num2str(Bus.DamageLevel)])
            disp('----------------------------')
        end
        
        function addGenerator(Bus, Generator)
            Bus.Generator=Generator;
        end
        
        function addBus(bus, Bus)
            bus.Bus=[bus.Bus, Bus];
        end
        
    end
end