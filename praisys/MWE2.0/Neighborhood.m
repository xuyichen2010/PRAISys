classdef Neighborhood<SystemGeneral
    properties (SetAccess=public)
        Location=[];
        Bus;
        RoadNode;
        Centraloffice;
        Neighborhood_Power_Link;
        Neighborhood_Trans_Link;
        Neighborhood_Comm_Link;
        Name;
        County;
        Population;
        Density;
        TreeCoverPercent;
        TreeCoverM2perPerson;
        PowerStatus =  1;
        CommStatus = 1;
        TransStatus = 1;
    end
    
    methods
        function obj=Neighborhood(Number, Location, Name, County, Population, Density,TreeCoverPercent,TreeCoverM2perPerson)
            if nargin == 8
                args{1} = Number;
                args{2} = 'Neighborhood_A';
                args{3} = 'Neighborhood';
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.Location=Location;
            obj.Name = Name;
            obj.County = County;
            obj.Population = Population;
            obj.Density = Density;
            obj.TreeCoverPercent = TreeCoverPercent;
            obj.TreeCoverM2perPerson = TreeCoverM2perPerson;
        end
    end
    
end