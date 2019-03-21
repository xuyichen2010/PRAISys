% Minimum working example of PRAISys

close all
clear all
clc

%%          Input characteristics the nodes of the network               %%
% Graph Display
%                          Substation 1
%                                |
%                     --------------------------                           
%                     |          |             |
%            Transformer 2   Transformer 3   Transformer 4              
%                  |   | |     | |   |      |  |  |   |  |  
%                  H5 H6 H7   H8 H9 H10     H11 H12 H13 H14 H15
% Number
Num.Nodes=15;
Num.Substation=1;
Num.Transformer=3;
Num.Household=11;
List.Substation=[1];
List.Transformer=[2,3,4];
List.Household=[5,6,7,8,9,10,11,12,13,14,15];
% Location



xy = [  2 0       %Substation 1
        1 1       %Transformer 2
        0 2       %Transformer 3
        3 0       %Transformer 4
        3 1       %Household 5
        3 2       %Household 6
        4 0       %Household 7
        5 1       %Household 8
        6 2       %Household 9 
        5 3       %Household 10 
        5 5       %Household 11
        1 3       %Household 12
        0 5       %Household 13
        2 5       %Household 14
        2 1       %Household 15 
        ];    

%%Create a cell to store Substations we need Number and Locations
Substation_Set={};
for i=1:Num.Substation
Substation_Set{i}=Substation(i,xy(1,:));
end

%Create a cell to store Transformers we need Number and Locations
Transformer_Set={};
for i=1:Num.Transformer
    Transformer_Set{i}=Transformer(i+Num.Substation,xy(i+Num.Substation,:));
end

%Create a cell to store Households we need Number and Locations
Household_Set={};
for i=1:Num.Household
    Household_Set{i}=Household(i+Num.Substation+Num.Transformer,xy(i+Num.Substation+Num.Transformer,:));
end
clear xy
%%
%%Create the tree structure 
%Add parent node and children node in the class 
%Substaion
addLink(Substation_Set{1},[2 3 4]);
%Transformer
addLink(Transformer_Set{1},[1],[5 6 7]);
addLink(Transformer_Set{2},[1],[8 9 10]);
addLink(Transformer_Set{3},[1],[11 12 13 14 15]);
%Household
addLink(Household_Set{1},2);
addLink(Household_Set{2},2);
addLink(Household_Set{3},2);

addLink(Household_Set{4},3);
addLink(Household_Set{5},3);
addLink(Household_Set{6},3);

addLink(Household_Set{7},4);
addLink(Household_Set{8},4);
addLink(Household_Set{9},4);
addLink(Household_Set{10},4);
addLink(Household_Set{11},4);
%%