% Minimum working example of PRAISys
% Compute functionality of a bridge

function Q = bridgefunctionality(IMtype,IM,Bclass,t)


%% Using Functionality Fragility Surfaces (doesn't work well because it lacks correlation, but we can add it, Liyang and Francesco will)

sample = unifrnd(0,1);

switch Bclass
    case {1, 3, 4}
        switch IMtype
            case 'PGA'
                load FFS_CBr_class1_PGA.mat
                [X,Y] = meshgrid(time_vector,IM_vector);
                Qbar50 = interp2(X, Y, Qbar_ge_50, t, IM);
                Qbar100 = interp2(X, Y, Qbar_ge_100, t, IM);
                states = [0 50 100];
                test = sample > [Qbar50 Qbar100];
                Q = states(sum(test)+1);
        end
        
    case 2
        switch IMtype
            case 'PGA'
                load FFS_CBr_class2_PGA.mat
                [X,Y] = meshgrid(time_vector,IM_vector);
                Qbar50 = interp2(X, Y, Qbar_ge_50, t, IM);
                Qbar100 = interp2(X, Y, Qbar_ge_100, t, IM);
                states = [0 50 100];
                test = sample > [Qbar50 Qbar100];
                Q = states(sum(test)+1);
        end
        
end