% Minimum working example of PRAISys
% Input file for power system

%%          Input characteristics the nodes of the network               %%

% SP.nodes(in, :) = characterics of node in
% SP.nodes(: , 1) = x position 
% SP.nodes(: , 2) = y position
% (we have also a subtoutine to convert from % latitude and longitude to x and y, if needed)


xy = [  2 0
        1 1
        0 2
        3 0
        3 1
        3 2
        4 0
        5 1
        6 2];

SP.nodes = [xy];
clear xy

%%          Input characteristics the links of the network               %%
     
% SP.links(il, :) = characterics of link il
% SP.links(: , 1) = origin node
% SP.links(: , 2) = destination node
% SP.links(: , 3) = length

OD=[1 2
    2 3
    4 5
    5 6
    7 8
    8 9
    1 4
    4 7
    2 5
    5 8
    3 6
    6 9];
OD2(1:2:24,:)=OD;
OD2(2:2:24,1)=OD(:,2);
OD2(2:2:24,2)=OD(:,1);
    
SP.links = [OD2];
clear OD OD2

%%         Input characteristics the transmission towers                 %%

% CTT.*(it, :) = characterics of transmission tower it
% CTT.n(: , 1:end) = name or code
% CTT.xy(: , 1:2) = x and y location of the tower
% CTT.class(: , 1:end) = class of the component, for functionaity fragility
            
CTT.n={ 'A1'
        'B2'
        'C3'
        'D4'
        'E5'
        'F6'
        'G7'
        'H8'};
			
CTT.xy = [ 1 2
           0 3
           2 4
           3 3
           6 3
           2 0
           1.5 3
           0.2 1.2]*0.9;
       
CTT.class = [ 1 
              4
              4
              1
              4 
              4
              3
              2];

%% Input characteristics the traffic lights

% CTL.*(it, :) = characterics of traffic light it
% CTL.n(: , 1:end) = name or code
% CTL.xy(: , 1:2) = x and y location of the traffic light
% CTL.class(: , 1:end) = class of the component
            
CTL.n={ 'A1'
        'B2'};
			
CTL.xy = [ 1.2 2.5
           0.6 3.5]*0.9;
       
CTL.class = [ 1 
              1];

