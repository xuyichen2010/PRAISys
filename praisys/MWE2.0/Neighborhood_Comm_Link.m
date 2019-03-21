classdef Neighborhood_Comm_Link<Neighborhood_General_Link
    properties (SetAccess=public)
        CentralTower;
    end
    
    methods
        function obj=Neighborhood_Comm_Link(Number, Start_Location, End_Location, Neighborhood, CentralTower)
            if nargin == 5
                args{1} = Number;
                args{2} = Start_Location;
                args{3} = End_Location;
                args{4} = Neighborhood;
                args{5} = 'Neighborhood_Comm_Link';
            else
            end
            obj = obj@Neighborhood_General_Link(args{:});
            obj.CentralTower = CentralTower;
        end
    end
end