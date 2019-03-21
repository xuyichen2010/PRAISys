% Minimum working example of PRAISys
% Compute functionality of a bridge

% We have already a much more sophisticated algorithm to compute this, but
% here I just wanted a sort of placeholder. 
% See "From Component Damage to System-Level Probabilistic Restoration Functions
% for Damaged Bridges" by Karamlou & Bocchini


function [Q , restoration_completion, state0] = bridgefunctionality(IMtype,IM,Bclass,timesteps,sample,restoration_completion_unif)

%% Using physics-based restoration functions

% sample = unifrnd(0,1);

switch IMtype
    case 'PGA'
        switch Bclass
            case {1, 3, 4}
                load FFS_CBr_class1_PGA.mat
                mean_restoration_duration = [365 60 1]; %mean restoration duration, for different initial damage states
                std_restoration_duration = [90 30 0.2]; %std of restoration duration, for different initial damage states
                
            case 2
                load FFS_CBr_class2_PGA.mat
                mean_restoration_duration = [400 90 1]; %mean restoration duration, for different initial damage states
                std_restoration_duration = [90 30 0.2]; %std of restoration duration, for different initial damage states
                
        end
       
        % The states vector represents three states of bridge
        % functionality: 0, 0.5, 1. 
        % Qbar50 and Qbar 100 are to get the initial functionality of the
        % bridge on the functionality frigility surface (FFS).  
        % "test" is calculated by comparing the functionality in "sample" with 
        % the functionality (Q) from the FFS at a initial state. 
        % If the functionality in "sample" for one bridge is greater than the 
        % the functionality (Q) from the FFS at a initial state, then the
        % corresponding value in "test" vector is 1 (true). Otherwise, it is 0
        % (false). And state0 gives the index for locating the value in states vector.
        % For instance, if sample<Qbar100, then test  = [0 0], state0 = 1, that
        % gives states(1)=0, i.e., the bridge is closed. 
        % If Qbar100<sample<Qbar50, test = [0 1], state0=2, that gives states(2)=0.5,
        % i.e., half of the lanes on the bridge is/are open.
        % If sample>Qbar50, test =[1 1], state0=3, that gives states(3)=1, i.e., the 
        % bridge is open with both/all lanes working properly. 
        %%% --------------------------------------------------
        %%% index of states | Q (%) | Qbar=100-Q (%) | Notes
        %%%  1                0       100           the bridge is completele closed.                           
        %%%  2                50      50            half of the lanes on the bridge is/are open.
        %%%  3                100     0             the bridge is open with both/all lanes working properly.
        %%% --------------------------------------------------
        % Q=0,50 -> Qbar50 = Probality_failure (Pfl) is equal to or greater than 50%.
        % Q=0 -> Qbar100 = Probality_failure (Pfl) is equal to or greater than 100%.
        
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





