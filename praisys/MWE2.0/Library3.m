%%%%library3.m
% by W.S. 06/29/2018

classdef Library3
    methods(Static)
        
        
        
        %% compute fragility
        % bridge fragility
        % IntensityMeasureVector = [PGA PGD Sa(0.3s)  Sa(1s)];
        function Prob_Damage = Bridge_Prob_Failure(IntensityMeasureVector,Object)
%             PGA: peak ground acceleration
%             PGD: permanent ground deformation
%             PGV: peak ground velocity?
%             Sa03: spectral acceleration [0.3 s]
%             Sa10: spectral acceleration [1.0 s]
            
            Prob_Damage = zeros(1,5); 
            
            % Object = bridge
            % without considering soil amplification factor 
            % (table 4.10 in HAZUS-EQ technical manual)
            PGA = IntensityMeasureVector(1);
            Sa10 = IntensityMeasureVector(1);
            Sa03 = IntensityMeasureVector(1);
            
%             PGD = IntensityMeasureVector(4);
%             % equation (4-5) in technical manual of HAZUS-earthquake, pp 4-9.  
%             PGV = (386.4*Sa10)*inv(2*pi*1.65); 
            
            % dispersion (=lognormal standard deviation)
            Beta_Sa10 = 0.6;
            
            idx = 1; 
            Sa10_fragility = Object.Fragility(idx,1:4);
            
            % bridge information
            alpha = Object.SkewAngle*pi*inv(180);
       
            % modification factors fo Sa10 and PGD
            Kskew = sqrt(sin(0.5*pi-alpha));
            Kshape = 2.5*Sa10*inv(Sa03);
            
            [K3D,Ishape,f1,f2] = Library3.getBridgeModificationFactor(Object); 
            
            if Ishape = 0
                Factor_slight = 1;
            elseif Ishape = 1
                Factor_slight = min(1,Kshape);
            end
            
            Factor_other = Kskew*K3D;
            
            Sa10_NewMedian = [Factor_slight,repmat(Factor_other,1,3)].*Sa10_fragility; 
            
            %% Sa: damage probability due to Ground Shaking
            IM = Sa10;
            median = Sa10_NewMedian;
            sigma = Beta_Sa10; 
            mu = log(median);     
            p = logncdf(IM,mu,sigma);
            Prob_Damage = [1, p] - [p,0]; 
            
            %% PGD: damage probability due to Ground Failure (not modeled currently)
%             PGD_fragility = Object.Fragility(idx,5:8);
%             Beta_PGD = 0.2; 
%             PGD_NewMedian = [rempat(f1,1,3), f2].*PGD_fragility; 
%             IM = PGD_NewMedian;
%             sigma = Beta_PGD;
%             mu = log(median);     
%             p = logncdf(IM,mu,sigma);
%             P_PGD = [1, p] - [p,0];


        end
        
        function [K3D,Ishape,f1,f2] = getBridgeModificationFactor(Object) 
            % refer to HAZUS-EQ technical manual
            % Table 7.2 and Table 7.3 on page 7-6 ~7-8 
            % bridge information
            N = Object.NoOfSpan;
            alpha = Object.SkewAngle*pi*inv(180);
            W = Object.Width;
            L = Object.Length;
            Lmax = Object.MaximumSpanLength;
            c = Object.Category; 
                        
            %% compute K3D = 1+A/(N-B)
            if strcmp(c, 'HWB1') %'HWB10'~'HWB28','HWB3'~'HWB5' in Lehigh Valley
                A = 0.25; B = 1;
                Ishape = 0;
                f1 = 1; f2 = f1;
            elseif strcmp(c, 'HWB2')
                A = 0.25; B = 1;
                Ishape = 0;
                f1 = 1; f2 = f1;
            elseif strcmp(c, 'HWB3')
                A = 0.25; B = 1;
                Ishape = 1;
                f1 = 1; f2 = f1;
            elseif strcmp(c, 'HWB4')
                A = 0.25; B = 1;
                Ishape = 1;
                f1 = 1; f2 = f1;
            elseif strcmp(c, 'HWB5')
                A = 0.25; B = 1;
                Ishape = 0;
                if alpha == 0
                    f1 = 1;
                else
                    f1 = 0.5*L*inv(N*W*sin(alpha)); 
                end
                f2 = f1;    
            elseif strcmp(c, 'HWB6')
                A = 0.25; B = 1;
                Ishape = 0;
                if alpha == 0
                    f1 = 1;
                else
                    f1 = 0.5*L*inv(N*W*sin(alpha)); 
                end
                f2 = f1;     
            elseif strcmp(c, 'HWB7')
                A = 0.25; B = 1;
                Ishape = 0;
                if alpha == 0
                    f1 = 1;
                else
                    f1 = 0.5*L*inv(N*W*sin(alpha)); 
                end
                f2 = f1; 
            elseif strcmp(c, 'HWB8')
                A = 0.33; B = 0;
                Ishape = 0;
                f1 = 1;
                f2 = sin(alpha);  
            elseif strcmp(c, 'HWB9')
                A = 0.33;
                B = 1;
                Ishape = 0;
                f1 = 1;
                f2 = sin(alpha);
            elseif strcmp(c, 'HWB10')
                A = 0.33;
                B = 0;    
                Ishape = 1;
                f1 = 1;
                f2 = sin(alpha);
            elseif strcmp(c, 'HWB11')
                A = 0.33;
                B = 1;   
                Ishape = 1;
                f1 = 1;
                f2 = sin(alpha);
            elseif strcmp(c, 'HWB12')
                A = 0.09;
                B = 1;
                Ishape = 0;
                if alpha == 0
                    f1 = 1;
                else
                    f1 = 0.5*L*inv(N*W*sin(alpha)); 
                end
                f2 = f1; 
            elseif strcmp(c, 'HWB13')
                A = 0.09;
                B = 1;
                Ishape = 0;
                if alpha == 0
                    f1 = 1;
                else
                    f1 = 0.5*L*inv(N*W*sin(alpha)); 
                end
                f2 = f1; 
            elseif strcmp(c, 'HWB14')
                A = 0.25;
                B = 1;
                Ishape = 0;
                if alpha == 0
                    f1 = 1;
                else
                    f1 = 0.5*L*inv(N*W*sin(alpha)); 
                end
                f2 = f1; 
            elseif strcmp(c, 'HWB15')
                A = 0.05;
                B = 0;    
                Ishape = 1;
                f1 = 1;
                f2 = sin(alpha);
            elseif strcmp(c, 'HWB16')
                A = 0.33;
                B = 1;   
                Ishape = 1;
                f1 = 1;
                f2 = sin(alpha);
            elseif strcmp(c, 'HWB17')
                A = 0.25;
                B = 1;
                Ishape = 0;
                if alpha == 0
                    f1 = 1;
                else
                    f1 = 0.5*L*inv(N*W*sin(alpha)); 
                end
                f2 = f1; 
            elseif strcmp(c, 'HWB18')
                A = 0.25;
                B = 1;
                Ishape = 0;
                if alpha == 0
                    f1 = 1;
                else
                    f1 = 0.5*L*inv(N*W*sin(alpha)); 
                end
                f2 = f1; 
            elseif strcmp(c, 'HWB19')
                A = 0.25;
                B = 1;
                Ishape = 0;
                if alpha == 0
                    f1 = 1;
                else
                    f1 = 0.5*L*inv(N*W*sin(alpha)); 
                end
                f2 = f1; 
            elseif strcmp(c, 'HWB20')
                A = 0.33;
                B = 0;  
                Ishape = 0;
                f1 = 1;
                f2 = sin(alpha);
            elseif strcmp(c, 'HWB21')
                A = 0.33;
                B = 1;  
                Ishape = 0;
                f1 = 1;
                f2 = sin(alpha);
            elseif strcmp(c, 'HWB22')
                A = 0.33;
                B = 0;
                Ishape = 1;
                if alpha == 0
                    f1 = 1;
                else
                    f1 = 0.5*L*inv(N*W*sin(alpha)); 
                end
                f2 = f1; 
            elseif strcmp(c, 'HWB23')
                A = 0.33;
                B = 1;
                Ishape = 1;
                if alpha == 0
                    f1 = 1;
                else
                    f1 = 0.5*L*inv(N*W*sin(alpha)); 
                end
                f2 = f1; 
            elseif strcmp(c, 'HWB24')
                A = 0.20;
                B = 1;
                Ishape = 0;
                if alpha == 0
                    f1 = 1;
                else
                    f1 = 0.5*L*inv(N*W*sin(alpha)); 
                end
                f2 = f1; 
            elseif strcmp(c, 'HWB25')
                A = 0.20;
                B = 1;    
                Ishape = 0;
                if alpha == 0
                    f1 = 1;
                else
                    f1 = 0.5*L*inv(N*W*sin(alpha)); 
                end
                f2 = f1; 
            elseif strcmp(c, 'HWB26')
                A = 0.20;
                B = 1;   
                Ishape = 1;
                f1 = 1;
                f2 = sin(alpha);
            elseif strcmp(c, 'HWB27')
                A = 0.10;
                B = 0;
                Ishape = 0;
                f1 = 1;
                f2 = sin(alpha);
            end 
                
            K3D = 1+A*inv(N-B);    
            
            
        end
        
            
            
        
        %% 
        
        
    end
end
