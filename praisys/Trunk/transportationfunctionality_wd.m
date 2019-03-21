% Minimum working example of PRAISys
% Compute transportation network functionality with dependencies

% We have several more or less sophisticated metrics for this (a review
% paper is coming out soon). Here I put something that is a simplified
% version of what we used in "Metrics and algorithm for optimal retrofit
% strategy of resilient transportation networks" by Karamlou, Bocchini &
% Christou (we assume all bridges have flow = 1 and highway exits are only at nodes)


function Q = transportationfunctionality_wd(ST,lcarr,lcros,QBr,timesteps,Qpower)

Q=zeros(size(ST.links,1),length(timesteps));
IFtotal = sum(ST.links(:,5));
for il=1:size(ST.links,1)
    %il
    carr=logical(sum(lcarr==il,2));
    cros=logical(sum(lcros==il,2));
    if sum([carr;cros]) == 0
        Q(il,:)=ones(1,length(timesteps))* ST.links(il,5);
    else
        tmp1=min(QBr(:,carr),2);
        tmp2=min(QBr(:,cros),2);
        Q(il,:)=min([tmp1,tmp2],1) * ST.links(il,5);
    end
end

Q=sum(Q)/IFtotal;

% we add the condition that if the functionality of the power system is
% less than 50%, then the functionality of the transportation system is reduced by 10%

Q = Q.*max(0.9,(Qpower'>=0.5));
