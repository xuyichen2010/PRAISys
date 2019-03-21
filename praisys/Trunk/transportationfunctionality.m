% Minimum working example of PRAISys
% Compute transportation network functionality

% We have several more or less sophisticated metrics for this (a review
% paper is coming out soon). Here I put something that is a simplified
% version of what we used in "Metrics and algorithm for optimal retrofit
% strategy of resilient transportation networks" by Karamlou, Bocchini &
% Christou (we assume all bridges have flow = 1 and highway exits are only at nodes)


function Q = transportationfunctionality(ST,lcarr,lcros,QBr,timesteps)

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