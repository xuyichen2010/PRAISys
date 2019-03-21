% Minimum working example of PRAISys
% Master input

%% General parameters

analysis_title = 'Example1'; %name of the analysis for log and output files
systems = [ 'ST' ; 'SP' ;'SC']; % list of systems to be included in this analysis. ST = transportation, SP = power, SC = communication
components = ['CBr'; 'CTT'; 'CTL']; % list of components to be included in this analysis. CBr = bridges, CTT = transmission towers
Nsamples = 100;
time_horizon = 365; % time horizon for the analysis in days
Ntimesteps = 27;
IMtype = 'PGA'; % type of intensity measure used, e.g. PGA, Sa, wind velocity...

%% List input files for analyzed systems

input.ST = 'input_transportation_example1.m';
input.SP = 'input_power_example1.m';
input.SC = 'input_communication_example1.m';

%% Load Intensity Measure map representing the scenario
% (at some point there may be modules doing this, for now we assume that it
% is computed separately somehow)
% It has to be consistent with the IMtype variable

input.IM = 'shakemap2.mat';

%% Some convergence parameters
% conv.toll = tollerance to determine when convergence is met
% conv.tmax = maximum time for the analysis
% conv.itermax = maximum number of iterations for the sub-analyses
conv.toll=1e-20;   
conv.tmax=10;
conv.itermax=9000;  