%Main file Mimimum work example Power with Communication
%% Load Input files
run('Input_Power.m');
run('Input_Communication.m');







    
%Assgin Disaster Damage 
load shakemap2.mat
%Begin Simulation
Nsamples=100;
time_horizon = 365; % time horizon for the analysis in days
Ntimesteps = 1;
Functionality_Power=zeros(Nsamples,time_horizon/Ntimesteps);
Functionality_Communication=zeros(Nsamples,time_horizon+1/Ntimesteps);
for n=1:Nsamples
%Initial Damage Evaluation:  
DisasterManager.DamageEval(Substation_Set,IM,IMx,IMy);
DisasterManager.DamageEval(Transformer_Set,IM,IMx,IMy);
DisasterManager.DamageEval(Household_Set,IM,IMx,IMy);
DisasterManager.DamageEval(Basestation_Set,IM,IMx,IMy);
Damage_list_Power=[];
Damage_list_Communication=[];
Stop_list_Power=[];
for j=1:size(Substation_Set,2)%Loop over the Substation Set
    if strcmp(Substation_Set{j}.Status,'Damaged');
        Damage_list_Power=[Damage_list_Power,Substation_Set{j}.Number];
    end
end
for j=1:size(Transformer_Set,2)%Loop over the Transformer Set
    if strcmp(Transformer_Set{j}.Status,'Damaged');
        Damage_list_Power=[Damage_list_Power,Transformer_Set{j}.Number];
    end
end
for j=1:size(Household_Set,2)%Loop over the Household Set
    if strcmp(Household_Set{j}.Status,'Damaged');
        Damage_list_Power=[Damage_list_Power,Household_Set{j}.Number];
    end
end
for j=1:size(Basestation_Set,2)%Loop over the Basestation Set
    if strcmp(Basestation_Set{j}.Status,'Damaged');
        Damage_list_Communication=[Damage_list_Communication,Basestation_Set{j}.Number];
    end
end
       
%Evaluate the situation through tree structure stop means no power source
%but is not damaged

for j=1:size(Transformer_Set,2)%Loop over the Transformer Set
   if  strcmp(Transformer_Set{j}.Status,'open');
    if ismember(Transformer_Set{j}.Parent_Node,Damage_list_Power)||ismember(Transformer_Set{j}.Parent_Node,Stop_list_Power);
         Transformer_Set{j}.Status='Stoped';
         Stop_list_Power=[Stop_list_Power,Transformer_Set{j}.Number];
    end
   end
end

for j=1:size(Household_Set,2)%Loop over the Household Set
   if  strcmp(Household_Set{j}.Status,'open');
    if ismember(Household_Set{j}.Parent_Node,Damage_list_Power)||ismember(Household_Set{j}.Parent_Node,Stop_list_Power);
        Household_Set{j}.Status='Stoped';
        Stop_list_Power=[Stop_list_Power,Household_Set{j}.Number];
    end
   end
end


%Repair Schedule
Schedule=DisasterManager.RepairSchedule(Substation_Set,Transformer_Set,Household_Set); 
%Repair Time Estimation 
%%
Restoration_Time_overall=[]; %Each element represent the time need to repair the corresponding component in Schedule
for i=1:size(Schedule,2)
   for j=1:size(Substation_Set,2)%Loop over the Substation Set
      if Schedule(i)==Substation_Set{j}.Number; %Find the Substation which needs restoration
           Restoration_Time_component=DisasterManager.RestorationTime(Substation_Set{j}); 
           Restoration_Time_overall=[Restoration_Time_overall,Restoration_Time_component];
      end
   end
    for j=1:size(Transformer_Set,2)%Loop over the Transformer Set
      if Schedule(i)==Transformer_Set{j}.Number; %Find the Substation which needs restoration
           Restoration_Time_component=DisasterManager.RestorationTime(Transformer_Set{j}); %
           Restoration_Time_overall=[Restoration_Time_overall,Restoration_Time_component];
      end
    end
    for j=1:size(Household_Set,2)%Loop over the Household Set
      if Schedule(i)==Household_Set{j}.Number; %Find the Substation which needs restoration
           Restoration_Time_component=DisasterManager.RestorationTime(Household_Set{j}); 
           Restoration_Time_overall=[Restoration_Time_overall,Restoration_Time_component];
      end
    end
   
           
end

%%
%Caculate the timeline=[retoretime(1),restoretime(1)+restoretime(2),,restoretime(1)+restoretime(2)+restoretime(3),...]
if isempty(Restoration_Time_overall)
    Restoration_Time_overall=[0];
end
Timeline=Restoration_Time_overall(1);
for i=2:size(Restoration_Time_overall,2)
    Timeline(i)=Restoration_Time_overall(i)+Timeline(i-1);
end
%%
clear Restoration_Time_component;
%%
% Calculate the functionality; 

Functionality_Communication(n,1)=DisasterManager.Functionality(Basestation_Set);
%update the compoment's staus with time
%functionality of ths power system=functional households/total households
for i=1:time_horizon
    for j=1:size(Timeline,2)
        if i==Timeline(j); %Update the status when reach the timeline 
             for k=1:size(Substation_Set,2)%Loop over the Substation Set
                 if Schedule(j)==Substation_Set{k}.Number; 
                      Substation_Set{k}.Status='open';
                      for l=1:size(Transformer_Set,2)
%if the transormer is in the stop_list and is the children node of the substation
                          if  ismember(Transformer_Set{l}.Number,Stop_list_Power)&& ismember(Transformer_Set{l}.Number,Substation_Set{k}.Childern_Node);
                              Transformer_Set{l}.Status='open';
                          end
                      end
                       
                      
                 end
             end
             for k=1:size(Transformer_Set,2)%Loop over the Transformer Set
         
                 if Schedule(j)==Transformer_Set{k}.Number; 
                      Transformer_Set{k}.Status='open';
                 end
                 if  strcmp(Transformer_Set{k}.Status,'open')
                  for l=1:size(Household_Set,2)
%if the household is in the stop_list and is the children node of the transformer              
                         if  ismember(Household_Set{l}.Number,Stop_list_Power)&& ismember(Household_Set{l}.Number,Transformer_Set{k}.Childern_Node);
                              Household_Set{l}.Status='open';
                         end
                  end
                 end
             end
             for k=1:size(Household_Set,2)%Loop over the Household Set
                 if Schedule(j)==Household_Set{k}.Number; 
                      Household_Set{k}.Status='open';
                 end
             end
        end
        
    end
    Functionality_Power(n,i)=DisasterManager.Functionality(Household_Set);
    Functionality_Communication(n,i+1)=min(1,Functionality_Communication(n,i)+0.01*Functionality_Power(n,i)); %very simplified interdependency 
end
    %Set the status back to open
     for j=1:size(Substation_Set,2)%Loop over the Substation Set
             Substation_Set{j}.Status='open'; 
 
     end
     for j=1:size(Transformer_Set,2)%Loop over the Transformer Set
             Transformer_Set{j}.Status='open';
      
 
     end
     for j=1:size(Household_Set,2)%Loop over the Household Set
             Household_Set{j}.Status='open';
     end
  
     for j=1:size(Basestation_Set,2)%Loop over the Basestation Set
             Basestation_Set{j}.Status='open';
     end
end
%Power
figure;
for i=1:Nsamples
plot([1:time_horizon], Functionality_Power(i,:));
   
  %Add text to the plot indicating repair schedule if only 1 sample 
  if Nsamples<=1
   x=0;
   y=0;
   for j=1:size(Schedule,2)
      x=Restoration_Time_overall(j)+x;
      y=Functionality_Power(x-1);
      txt=strcat('Repaired ', num2str(Schedule(j)),' Spend ',num2str(Restoration_Time_overall(j)),' days');
      text(x,y,txt);
   end
  end
hold on
end
xlabel('Time (day)');
ylabel('Power Functionality');
if Nsamples>=2
figure;
mf=mean(Functionality_Power);
plot([1:time_horizon], mf(1,:));
xlabel('Time (day)');
ylabel('mean Power Functionality mean');
end
%Comunication
figure;
for i=1:Nsamples
plot([1:time_horizon+1], Functionality_Communication(i,:));
hold on
end
xlabel('Time (day)');
ylabel('Communication Functionality');
if Nsamples>=2
figure;
mf=mean(Functionality_Communication);
plot([1:time_horizon+1], mf(1,:));
xlabel('Time (day)');
ylabel('mean Communication Functionality mean');
end
