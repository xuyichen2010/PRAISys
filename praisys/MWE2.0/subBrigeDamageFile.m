%abutment
abutment = { %level1
             { %1st task
                
                    %1st element
                    {20}
                
             },
             {
                
                    {21},{{22},{23}},{24},{20}
                
             },
             {
                
                    {21},{{22},{23}},{24},{20}
                
             },
             {
                
                    {21},{{22},{23}},{24},{20}
                
             }
    };

a = reshape(abutment,1,4);
save('DamageAbutment.mat','a');

%abutment foundation


abutmentFoundation = { %level1
             { %1st task
                
                    %1st element
                    {{4},{32},{39}},{31},{40},{41},{42},{36},{37},{44},{43},{45},{38},{15}
                
             },
             {
                
                    {{4},{32},{39}},{31},{40},{41},{42},{36},{37},{44},{43},{45},{38},{15}
                
             },
             {
                
                    {{4},{32},{39}},{31},{40},{41},{42},{36},{37},{44},{43},{45},{38},{15}
                
             },
             {
                
                    {{4},{32},{39}},{31},{40},{41},{42},{36},{37},{44},{43},{45},{38},{15}
                
             }
    };

a = reshape(abutmentFoundation,1,4);
save('DamageAbutmentFoundation.mat','a');


%Approach Slab
ApproachSlab = { %level1
             { %1st task
                
                    %1st element
                    {29}
                
             },
             {
                
                    {30},{29}
                
             },
             {
                
                    {30},{29}
                
             },
             {
                
                   {30},{29}
                
             }
    };

a = reshape(ApproachSlab,1,4);
save('DamageApproachSlab.mat','a');

%Column Foundation
ColumnFoundation = { %level1
             { %1st task
                
                    %1st element
                    {{40},{32}},{5},{6},{33},{36},{37},{11},{13},{14}
                
             },
             {
                
                    {{40},{32}},{5},{6},{33},{36},{37},{11},{13},{14}
                
             },
             {
                
                    {{40},{32}},{5},{6},{33},{36},{37},{11},{13},{14}
                
             },
             {
                
                    {{40},{32}},{5},{6},{33},{36},{37},{11},{13},{14}
                
             }
    };

a = reshape(ColumnFoundation,1,4);
save('DamageColumnFoundation.mat','a');


%Column
Column = { %level1
             { %1st task
                
                    %1st element
                    {{1},{2}}
                
             },
             {
                
                    {{1},{2}}
                
             },
             {
                
                    {{3},{4}},{{5},{6}},{7},{8},{9},{10},{11},{12},{13},{14},{15}
                    
                
             },
             {
                {
                    52
                }
             }
    };

a = reshape(Column,1,4);
save('DamageColumn.mat','a');



%bearing
Bearing = { %level1
             { %1st task
                
                    %1st element
                    {4},{31},{17},{18},{19},{15}
                
             },
             {
                
                   {4},{31},{17},{18},{19},{15}
                
             },
             {
                
                   {4},{31},{17},{18},{19},{15}
                
             },
             {
                
                   {4},{31},{17},{18},{19},{15}
                
             }
    };

a = reshape(Bearing,1,4);
save('DamageBearing.mat','a');