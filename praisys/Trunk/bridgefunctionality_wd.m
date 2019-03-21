% Minimum working example of PRAISys
% Compute functionality of a bridge with dependencies

% We have already a much more sophisticated algorithm to compute this, but
% here I just wanted a sort of placeholder. 
% See "From Component Damage to System-Level Probabilistic Restoration Functions
% for Damaged Bridges" by Karamlou & Bocchini


function Q = bridgefunctionality_wd(IMtype,IM,Bclass,timesteps,state0,restoration_completion,trafficlights,CTLQ)

%% Using physics-based restoration functions

% sample = unifrnd(0,1);

% switch IMtype
%     case 'PGA'
%         switch Bclass
%             case {1, 3, 4}
%                 load FFS_CBr_class1_PGA.mat
%                 mean_restoration_duration = [365 60 1]; %mean restoration duration, for different initial damage states
%                 std_restoration_duration = [90 30 0.2]; %std of restoration duration, for different initial damage states
%                 
%             case 2
%                 load FFS_CBr_class2_PGA.mat
%                 mean_restoration_duration = [400 90 1]; %mean restoration duration, for different initial damage states
%                 std_restoration_duration = [90 30 0.2]; %std of restoration duration, for different initial damage states
%                 
%         end
%         
        states = [0 0.5 1];
%         [X,Y] = meshgrid(time_vector,IM_vector);
%         Qbar50 = interp2(X, Y, Qbar_ge_50, 0, IM);
%         Qbar100 = interp2(X, Y, Qbar_ge_100, 0, IM);
%         
%         test = sample > [Qbar50 Qbar100];
%         state0 = sum(test)+1; % Functionality at t=0 using FFS
%         
%         %[mu, sigma] = lognstat(mean_restoration_duration(state0),std_restoration_duration(state0));
%         mu = log(mean_restoration_duration(state0)) - 0.5*log(1+ (std_restoration_duration(state0)^2)/(mean_restoration_duration(state0)^2));
%         sigma = sqrt(log(1+ (std_restoration_duration(state0)^2)/(mean_restoration_duration(state0)^2)));
%         
%         restoration_completion = lognrnd(mu,sigma);
        
        q=states(state0);
        m=(1-q)/restoration_completion;
        Q = min(m*timesteps+q , 1);
        Q = round(2*Q) / 2;
        
        % Everything above may be redundant: it should already be in CBr.Q,
        % but in the future we may decide to integrate better the various
        % things that affect functionality, so I leave it there.
        
        % Condition: if the traffic light is not perfectily working, the
        % bridge is 50% functional or less
        if trafficlights
            CTLQ = CTLQ(:,trafficlights);
            min(Q,max(CTLQ,0.5)');
        end
        
% end