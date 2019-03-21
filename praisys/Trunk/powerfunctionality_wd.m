% Minimum working example of PRAISys
% Compute power network functionality with dependencies

function Q = powerfunctionality_wd(SP,timesteps,restoration_completion,q,STQ)

% I have no idea about this, so for now we just make it completely random

% mean_restoration_duration = 45; %mean restoration duration
% std_restoration_duration = 10; %std of restoration duration
% 
% mu = log(mean_restoration_duration) - 0.5*log(1+ (std_restoration_duration^2)/(mean_restoration_duration^2));
% sigma = sqrt(log(1+ (std_restoration_duration^2)/(mean_restoration_duration^2)));
% 
% restoration_completion = lognrnd(mu,sigma);

% q=unifrnd(0,1,1,1);
m=(1-q)/restoration_completion;
Q = min(m*timesteps+q , 1);

% we add the condition that the loss of functionality of the transportation system
% can slow down the recovery of the power system (obviously this should be
% improved)

Q = Q.*STQ';