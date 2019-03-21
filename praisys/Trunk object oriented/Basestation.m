classdef Basestation<handle
    %COMMUNICATION_TOWER  
    %   Detailed explanation goes here
    
     properties (SetAccess=public)
        Number
        Location=[];
        Status='open';
        Type='Basestation_A';
        %Recovery=[40,10]; %[mean restoration duration, std of restoration duration]
        PowerInput; %Link Communication Tower to Transformers
       
    end
    
    methods
          function Base=Basestation(Number,Location)
            Base.Number=Number;
            Base.Location=Location;
          end
          function addPower(Base,Transformer_Num)
           Base.PowerInput=Transformer_Num;
          end
    end
    
end

