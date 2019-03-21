classdef Neighborhood_Trans_Link<Neighborhood_General_Link
    properties (SetAccess=public)
        RoadNode;
    end
    
    methods
        function obj=Neighborhood_Trans_Link(Number, Start_Location, End_Location, Neighborhood, RoadNode)
            if nargin == 5
                args{1} = Number;
                args{2} = Start_Location;
                args{3} = End_Location;
                args{4} = Neighborhood;
                args{5} = 'Neighborhood_Trans_Link';
            else
            end
            obj = obj@Neighborhood_General_Link(args{:});
            obj.RoadNode = RoadNode;
        end
    end
end