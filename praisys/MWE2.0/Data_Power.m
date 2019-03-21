% Minimum working example of PRAISys
% Power System
%%          Input characteristics the nodes of the network               %%
% Graph Display
%                                              Powerplant
%                                                   |
%                     -------------------------------------------------------------      TransmissionLine
%                     |                                                           |
%                Substation                                                    Substation
%                     |                                                           |
%          ------------------------------                              ---------------------------       TransmissionLine
%          |          |                 |                              |                         |
%  Transformer    Transformer       Transformer                    Transformer                 Transformer
%   |   |   |     |   |   |      |   |   |   |   |                  |   |   |                  |   |   |    DistributionLine
%  Hou Hou Hou   Hou Hou Hou     Hou Hou Hou Hou Hou                Hou Hou Hou                Hou Hou Hou
%
% Location



xy = [  1 0       %Branch 1
    1 1       % Branch 2
    1 2       % Branch 3
    1 3       % Branch 4
    2 0       % Branch 5
    2 1       % Branch 6
    2 2       % Branch 7
    2 3       % Branch 8
    3 0       % Branch 9
    3 1       % Branch 10
    3 2       % Branch 11
    3 3       % Branch 12
    4 0       % Branch 13
    4 1       % Branch 14
    4 2       % Branch 15
    4 3       % Branch 16
    1 4       % Branch 17
    2 4       % Branch 18
    3 4       % Branch 19
    4 4       % Branch 20
    5 0       % Branch 21
    5 1       % Branch 22
    5 2       % Branch 23
    5 3       % Branch 24
    5 4       % Branch 25
    ];

%%Create a cell to store Substations we need Number and Locations
Branch_Set = {};
Generator_Set = {};
Bus_Set = {};

Generator_Set{1} = Generator(1,xy(1,:),1);
Generator_Set{2} = Generator(2,xy(7,:),1);
Generator_Set{3} = Generator(3,xy(13,:),1);
Generator_Set{4} = Generator(4,xy(18,:),1);
Generator_Set{5} = Generator(5,xy(25,:),1);
index = 1;

for i = 1:25
    Branch_Set{i} = Branch(i, xy(i,:),2);
    if i == 1 || i == 7 || i == 13 || i == 18 || i ==25
        addGenerator(Branch_Set{i}, index);
        index = index + 1;
    end
end

Bus_Set{1} = Bus(1, Branch_Set{1}.Location, Branch_Set{2}.Location, 3);
Bus_Set{2} = Bus(2, Branch_Set{1}.Location, Branch_Set{5}.Location, 3);
Bus_Set{3} = Bus(3, Branch_Set{2}.Location, Branch_Set{5}.Location, 4);
Bus_Set{4} = Bus(4, Branch_Set{5}.Location, Branch_Set{3}.Location, 4);
Bus_Set{5} = Bus(5, Branch_Set{5}.Location, Branch_Set{4}.Location, 4);
Bus_Set{6} = Bus(6, Branch_Set{3}.Location, Branch_Set{6}.Location, 4);
Bus_Set{7} = Bus(7, Branch_Set{7}.Location, Branch_Set{6}.Location, 3);
Bus_Set{8} = Bus(8, Branch_Set{7}.Location, Branch_Set{4}.Location, 3);
Bus_Set{9} = Bus(9, Branch_Set{7}.Location, Branch_Set{16}.Location, 3);
Bus_Set{10} = Bus(10, Branch_Set{7}.Location, Branch_Set{9}.Location, 3);
Bus_Set{11} = Bus(11, Branch_Set{6}.Location, Branch_Set{10}.Location, 4);
Bus_Set{12} = Bus(12, Branch_Set{9}.Location, Branch_Set{8}.Location, 4);
Bus_Set{13} = Bus(13, Branch_Set{9}.Location, Branch_Set{21}.Location, 4);
Bus_Set{14} = Bus(14, Branch_Set{18}.Location, Branch_Set{9}.Location, 3);
Bus_Set{15} = Bus(15, Branch_Set{25}.Location, Branch_Set{21}.Location, 3);
Bus_Set{16} = Bus(16, Branch_Set{25}.Location, Branch_Set{22}.Location, 3);
Bus_Set{17} = Bus(17, Branch_Set{25}.Location, Branch_Set{23}.Location, 3);
Bus_Set{18} = Bus(18, Branch_Set{25}.Location, Branch_Set{24}.Location, 3);
Bus_Set{19} = Bus(19, Branch_Set{23}.Location, Branch_Set{24}.Location, 4);
Bus_Set{20} = Bus(20, Branch_Set{13}.Location, Branch_Set{11}.Location, 4);
Bus_Set{21} = Bus(21, Branch_Set{13}.Location, Branch_Set{14}.Location, 4);
Bus_Set{22} = Bus(22, Branch_Set{14}.Location, Branch_Set{12}.Location, 4);
Bus_Set{23} = Bus(23, Branch_Set{5}.Location, Branch_Set{15}.Location, 4);
Bus_Set{24} = Bus(24, Branch_Set{15}.Location, Branch_Set{20}.Location, 4);
Bus_Set{25} = Bus(25, Branch_Set{16}.Location, Branch_Set{17}.Location, 4);
Bus_Set{26} = Bus(26, Branch_Set{19}.Location, Branch_Set{17}.Location, 4);
Bus_Set{27} = Bus(27, Branch_Set{18}.Location, Branch_Set{19}.Location, 3);
Bus_Set{28} = Bus(28, Branch_Set{18}.Location, Branch_Set{22}.Location, 4);

for i = 1:length(Branch_Set)
    for j = 1:length(Bus_Set)
        if isequal(Branch_Set{i}.Location, Bus_Set{j}.Start_Location)
            addBus(Branch_Set{i}, j);
        end
    end
end

clear i j xy index;
%%