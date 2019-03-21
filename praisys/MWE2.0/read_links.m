[num1,txt1,raw1] = xlsread('RoadLink.xlsx');
[num2,txt2,raw2] = xlsread('TrafficLights.xlsx');
[num3,txt3,raw4] = xlsread('Bridges.xlsx');
all_Bridges_links=num3(:,8:15);

for k=2:4
 for i=1:size(num1,1)
[m,n]=find(num1(i,1)==all_Bridges_links(:,k));
  if k==2 
      bridgeIDcarry{i}=m;
  else
      bridgeIDcarry{i}=[bridgeIDcarry{i};m];
  end 
 end
end


for k=6:8
 for i=1:size(num1,1)
[m,n]=find(num1(i,1)==all_Bridges_links(:,k));
  if k==2 
      bridgeIDcross{i}=m;
  else
      bridgeIDcross{i}=[bridgeIDcarry{i};m];
  end 
 end
end



mm=[num2(:,1),num2(:,6)];
for i=1:size(num1,1)
[m,n]=find(num1(i,1)==mm(:,2));
trafficlightID{i}=m;
end

save newroadlinks.mat bridgeIDcarry bridgeIDcross trafficlightID

