 
function [opa,opx]=yalmip_opti(system)
load tables.mat % load tasks of three systems (taskTable), horizon length (time_horizon), R (Power_Resource, Comm_Resource, Trans_Resource)and P (precedenceTable) 
resource=[Power_Resource;Comm_Resource; Trans_Resource];
tic
%======================= parameters===========================
H=time_horizon; % horizon length
K=[4, 4, 4]; %  for three systems resource type length

% if Seperate_Scheduling==1
for k=system
I=size(taskTable{1,k},1); % number of tasks
r=reshape([taskTable{1,k}{:,11:14}],[size(taskTable{1,k},1),K(k)]);% number of type k resource needed for task i
end
% end
 

 % time duration for each task to be finished
for k=system
    for i=1:size(taskTable{1,k},1)
      if isempty(taskTable{1,k}{i,10}) % to aviod the 0s
        t(i)=0;
      else
        t(i)=[taskTable{1,k}{i,10}];
      end
    end
end





% the number of available type k resource
R=resource(system,:);


% predecessor matrix of tasks
for i=system
P=precedenceTable{1,i}(2:end,2:end); 
end



M=1e10; % A big enough number for if-then constraint

% z=zeros(1,I); % parameter for constraint 2 predecessor calculation
for k=system
for i=1:I
    z(i)=i;
end
end

% ==========================variable===============================
x=intvar(I,H); % the number of type k resources that should be sent to task i in time horizon h
a=binvar(I,H); % applied to transfer if-then constraint

% =========================constraints================================

% c1: at any period, the resource used by all tasks cannot exceed the total
% number of resource available
constraints=[];
for k=1:K
    for h=1:H
        temp7=transpose(x(:,h))*r(:,k);
        constraints=[constraints,temp7<=R(k)];
    end;
end;

% c2: precedence constraints
for i=1:I
    J=cell2mat(P(i,:)).*z;
    J1=nonzeros(J);
    if isempty(J1)~=0
        for h=2:H
            temp=M*a(i,h);
            temp2=sum(x(:,1:h-1),2);
            for j=J1
                temp=temp-t(j)-temp2(j); % check -temp2(j) or +temp2(j)
            end
            constraints=[constraints,temp>=0];
        end
        temp3=M*a(i,1);
        for j=J1
            temp3=temp3-t(j);
        end
        constraints=[constraints,temp3>=0];
        for i=1:I
            for h=1:H
                constraints=[constraints,M*(1-a(i,h))-x(i,h)>=0];
            end
        end
    end
end

% c3: we don't want to assign extra resource to a task than it actually
% needs
for i=1:I
    temp4=sum(x,2);
    constraints=[constraints,t(i)-temp4(i)>=0];
end

% c4: lowerbound for x
for i=1:I
    for h=1:H
        constraints=[constraints,x(i,h)>=0];
    end
end
% =========================objective=============================
objective=0;
for i=1:I
    temp6=sum(x,2);
    objective=objective+t(i)-temp6(i);
end
  
% ==========================solve=================================
ops = sdpsettings('solver','gurobi','verbose',0);
optimize(constraints,objective,ops)
opx=value(x); % value of variable x
opa=value(a);
obj=value(objective); % value of objective function
toc