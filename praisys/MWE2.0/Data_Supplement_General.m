% Minimum working example of PRAISys
% Component Properity Change
%%

% load input file
run('Data_Transportation.m');

% Power
for i = 1:length(Branch_Set)
    number = randi(length(Centraloffice_Set));
    Branch_Set{i}.Centraloffice = number;
    if ~isempty(Branch_Set{i}.Generator)
        Generator_Set{Branch_Set{i}.Generator}.Centraloffice = number;
    end
end

for i = 1:length(Branch_Set)
    for j = 1:length(Road_Set)
        if Branch_Set{i}.Location == Road_Set{j}.End_Location
            Branch_Set{i}.Road = [Branch_Set{i}.Road, j];
        end
    end
end

for i = 1:length(Branch_Set)
    for j = 1:length(Bus_Set)
        if Branch_Set{i}.Location == Bus_Set{j}.End_Location
            Branch_Set{i}.Line_In = [Branch_Set{i}.Line_In, j];
        end
    end
end

for i = 1:length(Bus_Set)
    number = randi(length(Antenna_Set));
    Bus_Set{i}.Antenna = number;
end

% Communication
for i = 1:length(Centraloffice_Set)
    number = randi(length(Branch_Set));
    Centraloffice_Set{i}.Branch = number;
    if ~isempty(Centraloffice_Set{i}.Router)
        Router_Set{Centraloffice_Set{i}.Router}.Branch = number;
    end
end

for i = 1:length(Centraloffice_Set)
    for j = 1:length(Road_Set)
        if Centraloffice_Set{i}.Location == Road_Set{j}.End_Location
            Centraloffice_Set{i}.Road = [Centraloffice_Set{i}.Road, j];
        end
    end
end

for i = 1:length(Antenna_Set)
    for j = 1:length(Road_Set)
        if Antenna_Set{i}.Location == Road_Set{j}.End_Location
            Antenna_Set{i}.Road = [Antenna_Set{i}.Road, j];
        end
    end
end

for i = 1:length(Antenna_Set)
    for j = 1:length(Cellline_Set)
        if Antenna_Set{i}.Location == Cellline_Set{j}.End_Location
            Antenna_Set{i}.Cellline = [Antenna_Set{i}.Cellline, j];
        end
    end
end

for i = 1:length(Centraloffice_Set)
    for j = 1:length(Cellline_Set)
        if Centraloffice_Set{i}.Location == Cellline_Set{j}.End_Location
            Centraloffice_Set{i}.Cellline = [Centraloffice_Set{i}.Cellline, j];
        end
    end
end

for i = 1:length(Cellline_Set)
    number = randi(length(Antenna_Set));
    Cellline_Set{i}.Antenna = number;
    number = randi(length(Branch_Set));
    Cellline_Set{i}.Branch = number;
end

% Transportation
for i = 1:length(Road_Set)
    number = randi(length(Antenna_Set));
    Road_Set{i}.Antenna = number;
    number = randi(length(Branch_Set));
    Road_Set{i}.Branch = number;
end

for i = 1:length(Road_Set)
    for j = 1:length(Bus_Set)
        if isequal(Road_Set{i}.Start_Location, Bus_Set{j}.Start_Location) && isequal(Road_Set{i}.End_Location, Bus_Set{j}.End_Location)
            Road_Set{i}.Bus = [Road_Set{i}.Bus, j];
        end
    end
end

for i = 1:length(Road_Set)
    for j = 1:length(Cellline_Set)
        if isequal(Road_Set{i}.Start_Location, Cellline_Set{j}.Start_Location) && isequal(Road_Set{i}.End_Location, Cellline_Set{j}.End_Location)
            Road_Set{i}.Cellline = [Road_Set{i}.Cellline, j];
        end
    end
end

for i = 1:length(Bridge_Set)
    Bridge_Set{i}.Destructible = 1;
    number = randi(length(Antenna_Set));
    Bridge_Set{i}.Antenna = number;
    number = randi(length(Branch_Set));
    Bridge_Set{i}.Branch = number;
end

for i = 1:length(TraficLight_Set)
    TraficLight_Set{i}.Destructible = 1;
    number = randi(length(Antenna_Set));
    TraficLight_Set{i}.Antenna = number;
end

for i = 1:10
    CommunicationTower_Set{i} = CommunicationTower(i, [randi(10), randi(10)], randi(length(Branch_Set)), 1);
    CommunicationTower_Set{i}.Centraloffice = randi(length(Centraloffice_Set));
end

for i = 1:length(Antenna_Set)
    Antenna_Set{i}.Class = 'Antenna';
end

for i = 1:length(Branch_Set)
    Branch_Set{i}.Class = 'Branch';
end

for i = 1:length(Bridge_Set)
    Bridge_Set{i}.Class = 'Bridge';
end

for i = 1:length(Bus_Set)
    Bus_Set{i}.Class = 'Bus';
end

for i = 1:length(Cellline_Set)
    Cellline_Set{i}.Class = 'Cellline';
end

for i = 1:length(Centraloffice_Set)
    Centraloffice_Set{i}.Class = 'Centraloffice';
end

for i = 1:length(CommunicationTower_Set)
    CommunicationTower_Set{i}.Class = 'CommunicationTower';
end

for i = 1:length(Generator_Set)
    Generator_Set{i}.Class = 'Generator';
end

for i = 1:length(Road_Set)
    Road_Set{i}.Class = 'Road';
end

for i = 1:length(Router_Set)
    Router_Set{i}.Class = 'Router';
end

for i = 1:length(TraficLight_Set)
    TraficLight_Set{i}.Class = 'TraficLight';
end

clear i j number;
%%