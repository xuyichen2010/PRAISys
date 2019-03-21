close all
clear
clc
% E = [1 2 3;2 1 2;2 3 2;2 4 2];
% V = [1 2 3 4];
% names = {'alpha' 'beta' 'gamma' 'delta'};
% G = Library2.buildGraph(V, E, 2, names);
% plot(G,'Layout','force');

s = {'BOS' 'NYC' 'NYC' 'NYC' 'LAX'};
t = {'NYC' 'LAX' 'DEN' 'LAS' 'DCA'};
G = digraph(s,t);
subplot(2, 2, 1);
plot(G,'Layout','force');
            G = rmnode(G,nodeName);
subplot(2, 2, 2);
plot(G,'Layout','force');
G = Library2.addNode('NYC',{'BOS' 'NYC' 'NYC' 'NYC'},{'NYC' 'LAX' 'DEN' 'LAS'},G);
subplot(2, 2, 3);
plot(G,'Layout','force');