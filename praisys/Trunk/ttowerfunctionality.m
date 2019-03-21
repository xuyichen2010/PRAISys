% Minimum working example of PRAISys
% Compute functionality of a transimission tower/router


function [Q , restoration_completion, state0] = ttowerfunctionality(IMtype,IM,Cclass,timesteps,sample,restoration_completion_unif)

%% Using physics-based restoration functions

% sample = unifrnd(0,1);

switch IMtype
    case 'PGA'
        switch Cclass
            case {1, 3, 4}
                load FFS_CTT_class1_PGA.mat
                mean_restoration_duration = [10 5 1]; %mean restoration duration, for different initial damage states
                std_restoration_duration = [1 1 0.2]; %std of restoration duration, for different initial damage states
                
            case 2
                load FFS_CTT_class2_PGA.mat
                mean_restoration_duration = [12 6 2]; %mean restoration duration, for different initial damage states
                std_restoration_duration = [1 1 0.2]; %std of restoration duration, for different initial damage states
                
        end
        
        states = [0 0.5 1];
        [X,Y] = meshgrid(time_vector,IM_vector);
        Qbar50 = interp2(X, Y, Qbar_ge_50, 0, IM);
        Qbar100 = interp2(X, Y, Qbar_ge_100, 0, IM);
        
        test = sample > [Qbar50 Qbar100];
        state0 = sum(test)+1; % Functionality at t=0 using FFS
        
        %[mu, sigma] = lognstat(mean_restoration_duration(state0),std_restoration_duration(state0));
        mu = log(mean_restoration_duration(state0)) - 0.5*log(1+ (std_restoration_duration(state0)^2)/(mean_restoration_duration(state0)^2));
        sigma = sqrt(log(1+ (std_restoration_duration(state0)^2)/(mean_restoration_duration(state0)^2)));
        
        % restoration_completion = lognrnd(mu,sigma);
        restoration_completion = logninv(restoration_completion_unif,mu,sigma);
        
        q=states(state0);
        m=(1-q)/restoration_completion;
        Q = min(m*timesteps+q , 1);
        Q = round(2*Q) / 2;
        
end