%% Perform new optimization of three systems
tic 
for system=1:3
    [aa{system},opxx{system}]=yalmip_opti(system);
end


toc