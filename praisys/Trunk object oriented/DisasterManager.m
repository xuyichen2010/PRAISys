classdef DisasterManager
 methods(Static)
     function DamageEval(cell,IM,IMx,IMy) %assign the intensity to the compoments
       
         switch cell{1}.Type 
             case 'Substaion_A'
                 for i=1:size(cell,2)
                      Intensity=interp2(IMx,IMy,IM,cell{i}.Location(1),cell{i}.Location(2));
                      Prob_Failure=Intensity; %assign probabilty of failure we can improve it later
                      if rand<Prob_Failure
                          cell{i}.Status='Damaged';
                      end
                
                          
                 end
                 case 'Transformer_A'
                 for i=1:size(cell,2)
                      Intensity=interp2(IMx,IMy,IM,cell{i}.Location(1),cell{i}.Location(2));
                      Prob_Failure=Intensity/2; %assign probabilty of failure we can improve it later
                      if rand<Prob_Failure;
                          cell{i}.Status='Damaged';
                      end
                    
                
                          
                 end
                 case 'Household_A'
                 for i=1:size(cell,2)
                      Intensity=interp2(IMx,IMy,IM,cell{i}.Location(1),cell{i}.Location(2));
                      Prob_Failure=Intensity/2; %assign probabilty of failure we can improve it later
                      if rand<Prob_Failure
                          cell{i}.Status='Damaged';
                      end
                
                          
                 end
                 case 'Basestation_A'
                 for i=1:size(cell,2)
                      Intensity=interp2(IMx,IMy,IM,cell{i}.Location(1),cell{i}.Location(2));
                      Prob_Failure=Intensity; %assign probabilty of failure we can improve it later
                      if rand<Prob_Failure
                          cell{i}.Status='Damaged';
                      end
                
                          
                 end
                 case 'Switch_A'
                 for i=1:size(cell,2)
                      Intensity=interp2(IMx,IMy,IM,cell{i}.Location(1),cell{i}.Location(2));
                      Prob_Failure=Intensity/2; %assign probabilty of failure we can improve it later
                      if rand<Prob_Failure
                          cell{i}.Status='Damaged';
                      end
                
                          
                 end
         end
         
     end
    
     function Schedule=RepairSchedule(Sub_Set,Tran_Set,Hous_Set) 
     %Assume 1 repair team meaning fix one compoment a time,
     %prioirty:Substation>Transformer>Household
     %Among Transformers the one has the more households get fixed first
     %The code here is just applicable to this example case
         Schedule=[];
         if strcmp(Sub_Set{1}.Status,'Damaged')
                 Schedule=[Schedule,Sub_Set{1}.Number];
         end
         if strcmp(Tran_Set{3}.Status,'Damaged') %since Transformer node 4 has more households connected
                 Schedule=[Schedule,Tran_Set{3}.Number];
         end
         if strcmp(Tran_Set{2}.Status,'Damaged') 
                 Schedule=[Schedule,Tran_Set{2}.Number];
         end
         if strcmp(Tran_Set{1}.Status,'Damaged')
                 Schedule=[Schedule,Tran_Set{1}.Number];
         end
         for i=1:size(Hous_Set,2)
             if strcmp(Hous_Set{i}.Status,'Damaged')
                 Schedule=[Schedule,Hous_Set{i}.Number];
             end
         end
         
     end
     
     function Time_Component=RestorationTime(Component)
       m=Component.Recovery(1);
       v=Component.Recovery(2);
       mu = log((m^2)/sqrt(v+m^2));
       sigma = sqrt(log(v/(m^2)+1));
       Time_Component=round(lognrnd(mu,sigma));
     end
     
     function Function=Functionality(Hous_Set)
         Num_Hous=size(Hous_Set,2);
         Num_Hous_open=0;
         for i=1: Num_Hous
             if strcmp(Hous_Set{i}.Status,'open')
                 Num_Hous_open=Num_Hous_open+1;
             end
         end
         Function=Num_Hous_open/Num_Hous;
     end
         
                 
         

         
                 
                 
                 
                 
                 
         
         
     
     
     
     
 end
end
 
                 
    
     
             
             
             
