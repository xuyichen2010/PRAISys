classdef BridgeAggregate<handle & SystemGeneral
    %   Bridge in Transportation System
    %   Detailed explanation goes here
    
    properties (SetAccess=public)
        Location;
        Name;
        CensusTract;
        Owner;
        PierType;
        BridgeID;
        DetourTime;
        DetourDistance;
        TraficLight = [];
        Capacity;
        Branch;
        Antenna;
        Destructible = 0;
        Width;
        NumSpans;
        MaxSpanLength;
        SkewAngle;
        Year;
        Traffic;
        Cost;
        
        Tasks = [];
    end
    
    methods
        
        function obj = BridgeAggregate(Number,Location,Type)
            if nargin == 3
                args{1} = Number;
                args{2} = Type;
                args{3} = 'Bridge';
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.Location = Location;
            
        end
       
        
        %   Add information to Bridge
        function addCarr(Br,carr)
            Br.carr=[Br.carr,carr];
        end
        
        function addCros(Br,cros)
            Br.cros=[Br.cros,cros];
        end
        
        function addTrafficLightBridge(Br,TL)
            Br.TraficLight=[Br.TraficLight,TL];
        end
        
        function addCapacity(Br,Capacity)
            Br.Capacity = Capacity;
        end
    end
end