classdef Neighborhood_Power_Link<Neighborhood_General_Link
    properties (SetAccess=public)
        Bus;
    end
    
    methods
        function obj=Neighborhood_Power_Link(Number, Start_Location, End_Location, Neighborhood, Bus)
            if nargin == 5
                args{1} = Number;
                args{2} = Start_Location;
                args{3} = End_Location;
                args{4} = Neighborhood;
                args{5} = 'Neighborhood_Power_Link';
            else
            end
            obj = obj@Neighborhood_General_Link(args{:});
            obj.Bus = Bus;
        end
    end
end