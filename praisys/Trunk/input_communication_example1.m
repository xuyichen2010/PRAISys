% Minimum working example of PRAISys
% Input file for power system

%%%          Input characteristics the nodes of the network               %%

% SC.nodes(in, :) = characterics of node in
% SC.nodes(: , 1) = x position 
% SC.nodes(: , 2) = y position
% (we have also a subtoutine to convert from % latitude and longitude to x and y, if needed)


xy = [  2 0
        1 1
        0 2];

SC.nodes = [xy];
clear xy

%%%          Input characteristics the links of the network               %%
     
% SC.links(il, :) = characterics of link il
% SC.links(: , 1) = origin node
% SC.links(: , 2) = destination node
% SC.links(: , 3) = length

OD=[1 2
    2 3
    3 1];
OD2(1:2:6,:)=OD;
OD2(2:2:6,1)=OD(:,2);
OD2(2:2:6,2)=OD(:,1);
    
SC.links = [OD2];
clear OD OD2

%%%         Input characteristics the transmission towers                 %%

% CTT.*(it, :) = characterics of transmission tower it
% CTT.n(: , 1:end) = name or code
% CTT.xy(: , 1:2) = x and y location of the tower
% CTT.class(: , 1:end) = class of the component, for functionaity fragility
            
CTT.n={ 'A1'
        'B2'
        'C3' };
			
CTT.xy = [ 1 2
           0 3
           2 4]*0.9;
       
CTT.class = [ 1 
              2
              1];



