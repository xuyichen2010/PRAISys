classdef Transformer<handle
    properties (SetAccess=public)
        Number
        Location=[];
        Status='open';
        Type='Transformer_A';
        Recovery=[15,5]; %[mean restoration duration, std of restoration duration]
        Parent_Node=[]; %Link Transformers to Substations
        Childern_Node=[]; %Link Transformers to the Households
    end
    
    methods
        %Constructor initializes proerty values with input arguments
        function Tran=Transformer(Number,Location)
            Tran.Number=Number;
            Tran.Location=Location;
        end
        %Display Selected information about the account
        function getStatement(Tran)
            disp('----------------------------')
            disp(['Transformer:', num2str(Tran.Number)])
            disp(['CurrentStatus:', Tran.Status])
            disp('----------------------------')
        end
        function addLink(Tran,Parent_Node,Childern_Node)
            Tran.Parent_Node=[Tran.Parent_Node,Parent_Node];
            Tran.Childern_Node=[Tran.Childern_Node,Childern_Node];
        end
    end
end