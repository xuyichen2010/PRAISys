classdef Substation<handle
    properties (SetAccess=public)
        Number
        Location=[];
        Status='open';
        Type='Substaion_A';
        Recovery=[30,5]; %[mean restoration duration, std of restoration duration]
        Childern_Node=[]; %Link Susbstation to the Transformers 
    end
    
    
    methods
        %Constructor initializes proerty values with input arguments
        function Sub=Substation(Number,Location)
            Sub.Number=Number;
            Sub.Location=Location;
        end
        %Display Selected information about the account
        function getStatement(Sub)
            disp('----------------------------')
            disp(['Susbustation:', num2str(Sub.Number)])
            disp(['CurrentStatus:', Sub.Status])
            disp('----------------------------')
        end
        function addLink(Sub,Childern_Node)
            Sub.Childern_Node=[Sub.Childern_Node,Childern_Node];
        end
    end
end
