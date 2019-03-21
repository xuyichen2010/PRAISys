classdef Neighborhood_General_Link<SystemGeneral
    properties (SetAccess=public)
        Neighbor_Location=[];
        End_Location=[];
        Neighborhood;
        Length;
    end
    
    methods
        function obj=Neighborhood_General_Link(Number, Neighbor_Location, End_Location, neighborhood, class)
            if nargin == 5
                args{1} = Number;
                args{2} = 'A';
                args{3} = class;
            else
            end
            obj = obj@SystemGeneral(args{:});
            obj.Neighbor_Location= Neighbor_Location;
            obj.End_Location= End_Location;
            obj.Neighborhood = neighborhood;
            obj.Length = sqrt((Neighbor_Location(1) - End_Location(1))^2 + (Neighbor_Location(2) - End_Location(2))^2);
            
        end
    end
end