clear;
load tables.mat % load tasks of three systems (taskTable), horizon length (time_horizon), R (Power_Resource, Comm_Resource, Trans_Resource)and P (precedenceTable) 
tic
%======================= parameters===========================
H=time_horizon; % horizon length
K=[4, 4, 4]; %  for three systems resource type length

% if Seperate_Scheduling==1
for k=1:size(taskTable,2)
I(k)=size(taskTable{1,k},1); % number of tasks
r{k}=reshape([taskTable{1,k}{:,11:14}],[size(taskTable{1,k},1),K(k)]);% number of type k resource needed for task i
end
% end
 

 % time duration for each task to be finished
for k=1:size(taskTable,2)
    for i=1:size(taskTable{1,k},1)
      if isempty(taskTable{1,k}{i,10}) % to aviod the 0s
        t{k}(i)=0;
      else
        t{k}(i)=[taskTable{1,k}{i,10}];
      end
    end
end





% the number of available type k resource
R{1}=Power_Resource;R{2}=Comm_Resource; R{3}=Trans_Resource;


% predecessor matrix of tasks
for i=1:size(precedenceTable,2)
P{i}=precedenceTable{1,i}(2:end,2:end); 
end



M=1e10; % A big enough number for if-then constraint

% z=zeros(1,I); % parameter for constraint 2 predecessor calculation
for k=1:size(taskTable,2)
for i=1:I(k)
    z{k}(i)=i;
end
end

% ==========================variable===============================
for kk=1:size(taskTable,2)
x=intvar(I(kk),H); % the number of type k resources that should be sent to task i in time horizon h
a=binvar(I(kk),H); % applied to transfer if-then constraint

% =========================constraints================================

% c1: at any period, the resource used by all tasks cannot exceed the total
% number of resource available
constraints=[];
for k=1:K
    for h=1:H
        temp7=transpose(x(:,h))*r{kk}(:,k);
        constraints=[constraints,temp7<=R{kk}(k)];
    end;
end;

% c2: precedence constraints
for i=1:I
    J=cell2mat(P{kk}(i,:)).*z{kk};
    J1=nonzeros(J);
    if isempty(J1)~=0
        for h=2:H
            temp=M*a(i,h);
            temp2=sum(x(:,1:h-1),2);
            for j=J1
                temp=temp-t{kk}(j)-temp2(j); % check -temp2(j) or +temp2(j)
            end
            constraints=[constraints,temp>=0];
        end
        temp3=M*a(i,1);
        for j=J1
            temp3=temp3-t{kk}(j);
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
    constraints=[constraints,t{kk}(i)-temp4(i)>=0];
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
    objective=objective+t{kk}(i)-temp6(i);
end
  
% ==========================solve=================================
ops = sdpsettings('solver','gurobi','verbose',0);
optimize(constraints,objective,ops)
opx=value(x); % value of variable x
opa=value(a);
obj=value(objective); % value of objective function
xx{kk}=x;
aa{kk}=a;
opxx{kk}=opx;
clear x a constraints objective ops opx temp temp2 temp3 temp4 temp5 temp6 temp7
end
toc