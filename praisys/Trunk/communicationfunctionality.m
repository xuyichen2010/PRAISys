% Minimum working example of PRAISys
% Compute communication network functionality

function [Q restoration_completion] = communicationfunctionality(SC,q,restoration_completion_unif,timesteps)

% I have no idea about this, so for now we just make it completely random

mean_restoration_duration = 15; %mean restoration duration
std_restoration_duration = 2; %std of restoration duration

mu = log(mean_restoration_duration) - 0.5*log(1+ (std_restoration_duration^2)/(mean_restoration_duration^2));
sigma = sqrt(log(1+ (std_restoration_duration^2)/(mean_restoration_duration^2)));

% restoration_completion = lognrnd(mu,sigma);
restoration_completion = logninv(restoration_completion_unif,mu,sigma);

% q=unifrnd(0,1,1,1);
m=(1-q)/restoration_completion;
Q = min(m*timesteps+q , 1);
