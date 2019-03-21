% Minimum working example of PRAISys
% Main file

close all
clear
clc

%% Load input

% query the analyst for input file name
[FileName,PathName] = uigetfile('*.m','Select master input file',pwd);
basedir=PathName;
run([PathName,FileName])

clear PathName FileName

%% Start log file

if exist([analysis_title,'_log.txt'],'file')
    delete([analysis_title,'_log.txt'])
end
starttime=now;
diary([analysis_title,'_log.txt'])
disp(['Analysis started on ',datestr(starttime,'ddmmmyy_HH:MM')])

%% Load the system data from the individual system input files

for is=1:size(systems,1)
    eval(['system_input_file = input.',systems(is,:),';'])
    run(system_input_file);
end

%% Load the intensity measure map

load(input.IM)

%% Initialize the random stream
% To generate pseudorandom numbers from one or more random number streams
% The "seed" of "123" ensures that the generated single stream of random 
% numbers is always based on "123". 

s = RandStream('mt19937ar','Seed',123);
RandStream.setGlobalStream(s);

%% Pre-processing stage

% Find intensity measure at location of components of various systems
for ict=1:size(components,1)
    switch components(ict,:)
        case 'CBr'
            for ic=1:length(CBr.class)
                CBr.IM(ic) = interp2(IMx,IMy,IM,CBr.xy(ic,1),CBr.xy(ic,2));
            end
        case 'CTT'
            for ic=1:length(CTT.class)
                CTT.IM(ic) = interp2(IMx,IMy,IM,CTT.xy(ic,1),CTT.xy(ic,2));
            end
        case 'CTL'
            for ic=1:length(CTL.class)
                CTL.IM(ic) = interp2(IMx,IMy,IM,CTL.xy(ic,1),CTL.xy(ic,2));
            end
    end
end

%% Analysis first pass: no interdependencies

timesteps = linspace(0,time_horizon,Ntimesteps);

% Component functionality if Functionality Fragility Surfaces are used
% for it = 1:Ntimesteps
%     t = timesteps(it);
%     for ict=1:size(components,1)
%         switch components(ict,:)
%             case 'CBr'
%                 for ib=1:length(CBr.class)
%                     for is=1:Nsamples
%                         CBr.Q(it,ib,is) = bridgefunctionalityFFS(IMtype,CBr.IM(ib),CBr.class(ib),t);
%                     end
%                 end
%             case 'CTT'
% 
%         end
%     end 
% end

% Component functionality if physics-based siumlations are used
for ict=1:size(components,1) %loop over component types
    switch components(ict,:)
        case 'CBr'
            samples.CBr.Qbar = unifrnd(0,1,length(CBr.class),Nsamples);
            samples.CBr.restoration_completion_unif = unifrnd(0,1,length(CBr.class),Nsamples);
            CBr.state0=zeros(length(CBr.class),Nsamples);
            for ic=1:length(CBr.class) %loop over individual bridges
                for is=1:Nsamples %loop over samples
                    [CBr.Q(:,ic,is), CBr.restoration_completion(ic,is), CBr.state0(ic,is)] = ...
                        bridgefunctionality(IMtype,CBr.IM(ic),CBr.class(ic),timesteps,...
                        samples.CBr.Qbar(ic,is),samples.CBr.restoration_completion_unif(ic,is));
                end
            end
        case 'CTT'
            samples.CTT.Qbar = unifrnd(0,1,length(CTT.class),Nsamples);
            samples.CTT.restoration_completion_unif = unifrnd(0,1,length(CTT.class),Nsamples);
            CTT.state0=zeros(length(CTT.class),Nsamples);
                for ic=1:length(CTT.class) %loop over individual component towers
                    for is=1:Nsamples %loop over samples
                    [CTT.Q(:,ic,is), CTT.restoration_completion(ic,is), CTT.state0(ic,is)] = ...
                        ttowerfunctionality(IMtype,CTT.IM(ic),CTT.class(ic),timesteps,...
                        samples.CTT.Qbar(ic,is),samples.CTT.restoration_completion_unif(ic,is));
                    end
                end 
        case 'CTL'
            samples.CTL.Qbar = unifrnd(0,1,Nsamples,length(CTL.class));
            samples.CTL.restoration_completion_unif = unifrnd(0,1,length(CTL.class),Nsamples);
            CTL.state0=zeros(length(CTL.class),Nsamples);
            for ic=1:length(CTL.class) %loop over individual components
                for is=1:Nsamples %loop over samples
                    [CTL.Q(:,ic,is), CTL.restoration_completion(ic,is), CTL.state0(ic,is)] = ...
                        trafficlightfunctionality(IMtype,CTL.IM(ic),CTL.class(ic),timesteps,...
                        samples.CTL.Qbar(is,ic),samples.CTL.restoration_completion_unif(ic,is));
                end
            end
            
    end
end

% System functionality
for ist=1:size(systems,1) %loop over system type
    switch systems(ist,:) 
        case 'ST' %System Transportation
            for is=1:Nsamples %loop over samples
                ST.Q(:,is) = transportationfunctionality(ST,CBr.carr,CBr.cros,CBr.Q(:,:,is),timesteps);
            end
  
        case 'SP' %System power
            samples.SP.restoration_completion_unif = unifrnd(0,1,1,Nsamples);
            samples.SP.q = unifrnd(0,1,1,Nsamples);
            for is=1:Nsamples %loop over samples
                [SP.Q(:,is), SP.restoration_completion(is)] = powerfunctionality(SP,timesteps,samples.SP.restoration_completion_unif(is),samples.SP.q(is));
            end
            
        case 'SC' % System communication 
            samples.SC.restoration_completion_unif = unifrnd(0,1,1,Nsamples);
            samples.SC.q = unifrnd(0,1,1,Nsamples);
            for is=1:Nsamples %loop over samples
                [SC.Q(:,is), SC.restoration_completion(is)] = communicationfunctionality(SC,samples.SC.q(is),samples.SC.restoration_completion_unif(is),timesteps);
            end            
    end
end

% Some plots
% figure
% plot(timesteps,ST.Q)
% xlabel('Time after event [days]')
% ylabel('Transportation network functionality [%]')
% title([num2str(Nsamples),' samples of the tranportation network recovery (no interdependencies)']);
% 
% figure
% plot(timesteps,mean(ST.Q,2))
% xlabel('Time after event [days]')
% ylabel('Mean transportation network functionality [%]')
% title('(no interdependencies)');
figure(1)
subplot(3,1,1),plot(timesteps,ST.Q)
xlabel('Time after event [days]')
ylabel('Qtrans [%]')
title([num2str(Nsamples),' samples of the network recovery (no interdependencies)']);

subplot(3,1,2),plot(timesteps,SP.Q)
xlabel('Time after event [days]')
ylabel('Qpower [%]')

subplot(3,1,3),plot(timesteps,SC.Q)
xlabel('Time after event [days]')
ylabel('Qcommu [%]')

figure(2)
subplot(3,1,1),plot(timesteps,mean(ST.Q,2))
xlabel('Time after event [days]')
ylabel('Mean Qtrans [%]')
title('Mean functionality of the network recovery (no interdependencies)');

subplot(3,1,2),plot(timesteps,mean(SP.Q,2))
xlabel('Time after event [days]')
ylabel('Mean Qpower [%]')

subplot(3,1,3),plot(timesteps,mean(SC.Q,2))
xlabel('Time after event [days]')
ylabel('Mean Qcommu [%]')

%% Iterative solution: account for interdependencies

deltahistory = [];
tic
for iiter = 1:conv.itermax
    
    disp(['Iteration ',num2str(iiter),' started; ',num2str(round(toc)),' sec elapsed; max iterations = ',num2str(conv.itermax),'; max time = ',num2str(conv.tmax),' sec.'])
    
    % Component functionality if physics-based siumlations are used
    for ict=1:size(components,1) %loop over component types
        switch components(ict,:)
            case 'CBr'
                for ic=1:length(CBr.class) %loop over individual bridges
                    for is=1:Nsamples %loop over samples
                        CBr.Q(:,ic,is) = bridgefunctionality_wd(IMtype,CBr.IM(ic),CBr.class(ic),timesteps,...
                            CBr.state0(ic,is),CBr.restoration_completion(ic,is),CBr.trafficlights(ic),CTL.Q(:,:,is));
                    end
                end
            case 'CTT'
                for ic=1:length(CTT.class) %loop over individual bridges
                    for is=1:Nsamples %loop over samples
                        CTT.Q(:,ic,is) = ttowerfunctionality_wd(IMtype,CTT.IM(ic),CTT.class(ic),timesteps,...
                            CTT.state0(ic,is),CTT.restoration_completion(ic,is),CBr.trafficlights(ic),CTL.Q(:,:,is));
                    end
                end
            case 'CTL'
                for ic=1:length(CTL.class) %loop over individual components
                    for is=1:Nsamples %loop over samples
                        CTL.Q(:,ic,is) = trafficlightfunctionality_wd(IMtype,CTL.IM(ic),CTL.class(ic),timesteps,...
                            CTL.state0(ic,is),CTL.restoration_completion(ic,is));
                    end
                end
        end
    end
    
    % System functionality
    for ist=1:size(systems,1) %loop over system type
        switch systems(ist,:)
            case 'ST' %System Transportation
                ST.Qold=ST.Q;
                for is=1:Nsamples %loop over samples
                    ST.Q(:,is) = transportationfunctionality_wd(ST,CBr.carr,CBr.cros,CBr.Q(:,:,is),timesteps,SP.Q(:,is));
                end
                
            case 'SP' %System Power
                SP.Qold=SP.Q;
            for is=1:Nsamples %loop over samples
                SP.Q(:,is) = powerfunctionality_wd(SP,timesteps,SP.restoration_completion(is),samples.SP.q(is),ST.Q(:,is));
            end

           case 'SC' %System Communication
                SC.Qold=SC.Q;
            for is=1:Nsamples %loop over samples
                SC.Q(:,is) = communicationfunctionality_wd(SC,timesteps,SC.restoration_completion(is),samples.SC.q(is),SC.Q(:,is));
            end   
            
        end
    end
    
    
    
    % compute convergence
    delta = 0;
    for ist=1:size(systems,1) %loop over system type
        switch systems(ist,:)
            case 'ST' %System Transportation
                difference = abs(ST.Q-ST.Qold);
                delta = delta + mean(difference(:));
            case 'SP' %System Power
                difference = abs(SP.Q-SP.Qold);
                delta = delta + mean(difference(:));
            case 'SC' %System Communication
                difference = abs(SC.Q-SC.Qold);
                delta = delta + mean(difference(:)); 
        end
    end
    
    deltahistory = [deltahistory ; delta];
    
    disp(['Iteration ',num2str(iiter),' yielded delta = ',num2str(delta)])
    
    if delta < conv.toll
        disp('Convergence met')
        break
    end
    if toc>conv.tmax
        disp('Iterations terminated for maximium time reached')
        break
    end
    if iiter==conv.itermax
        disp('Iterations terminated for maximium number of iterations reached')
    end
    
end

%% Plot with dependencies

figure
subplot(3,1,1),plot(timesteps,ST.Q)
xlabel('Time after event [days]')
ylabel('Qtrans [%]')
title([num2str(Nsamples),' samples of the network recovery (with interdependencies)']);

subplot(3,1,2),plot(timesteps,SP.Q)
xlabel('Time after event [days]')
ylabel('Qpower [%]')

subplot(3,1,3),plot(timesteps,SC.Q)
xlabel('Time after event [days]')
ylabel('Qcommu [%]')

figure
subplot(3,1,1),plot(timesteps,mean(ST.Q,2))
xlabel('Time after event [days]')
ylabel('Mean Qtrans [%]')
title('Mean functionality of the network recovery (with interdependencies)');

subplot(3,1,2),plot(timesteps,mean(SP.Q,2))
xlabel('Time after event [days]')
ylabel('Mean Qpower [%]')

subplot(3,1,3),plot(timesteps,mean(SC.Q,2))
xlabel('Time after event [days]')
ylabel('Mean Qcommu [%]')


%% Postprocessing

figure
plot(deltahistory);
xlabel('Iteration')
ylabel('\Delta')
title('Convergence of iterations')

%% Clean up

endtime=now;
diary([analysis_title,'_log.txt'])
disp(['Analysis complteted on ',datestr(endtime,'ddmmmyy_HH:MM')])
diary off