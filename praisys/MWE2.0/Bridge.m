classdef Bridge<handle & SystemGeneral
    %   Bridge in Transportation System
    %   Detailed explanation goes here
    
    properties (SetAccess=public)
        Location;
        Name;
        CensusTract;
        Owner;
        PierType;
        BridgeID;
        NoOfCarryLinkID;
        CarryLinkID;
        NoOfCrossLinkID;
        CrossLinkID;
        CTY_CODE;
        FEATINT;
        DetourTime;
        DetourDistance;
        TrafficLight = [];
        Capacity;
        Branch;
        Destructible = 0;
        Width;
        MainSpans;
        AppSpans;
        MaxSpanLength;
        SkewAngle;
        Year;
        Traffic;
        Cost;
        %the following are for sub-obj
        HasSub = 0; % switch for sub-component analysis
        ColumnSet = {};
        ColumnFoundSet = {};
        AbutmentSet = {};
        AbutmentFoundSet = {};
        GirderSet = {}; % not used yet ?
        BearingSet = {};
        DeckSet = {};
        SlabSet = {};%Approach slab      
        
        taskUniqueIds = [];
        
    end
    methods
        function obj = Bridge(Number,Location,Type)
            if nargin == 3
                args{1} = Number;
                args{2} = Type;
                args{3} = 'Bridge';
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.Location = Location;
        end
        
        %   Display Selected information about the account
        function getStatement(Br)
            disp('----------------------------')
            disp(['Bridge:', num2str(Br.Number)])
            disp(['Status:', Br.Status])
            disp(['Type:', Br.Type])
            disp(['Location:', num2str(Br.Location)])
            disp(['Trafic Light:', num2str(Br.TrafficLight)])
            disp(['Priority:', num2str(Br.Priority)])
            disp(['Functionality:', num2str(Br.Functionality)])
            disp(['WorkingDays:', num2str(Br.WorkingDays)])
            disp('----------------------------')
        end
        
        %   Add information to Bridge
        function addCarr(Br,carr)
            Br.carr=[Br.carr,carr];
        end
        
        function addCros(Br,cros)
            Br.cros=[Br.cros,cros];
        end
        
        function addTrafficLightBridge(Br,TL)
            Br.TrafficLight=[Br.TrafficLight,TL];
        end
        
        
        
        function addCapacity(Br,Capacity)
            Br.Capacity = Capacity;
        end
    end
end