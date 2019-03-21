% Minimum working example of PRAISys
% Transportation System
%%
% load input file
run('Data_Communication.m');

% road generation
index = 1;

Road_Set = {};
Bridge_Set = {};
TraficLight_Set = {};
road_type = 0;

% Powerplant
Road_Set{1} = Road(1, 'Road_A', Branch_Set{1}.Location, Branch_Set{2}.Location,1);
Road_Set{2} = Road(2, 'Road_A', Branch_Set{2}.Location, Branch_Set{1}.Location,1);
Road_Set{3} = Road(3, 'Road_A', Branch_Set{1}.Location, Branch_Set{3}.Location,1);
Road_Set{4} = Road(4, 'Road_A', Branch_Set{3}.Location, Branch_Set{1}.Location,1);

% Substation 1
Road_Set{5} = Road(5, 'Road_A', Branch_Set{2}.Location, Branch_Set{4}.Location,1);
Road_Set{6} = Road(6, 'Road_A', Branch_Set{4}.Location, Branch_Set{2}.Location,1);
Road_Set{7} = Road(7, 'Road_A', Branch_Set{2}.Location, Branch_Set{5}.Location,1);
Road_Set{8} = Road(8, 'Road_A', Branch_Set{5}.Location, Branch_Set{2}.Location,1);
Road_Set{9} = Road(9, 'Road_A', Branch_Set{2}.Location, Branch_Set{6}.Location,1);
Road_Set{10} = Road(10, 'Road_A', Branch_Set{6}.Location, Branch_Set{2}.Location,1);
Road_Set{11} = Road(11, 'Road_A', Branch_Set{2}.Location, Antenna_Set{1}.Location,1);
Road_Set{12} = Road(12, 'Road_A', Antenna_Set{1}.Location, Branch_Set{2}.Location,1);

% Substation 2
Road_Set{13} = Road(13, 'Road_A', Branch_Set{3}.Location, Branch_Set{7}.Location,1);
Road_Set{14} = Road(14, 'Road_A', Branch_Set{7}.Location, Branch_Set{3}.Location,1);
Road_Set{15} = Road(15, 'Road_A', Branch_Set{3}.Location, Branch_Set{8}.Location,1);
Road_Set{16} = Road(16, 'Road_A', Branch_Set{8}.Location, Branch_Set{3}.Location,1);
Road_Set{17} = Road(17, 'Road_A', Branch_Set{3}.Location, Antenna_Set{2}.Location,1);
Road_Set{18} = Road(18, 'Road_A', Antenna_Set{2}.Location, Branch_Set{3}.Location,1);
Road_Set{19} = Road(19, 'Road_A', Branch_Set{3}.Location, Antenna_Set{3}.Location,1);
Road_Set{20} = Road(20, 'Road_A', Antenna_Set{3}.Location, Branch_Set{3}.Location,1);

% Transformer 1
Road_Set{21} = Road(21, 'Road_B', Branch_Set{4}.Location, Antenna_Set{1}.Location,3);
Road_Set{22} = Road(22, 'Road_B', Antenna_Set{1}.Location, Branch_Set{4}.Location,3);
Road_Set{23} = Road(23, 'Road_B', Branch_Set{4}.Location, Branch_Set{5}.Location,3);
Road_Set{24} = Road(24, 'Road_B', Branch_Set{5}.Location, Branch_Set{4}.Location,3);
Road_Set{25} = Road(25, 'Road_B', Branch_Set{4}.Location, Branch_Set{9}.Location,3);
Road_Set{26} = Road(26, 'Road_B', Branch_Set{9}.Location, Branch_Set{4}.Location,3);
Road_Set{27} = Road(27, 'Road_B', Branch_Set{4}.Location, Branch_Set{11}.Location,3);
Road_Set{28} = Road(28, 'Road_B', Branch_Set{11}.Location, Branch_Set{4}.Location,3);

% Transformer 2
Road_Set{29} = Road(29, 'Road_B', Branch_Set{5}.Location, Branch_Set{6}.Location,3);
Road_Set{30} = Road(30, 'Road_B', Branch_Set{6}.Location, Branch_Set{5}.Location,3);
Road_Set{31} = Road(31, 'Road_B', Branch_Set{5}.Location, Branch_Set{12}.Location,3);
Road_Set{32} = Road(32, 'Road_B', Branch_Set{12}.Location, Branch_Set{5}.Location,3);
Road_Set{33} = Road(33, 'Road_B', Branch_Set{5}.Location, Branch_Set{14}.Location,3);
Road_Set{34} = Road(34, 'Road_B', Branch_Set{14}.Location, Branch_Set{5}.Location,3);

% Transformer 3
Road_Set{35} = Road(35, 'Road_B', Branch_Set{6}.Location, Branch_Set{15}.Location,3);
Road_Set{36} = Road(36, 'Road_B', Branch_Set{15}.Location, Branch_Set{6}.Location,3);
Road_Set{37} = Road(37, 'Road_B', Branch_Set{6}.Location, Branch_Set{19}.Location,3);
Road_Set{38} = Road(38, 'Road_B', Branch_Set{19}.Location, Branch_Set{6}.Location,3);

% Transformer 4
Road_Set{39} = Road(39, 'Road_B', Branch_Set{7}.Location, Antenna_Set{2}.Location,3);
Road_Set{40} = Road(40, 'Road_B', Antenna_Set{2}.Location, Branch_Set{7}.Location,3);
Road_Set{41} = Road(41, 'Road_B', Branch_Set{7}.Location, Branch_Set{8}.Location,3);
Road_Set{42} = Road(42, 'Road_B', Branch_Set{8}.Location, Branch_Set{7}.Location,3);
Road_Set{43} = Road(43, 'Road_B', Branch_Set{7}.Location, Branch_Set{20}.Location,3);
Road_Set{44} = Road(44, 'Road_B', Branch_Set{20}.Location, Branch_Set{7}.Location,3);
Road_Set{45} = Road(45, 'Road_B', Branch_Set{7}.Location, Branch_Set{22}.Location,3);
Road_Set{46} = Road(46, 'Road_B', Branch_Set{22}.Location, Branch_Set{7}.Location,3);

% Transformer 5
Road_Set{47} = Road(47, 'Road_B', Branch_Set{8}.Location, Antenna_Set{3}.Location,3);
Road_Set{48} = Road(48, 'Road_B', Antenna_Set{3}.Location, Branch_Set{8}.Location,3);
Road_Set{49} = Road(49, 'Road_B', Branch_Set{8}.Location, Branch_Set{23}.Location,3);
Road_Set{50} = Road(50, 'Road_B', Branch_Set{23}.Location, Branch_Set{8}.Location,3);
Road_Set{51} = Road(51, 'Road_B', Branch_Set{8}.Location, Branch_Set{25}.Location,3);
Road_Set{52} = Road(52, 'Road_B', Branch_Set{25}.Location, Branch_Set{8}.Location,3);

% Cell Tower 1
Road_Set{53} = Road(53, 'Road_B', Antenna_Set{1}.Location, Centraloffice_Set{1}.Location,3);
Road_Set{54} = Road(54, 'Road_B', Centraloffice_Set{1}.Location, Antenna_Set{1}.Location,3);
Road_Set{55} = Road(55, 'Road_B', Antenna_Set{1}.Location, Centraloffice_Set{3}.Location,3);
Road_Set{56} = Road(56, 'Road_B', Centraloffice_Set{3}.Location, Antenna_Set{1}.Location,3);

% Cell Tower 2
Road_Set{57} = Road(57, 'Road_B', Antenna_Set{2}.Location, Centraloffice_Set{4}.Location,3);
Road_Set{58} = Road(58, 'Road_B', Centraloffice_Set{4}.Location, Antenna_Set{2}.Location,3);
Road_Set{59} = Road(59, 'Road_B', Antenna_Set{2}.Location, Centraloffice_Set{6}.Location,3);
Road_Set{60} = Road(60, 'Road_B', Centraloffice_Set{6}.Location, Antenna_Set{2}.Location,3);

% Cell Tower 3
Road_Set{61} = Road(61, 'Road_B', Antenna_Set{3}.Location, Centraloffice_Set{7}.Location,3);
Road_Set{62} = Road(62, 'Road_B', Centraloffice_Set{7}.Location, Antenna_Set{3}.Location,3);
Road_Set{63} = Road(63, 'Road_B', Antenna_Set{3}.Location, Centraloffice_Set{9}.Location,3);
Road_Set{64} = Road(64, 'Road_B', Centraloffice_Set{9}.Location, Antenna_Set{3}.Location,3);

% Household
Road_Set{65} = Road(65, 'Road_B', Branch_Set{9}.Location, Branch_Set{10}.Location,3);
Road_Set{66} = Road(66, 'Road_B', Branch_Set{10}.Location, Branch_Set{9}.Location,3);

Road_Set{67} = Road(67, 'Road_B', Branch_Set{10}.Location, Branch_Set{11}.Location,3);
Road_Set{68} = Road(68, 'Road_B', Branch_Set{11}.Location, Branch_Set{10}.Location,3);

Road_Set{69} = Road(69, 'Road_B', Branch_Set{12}.Location, Branch_Set{13}.Location,3);
Road_Set{70} = Road(70, 'Road_B', Branch_Set{13}.Location, Branch_Set{12}.Location,3);

Road_Set{71} = Road(71, 'Road_B', Branch_Set{13}.Location, Branch_Set{14}.Location,3);
Road_Set{72} = Road(72, 'Road_B', Branch_Set{14}.Location, Branch_Set{13}.Location,3);

Road_Set{73} = Road(73, 'Road_B', Branch_Set{15}.Location, Branch_Set{16}.Location,3);
Road_Set{74} = Road(74, 'Road_B', Branch_Set{16}.Location, Branch_Set{15}.Location,3);

Road_Set{75} = Road(75, 'Road_B', Branch_Set{16}.Location, Branch_Set{17}.Location,3);
Road_Set{76} = Road(76, 'Road_B', Branch_Set{17}.Location, Branch_Set{16}.Location,3);

Road_Set{77} = Road(77, 'Road_B', Branch_Set{17}.Location, Branch_Set{18}.Location,3);
Road_Set{78} = Road(78, 'Road_B', Branch_Set{18}.Location, Branch_Set{17}.Location,3);

Road_Set{79} = Road(79, 'Road_B', Branch_Set{18}.Location, Branch_Set{19}.Location,3);
Road_Set{80} = Road(80, 'Road_B', Branch_Set{19}.Location, Branch_Set{18}.Location,3);

Road_Set{81} = Road(81, 'Road_B', Branch_Set{20}.Location, Branch_Set{21}.Location,3);
Road_Set{82} = Road(82, 'Road_B', Branch_Set{21}.Location, Branch_Set{20}.Location,3);

Road_Set{83} = Road(83, 'Road_B', Branch_Set{21}.Location, Branch_Set{22}.Location,3);
Road_Set{84} = Road(84, 'Road_B', Branch_Set{22}.Location, Branch_Set{21}.Location,3);

Road_Set{85} = Road(85, 'Road_B', Branch_Set{23}.Location, Branch_Set{24}.Location,3);
Road_Set{86} = Road(86, 'Road_B', Branch_Set{24}.Location, Branch_Set{23}.Location,3);

Road_Set{87} = Road(87, 'Road_B', Branch_Set{24}.Location, Branch_Set{25}.Location,3);
Road_Set{88} = Road(88, 'Road_B', Branch_Set{25}.Location, Branch_Set{24}.Location,3);

% Central Office
Road_Set{89} = Road(89, 'Road_B', Centraloffice_Set{1}.Location, Centraloffice_Set{2}.Location,3);
Road_Set{90} = Road(90, 'Road_B', Centraloffice_Set{2}.Location, Centraloffice_Set{1}.Location,3);

Road_Set{91} = Road(91, 'Road_B', Centraloffice_Set{2}.Location, Centraloffice_Set{3}.Location,3);
Road_Set{92} = Road(92, 'Road_B', Centraloffice_Set{3}.Location, Centraloffice_Set{2}.Location,3);

Road_Set{93} = Road(93, 'Road_B', Centraloffice_Set{4}.Location, Centraloffice_Set{5}.Location,3);
Road_Set{94} = Road(94, 'Road_B', Centraloffice_Set{5}.Location, Centraloffice_Set{4}.Location,3);

Road_Set{95} = Road(95, 'Road_B', Centraloffice_Set{5}.Location, Centraloffice_Set{6}.Location,3);
Road_Set{96} = Road(96, 'Road_B', Centraloffice_Set{6}.Location, Centraloffice_Set{5}.Location,3);

Road_Set{97} = Road(97, 'Road_B', Centraloffice_Set{7}.Location, Centraloffice_Set{8}.Location,3);
Road_Set{98} = Road(98, 'Road_B', Centraloffice_Set{8}.Location, Centraloffice_Set{7}.Location,3);

Road_Set{99} = Road(99, 'Road_B', Centraloffice_Set{8}.Location, Centraloffice_Set{9}.Location,3);
Road_Set{100} = Road(100, 'Road_B', Centraloffice_Set{9}.Location, Centraloffice_Set{8}.Location,3);

index = 100;
index_bridge = 1;

% bridge generation
for i = 1:20
    j = randi(index);
    start_location = Road_Set{j}.Start_Location;
    end_location = Road_Set{j}.End_Location;
    
    if end_location(1) ~= start_location(1)
        slope = (end_location(2) - start_location(2))/(end_location(1) - start_location(1));
        intersection = end_location(2) - end_location(1) * slope;
        
        difference = start_location(1) - end_location(1);
        if difference > 0
            location_x = start_location(1) - randi(abs(difference));
        else
            location_x = start_location(1) + randi(abs(difference));
        end
        location_y = round(location_x * slope + intersection, 0);
    else
        location_x = start_location(1);
        difference = start_location(2) - end_location(2);
        
        if difference > 0
            location_y = start_location(2) - randi(abs(difference));
        else
            location_y = start_location(2) + randi(abs(difference));
        end
    end
    
    if strcmp(Road_Set{j}.Type, 'Road_A')
        Bridge_Set{i} = Bridge(index_bridge, [location_x location_y], 'Bridge_A',2);
    else
        Bridge_Set{i} = Bridge(index_bridge, [location_x location_y], 'Bridge_B',4);
    end
    
    addBridgeCarr(Road_Set{j}, i);
    index_bridge = index_bridge + 1;
end

index_bridge = index_bridge - 1;
index_TL = 1;

% trafic light generation
% road trafic light
for i = 1:80
    if i <= 70
        j = i;
        start_location = Road_Set{j}.Start_Location;
        end_location = Road_Set{j}.End_Location;
        if end_location(1) ~= start_location(1)
            slope = (end_location(2) - start_location(2))/(end_location(1) - start_location(1));
            intersection = end_location(2) - end_location(1) * slope;
            
            difference = start_location(1) - end_location(1);
            if difference > 0
                location_x = start_location(1) - randi(abs(difference));
            else
                location_x = start_location(1) + randi(abs(difference));
            end
            location_y = round(location_x * slope + intersection, 0);
        else
            location_x = start_location(1);
            difference = start_location(2) - end_location(2);
            
            if difference > 0
                location_y = start_location(2) - randi(abs(difference));
            else
                location_y = start_location(2) + randi(abs(difference));
            end
        end
        
        TraficLight_Set{i} = TraficLight(index_TL, [location_x location_y], randi(length(Branch_Set)), 'TL_A',5);
        addTraficLightRoad(Road_Set{i}, TraficLight_Set{i}.Number);
        index_TL = index_TL + 1;
    else
        j = randi(length(Road_Set));
        start_location = Road_Set{j}.Start_Location;
        end_location = Road_Set{j}.End_Location;
        if end_location(1) ~= start_location(1)
            slope = (end_location(2) - start_location(2))/(end_location(1) - start_location(1));
            intersection = end_location(2) - end_location(1) * slope;
            
            difference = start_location(1) - end_location(1);
            if difference > 0
                location_x = start_location(1) - randi(abs(difference));
            else
                location_x = start_location(1) + randi(abs(difference));
            end
            location_y = round(location_x * slope + intersection, 0);
        else
            location_x = start_location(1);
            difference = start_location(2) - end_location(2);
            
            if difference > 0
                location_y = start_location(2) - randi(abs(difference));
            else
                location_y = start_location(2) + randi(abs(difference));
            end
        end
        
        TraficLight_Set{i} = TraficLight(index_TL, [location_x location_y], randi(length(Branch_Set)), 'TL_A',4);
        addTraficLightRoad(Road_Set{j}, TraficLight_Set{i}.Number);
        index_TL = index_TL + 1;
    end
end

% bridge trafic light
for i = index_TL:index_TL + 9
    j = randi(length(Bridge_Set));
    location_x = Bridge_Set{j}.Location(1);
    location_y = Bridge_Set{j}.Location(2);
    
    TraficLight_Set{i} = TraficLight(i, [location_x location_y], randi(length(Branch_Set)), 'TL_A',4);
    addTrafficLightBridge(Bridge_Set{j}, TraficLight_Set{i}.Number);
end

clear index road_type index_bridge index_TL intersection location_x location_y slope end_location start_location i j difference;
%%