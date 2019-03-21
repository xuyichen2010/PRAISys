classdef Household<handle
    properties (SetAccess=public)
        Number
        Location=[];
        Status='open';
        Type='Household_A';
        Recovery=[10,2]; %[mean restoration duration, std of restoration duration]
        Parent_Node=[]; %Link Households to Transformers
        
    end
    
    methods
        %Constructor initializes proerty values with input arguments
        function Hous=Household(Number,Location)
            Hous.Number=Number;
            Hous.Location=Location;
        end
        %Display Selected information about the account
        function getStatement(Hous)
            disp('----------------------------')
            disp(['Houshold:', num2str(Hous.Number)])
            disp(['CurrentStatus:', Hous.Status])
            disp('----------------------------')
        end
        function addLink(Hous,Parent_Node)
            Hous.Parent_Node=[Hous.Parent_Node,Parent_Node];
        end
    end
end