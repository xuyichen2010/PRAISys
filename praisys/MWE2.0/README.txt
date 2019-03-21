Readme file for MWE 2.0

IMPORTANT:
    To Debug the simulator, Change the parfor statement in the main.m to for. After debugging, change it back to improve
    the performance.

1. Objects file
    The objects are defined in the file that named by the object's class and followed by the .m extension. For example, 
    the Bridge objects are defined in the Bridge.m file.
    In each file, the properties of each object class are defined in the section under properties. The methods including 
    the constructor. If need to create a object, just call the constructor function and pass the corresponding parameter.

2. Input File
    The Input file is used to let simulator to read input data and also let user to select and input the configuration for 
    the simulation. The command that used in the input file is list below:
        a) Data
            This command is used to let simulator to read the data input file. Just list all file name with the extension 
            after the Data command. This version simulator only support .xlsx and .csv format.
        
        b) Nsamples
            This command is used to set how many different damaged state in the simulation.
        
        c) NRun
            This command is used to set how many different run for every damaged state.
        
        d) Map
            This command is used to select the hazard map by list the file name after the command.

        e) System
            This command is used to select the active system by list the all system will be simulated after the command.
        
        f) Profile_Num
            This is the switch for the profile function.(0 for turn off and 1 for turn on)

        g) Scheduler
            Select the scheduler by enter the number.

        h) ReSchedule
            This is the switch for the reschedule function.(0 for turn off other number to select specific reschedule 
            algorithm)

        i) Interdependence
            This is the switch for the Interdependence function.(0 for turn off other number to select specific 
            reschedule algorithm)

        j) Functionality_Power/Functionality_Comm/Functionality_Trans
            Select the algorithm to calculate the functionality for each system by put number after the command.

        k) Time
            Set the time length for the simulator in days.

        l) Power_Resource/Comm_Resource/Trans_Resource
            Set the resource limit for each system.

        m) Power_Priority/Comm_Priority/Trans_Priority
            Put the maximum priority ranking for each system in order for the priority schedule algorithm.
        
    In order to run the simulator correctly, every command above need to be in the input file and there must a valid 
    value after the command. For Power_Priority/Comm_Priority/Trans_Priority and Power_Resource/Comm_Resource/Trans_Resource, 
    a really large number like 1000 will also works. 

3. Library
    There are total two libraries in this simulator. First one is Library.m and the second one is Interface.m. The 
    Library.m file contain the all  functions that we are going to use for the simulation. The Interface.m file contain
    all functions that work as switches.
    
    A. Interface.m
    The interface.m is a the file that allow user to choose your own version function instead of the build-in functions.
    This version simulator only allowed user to use your own version functions include: RepairSchedule, RepairReSchedule,
    InterdependenceFactor and Functionality
        a) RepairSchedule
            The RepairSchedule function will allow user to choose different repair schedule algorithm. The function will take
            several inputs include: num(your algorithm case number), time(recovery time period), Max_Power, Max_Trans, Max_Comm 
            (resource limit for each system), Power_Priority, Comm_Priority, Trans_Priority(maximum priority ranking in each 
            system), active_power, active_comm, active_trans(flag to indicate active or not for each system), Power_Set, 
            Communication_Set, Transportation_Set(Data set for each system).

            In order to add to your algorithm, user need to create a case inside the switch statement. In your case, call your own
            function and you do not need to use all the inputs that provide by the RepairSchedule.

            At the end of the case, the schedule matrix and the data matrix are required to assign. The schedule matrix is a
            cell matrix that contain three string matrixes contain the recovery schedule information for each system which one 
            matrix for each system. Inside the string matrix, each element need to be a format as 'Class_of_object/Index_number_in_set/' 
            (ex, the string matrix for power system should be ['Branch/4',  'Branch/47', 'Branch/48', 'Branch/52', 'Branch/53', 
            'Branch/68', 'Branch/81', 'Generator/5', 'Generator/6', 'Bus/15', 'Bus/16', 'Bus/17', 'Bus/18',...]). The date matrix is a
            cell matrix that contain three number matrixes contain the starting date information for corresponding element in the string 
            matrix. It should just be a matrix with some number. (ex, the date matrix for power system should be [1,1,1,1,1,1,6,7,8,....])
            
            IMPORTANT: The order inside the Schedule cell matrix must be in [Power], [Comm], [Trans].There must be three matrix inside 
            the Schedule cell matrix even if some system is not being simulated. If power system is not be simulated, just put a empty 
            matrix in that place (ex. power system not being simulated, the Schedule variable should look like {[],[result of communication], 
            [result of transportation]}).

        b) RepairReSchedule
            The RepairReSchedule function will allow user to choose different reschedule algorithm. The function will take
            several inputs include: num(your algorithm case number), orig_Schedule(three system's original schedule), time(recovery time period), 
            Max_Power, Max_Trans, Max_Comm(resource limit for each system),Power_Set, Communication_Set, Transportation_Set(Data set for each system).

            In order to add to your algorithm, user need to create a case inside the switch statement. In your case, call your own
            function and you do not need to use all the inputs that provide by the RepairReSchedule.

            At the end of the case, the schedule matrix is required to assign. The schedule matrix is a cell matrix that contain 
            three string matrixes contain the recovery schedule information for each system which one matrix for each system. Inside the string 
            matrix, each element need to be a format as 'Class_of_object/Index_number_in_set/' (ex, the string matrix for power system should be ['Branch/4',  
            'Branch/47', 'Branch/48', 'Branch/52', 'Branch/81', 'Generator/5', 'Generator/6', 'Bus/15', 'Bus/16', 'Bus/17', 'Bus/18',...]).

            IMPORTANT: The elements like 'Branch/47/Working' inside the each string matrix in orig_Schedule means this object has already been fixed, 
            no need to re schedule. Only reschedule the elements like 'Bus/15' inside each string matrix in orig_Schedule.

        c) InterdependenceFactor
            The InterdependenceFactor will allow user to choose different reschedule algorithm. The function will take
            several inputs include: num(your algorithm case number), CurrentWorking_Power, CurrentWorking_Comm, CurrentWorking_Trans(Current 
            Working Set), Power_Set, Communication_Set, Transportation_Set(Data set for each system).

            In order to add to your algorithm, user need to create a case inside the switch statement. In your case, call your own
            function and you do not need to use all the inputs that provide by the InterdependenceFactor.

            IMPORTANT: you do not need to return anything from this function since you are modifying the Interdependence_Factor property
            for each element that is currently being repaired. The objects that are currently repaired information is in the CurrentWorking matrix
            which are three string matrixes. In each matrix, the element format is 'Class/Num/Working'(ex, current working power: ['Branch/19/Working', 
            'Branch/29/Working', 'Branch/31/Working', 'Branch/32/Working',....]). Use this information to access the object in the corresponding data set.

        d) Functionality
            The InterdependenceFactor will allow user to choose different reschedule algorithm. The function will take
            several inputs include: Interdependence_Num(your algorithm case number), CurrentWorking_Power, CurrentWorking_Comm, CurrentWorking_Trans(Current 
            Working Set), Power_Set, Communication_Set, Transportation_Set(Data set for each system).

            In order to add to your algorithm, user need to create a case inside the switch statement. In your case, call your own
            function and you do not need to use all the inputs that provide by the Functionality.

            At the end of the case, three numbers include Trans_Fun, Pow_Fun, Comm_Fun need to assigned. Each number is a result of the functionality
            that returned from your own algorithm.

    B. Library.m
    In this file, the functions are mainly used for the simulation process. The simulation process are divided into 7
    parts: Sampling, Damage Evaluation, Scheduler, Recovery, Functionality Calculation, Data Input and Data Management. 
        a) Sampling
            The Sampling function under the Sampling section in the library.m is used to generate all samples which 
            will be used in the simulation in .m file. The function will take number of samples, number of runs, hostname
            , shake map information(IM, IMx, IMy), and flag indicating active system(active_power, active_comm, 
            active_trans) as input and generate total number of sample times number of runs samples and save under the 
            mat folder.

        b) Damage Evaluation
            In the library, there are total 4 functions under damage evaluation section. The DamageAndStop function is 
            the main function which is used to evaluate the damage state and determine the cascading stop for the affected 
            objects. The other 3 functions are the helper functions for the DamageAndStop function. The DamageEval function 
            will calculate the damaged state for the input cell base on the shake map information. The StopedEval function 
            will evaluate all the cascading stopped objects in each infrastructure system if they are activated in the 
            simulation. The Prob_Failure function will calculate the probability of failure for a objects base on the 
            intensity from their geographic location on the shake map.

        c) Scheduler
            There are 6 functions under the scheduler section. The RepairSchedulePriority function will generate a schedule 
            base on the priority ranking for given system. The RepairSchedulEfficiency function will generate a schedule 
            that is the result of the optimal solution by using Groubi. The resource constrains and mean recovery time are
            used in this function. The RepairScheduleReScheduleMean is only used when the reschedule is turn on, this function
            will reschedule the objects that are not repair yet in the original schedule with interdependence information with
            the resource constrains and mean recovery time. The RepairScheduleReScheduleActual is the only used when the 
            reschedule is turn on, this function will reschedule the objects that are not repair yet in the original schedule 
            with interdependence information with the resource constrains and actual recovery time. The addInterdependence
            is the helper function for two reschedule function. This function will add the interdependence information into the 
            matrix for the optimizer. The countSchedule is also the helper function for the two reschedule functions, it will 
            count how many objects that are need to reschedule for the reschedule functions.

        d) Recovery
            There are total 10 functions under this section. The Repairation function is the main function that simulate the 
            recovery process. In the process, the simulator will first create one matrix for each system to represent the current
            working objects set with the resource limit. Calculate the actual recovery time for every object, and add damaged 
            objects to the current working matrix. And then find the minimal days to fix one objects across three system and jump
            to that day. Update the status for the repaired objects and calculate the functionality. Repeat the process until 
            every objects is fixed. The InterdenpendenceFactorCalculateBasic is the helper function to change the recovery speed 
            which will be influence by the interdependence. UpdateStatus is the helper function that will update the status of a
            fixed object. checkNeedReschedule is the helper function that check if the reschedule is needed after fix every damaged 
            object. AddCurrentWorking is the helper function that add damaged objects to the current working matrix when there is a
            space is available. CalculateActualTime and RepairTime are the helper function that calculate the actual recovery time 
            by using the mean and standard deviation. The FindMinDays function will find the minimal days to repair the one object 
            in the current working matrix and the WorkingProcess function will subtract the minimal days for every current repairing 
            objects in the current working matrix.

        e) Functionality Calculation
            There are total 3 functions under this section, one functionality calculation for each system. This version 
            simulator only calculate the percentage of the functional objects over total number of objects in each system. 
            For power system the functionality calculation is number of branch that has power over the total number of branch. 
            For communication system, the functionality calculation is the number of all functional objects over total number 
            of objects. For transportation system, the functionality calculation is the number of all functional roads over 
            total number of roads.

        f) Data Input
            The input file reading function under this section is used to read in the data file for each class and then 
            generate the proper data set for each class. The function will take the filename, three dictionaries (pow_check, 
            comm_check, trans_check) and three system set (Pow, Trans, Comm) as input. It will open the file according to 
            filename, and then check the if the data in the input file is valid using the corresponding dictionary. If the 
            data in the file is valid, it will create the object, read in all the properties values and add it to the system 
            set. 

        g) Data Management
            There are total 7 functions under this section. The SaveDataLog, SaveScheduleLog and SaveFunctionalityLog are used 
            to save the data, schedule and functionality information into txt file and save it under the txt folder. The 
            PlotFigure function will plot the functionality result and save it under the plot folder. The ResetData function is 
            used only in sampling process which reset data every time we create a new damaged state data. The CleanOldData and 
            CreateFolder are used every time run the simulator, these two function will clean the old data that store in the 
            folder and create new folders for the new simulation.

4. Output File
    The top level folder will named by the hostname of the machine that run the simulator. Inside the folder, there are total 
    three folders(txt, mat and plot). There are three type of file store in the mat folder. The Data_Sample_X_Run_X.mat contains 
    the data information for Sample X in Run X. Use load command in MATLAB to see the detail inside the file. The Functionality.mat
    contain the functionality result matrix and the Schedule.mat contain the result from the scheduler. The plot folder contains 
    the plot for each system's functionality result. The txt folder contain three txt file, data.txt, Functionality.txt and 
    Schedule.txt. These information in these three files and the flies in the mat folder has exactly the same but only in the 
    different file format. 

5. Unit Test 
    All unit test cases are list in the UnitTestCase.m. In order to add new test case, create a function and only take testCase as
    input. Inside the function, write your own algorithm. At the end of function, use verifyEqual(testCase,actSolution,expSolution)
    function to test the actual solution with the expected solution. 
    To run all unit test case, simply just run UnitTest.m script. There is no need to change anything in UnitTest.m file.