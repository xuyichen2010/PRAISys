%Minimum working example of PRAISys
%Communication Sytstem

%%   Input charactersitcs 
%Graph Display
%                   
%         
%        Transformer2         Transformer3           Transformer4
%          |                     |                     |
% ------------------             -                   ------
% |   |        |   |             |                   |    |          
% BS1 BS2     BS3  BS4         BS5                   BS6 BS7 

%Assumption is that the recvoery of BS recovers 0.1% depend on the
%functioanlity of the power system

%
%BS stantds for Base Station

Basestation_Set={};

Num.Basestation=7;


xy=[ 1 3  %BS1
     4 2  %BS2
     2 5  %BS3
     6 7  %BS4
     2 4  %BS5
     1 6  %BS6
     9 3  %BS7
     ];
for i=1:Num.Basestation
    Basestation_Set{i}=Basestation(i,xy(i,:));
end
addPower(Basestation_Set{1},2);
addPower(Basestation_Set{2},2);
addPower(Basestation_Set{3},2);
addPower(Basestation_Set{4},2);
addPower(Basestation_Set{5},3);
addPower(Basestation_Set{6},4);
addPower(Basestation_Set{7},4);
