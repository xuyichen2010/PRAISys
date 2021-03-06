% Minimum working example of PRAISys
% Input file for transportation system

%%          Input characteristics the nodes of the network               %%

% ST.nodes(in, :) = characterics of node in
% ST.nodes(: , 1) = x position 
% ST.nodes(: , 2) = y position
% (we have also a subtoutine to convert from % latitude and longitude to x and y, if needed)
% ST.nodes(: , 3) = number of travels generated by node in
% ST.nodes(: , 4) = number of travels attracted by node in

xy = [  2 0
        1 1
        0 2
        3 0
        3 1
        3 2
        4 0
        5 1
        6 2];

O=[ 2 1 2 ...
    1 1 1 ...
    2 1 2]*5000;
D=O;

ST.nodes = [xy,O',D'];
clear xy  O D

%%          Input characteristics the links of the network               %%
     
% ST.links(il, :) = characterics of link il
% ST.links(: , 1) = origin node
% ST.links(: , 2) = destination node
% ST.links(: , 3) = travel time at free flow [min] = distance[mi] / 60[mph] * 60[min/h]
% ST.links(: , 4) = practical capacity (capacity of link per unit of time)
% ST.links(: , 5) = length

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

distance=sqrt((ST.nodes(OD2(:,1),1)-ST.nodes(OD2(:,2),1)).^2+...
              (ST.nodes(OD2(:,1),2)-ST.nodes(OD2(:,2),2)).^2); %miles        
        
ST.links = [OD2 distance ones(24,1)*4000 distance];
clear OD OD2 distance

%%         Input characteristics the bridges of the network              %%

% CBr.*(ib, :) = characterics of bridge ib
% CBr.n(: , 1:end) = name or code
% CBr.xy(: , 1:2) = x and y location of the bridge
% CBr.carr(: , 1:end) = links carried by the bridge
% CBr.cros(: , 1:end) = links crossed by the bridge
% CBr.class(: , 1) = class of the component, for functionaity fragility
% CBr.wp(:,1) = work progress status (0=recovery not in progress 1=recovery in progress) 
% CBr.cd(: , 1) = basic detour time
% CBr.dd(: , 1) = basic detour distance
% CBr.fd(: , 1) = detour practical capacity

%== For more information refere to:

%==> Bocchini, P. and Frangopol, D. M. (2011b). A stochastic computational 
% framework for the joint transportation network fragility analysis and traffic distribution
% under extreme events. Probabilistic Engineering Mechanics, 26(2):182{193.
%==> Bocchini, P. and Frangopol, D. M. (2012). Restoration of bridge
% networks after an earthquake: Multicriteria intervention optimization. 
% Earthquake Spectra, 28(2):426-455.
            
CBr.n={  'A'
        'B'
        'C'
        'D'
        'E'
        'F'
        'G'
        'H'};

CBr.xy = [ 1 2
           0 3
           2 4
           3 3
           6 3
           2 0
           1.5 3
           0.2 1.2];

CBr.carr = [ 1  2   %A
            3  4   %B
            5  6   %C
            7  8   %D
            9 10   %E
           11 12   %F
           21 22   %G
           23 24]; %H
CBr.cros = zeros(8,1);

CBr.class = [ 1 
              4
              4
              1
              4 
              4
              3
              2];
            
CBr.wp = [  0
           0
           0
           0
           0
           0
           1
           0];
			
			
% Detour time [minutes] = Detour length [km] from NBI / 40 [km/h] * 60 [minutes/h]        
CBr.cd=[ 1 
        1
        1
        1
        1
        1
        1
        1]/40*60;
  
% Detour length [mi] = Detour time [minutes] / 60 [minutes/h] * 40 [km/h] *0.621371192 [mi/km]        
CBr.dd=CBr.cd/60*40*0.621371192;     

CBr.fd=ones(size(CBr.class))*1500;

CBr.trafficlights= [  2 %means that in bridge #1 there is traffic light #2
                      0 %means that in bridge #2 there is no traffic light
                      0
                      0
                      0
                      0
                      1 %means that in bridge #7 there is traffic light #1
                      0];
