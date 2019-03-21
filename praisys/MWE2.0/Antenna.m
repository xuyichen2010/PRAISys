classdef Antenna<SystemGeneral
    %COMMUNICATION_TOWER  
    %   Detailed explanation goes here
    
     properties (SetAccess=public)
        Location=[];
        Bus;
        Line;
        Road;
        Cellline = {};;
        Centraloffice = {};
        AntennaID;
        Company;
        Address;
    end
    
    methods
        function getStatement(AN)
            disp('----------------------------')
            disp(['Antenna:', num2str(AN.Number)])
            disp(['Status:', AN.Status])
            disp(['Type:', AN.Type])
            disp(['Location:', num2str(AN.Location)])
            disp(['WorkingDays:', num2str(AN.WorkingDays)])
            disp('----------------------------')
        end
        
%         function AN=Antenna(Number,Location, Branch,Priority)
%             AN.Number=Number;
%             AN.Location=Location;
%             AN.Branch=Branch;
%             AN.Priority=Priority;
%         end
        
        function obj=Antenna(Number,AntennaID, Location)
            if nargin == 3
                args{1} = Number;
                args{2} = 'Antenna_A';
                args{3} = 'Antenna';
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.AntennaID=AntennaID;
            obj.Location=Location;
        end

        function addCentraloffice(AN,Centraloffice)
            AN.Centraloffice=[AN.Centraloffice, Centraloffice];
          end
    end
    
end