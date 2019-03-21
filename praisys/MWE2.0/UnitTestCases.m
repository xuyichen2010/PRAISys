function tests = UnitTestCases
tests = functiontests(localfunctions);
end

% Test for DamageAndStop
function testDamageAndStop(testCase)
load Test_Data.mat
load shakemap2.mat
Pow = Total{1};
Comm = Total{2};
Trans = Total{3};

Library.DamageAndStop(IM,IMx,IMy, 1, 1, 1, Pow, Comm, Trans);

count = 0;
for i = 1:length(Pow)
    count = count + Library.countDamaged(Pow{i});
end

for i = 1:length(Comm)
    count = count + Library.countDamaged(Comm{i});
end

for i = 1:length(Trans)
    count = count + Library.countDamaged(Trans{i});
end

actSolution = 0;

if count > 0
    actSolution = 1;
end

expSolution = 1;
verifyEqual(testCase,actSolution,expSolution)
end

% Test for RepairSchedulePriority
function testRepairSchedulePriority(testCase)
load Test_Data.mat
load shakemap2.mat
Pow = Total{1};
Comm = Total{2};
Trans = Total{3};

Library.DamageAndStop(IM,IMx,IMy, 1, 1, 1, Pow, Comm, Trans);

actSolution = 0;

for i = 1:length(Pow)
    actSolution = actSolution + Library.countDamaged(Pow{i});
end

for i = 1:length(Comm)
    actSolution = actSolution + Library.countDamaged(Comm{i});
end

for i = 1:length(Trans)
    actSolution = actSolution + Library.countDamaged(Trans{i});
end

[PowSchedule, ~] = Library.RepairSchedulePriority('Power', Pow, 1000);
[CommSchedule, ~] = Library.RepairSchedulePriority('Communication', Comm, 1000);
[TransSchedule, ~] = Library.RepairSchedulePriority('Transportation', Trans, 1000);

expSolution = length(PowSchedule) + length(CommSchedule) + length(TransSchedule);

verifyEqual(testCase,actSolution,expSolution)
end

% Test for RepairSchedulEfficiency
function testRepairSchedulEfficiency(testCase)
load Test_Data.mat
load shakemap2.mat
Pow = Total{1};
Comm = Total{2};
Trans = Total{3};

Library.DamageAndStop(IM,IMx,IMy, 1, 1, 1, Pow, Comm, Trans);

actSolution = 0;

for i = 1:length(Pow)
    actSolution = actSolution + Library.countDamaged(Pow{i});
end

for i = 1:length(Comm)
    actSolution = actSolution + Library.countDamaged(Comm{i});
end

for i = 1:length(Trans)
    actSolution = actSolution + Library.countDamaged(Trans{i});
end

[PowSchedule, ~] = Library.RepairSchedulEfficiency('Power', 15, 450, Pow);
[CommSchedule, ~] = Library.RepairSchedulEfficiency('Communication', 15, 450, Comm);
[TransSchedule, ~] = Library.RepairSchedulEfficiency('Transportation', 30, 450, Trans);

expSolution = length(PowSchedule) + length(CommSchedule) + length(TransSchedule);

verifyEqual(testCase,actSolution,expSolution)
end

% Test for Repairation
function testRepairation(testCase)
load Test_Data.mat
load shakemap2.mat
Pow = Total{1};
Comm = Total{2};
Trans = Total{3};

Library.DamageAndStop(IM,IMx,IMy, 1, 1, 1, Pow, Comm, Trans);

[PowSchedule, ~] = Library.RepairSchedulePriority('Power', Pow, 1000);
[CommSchedule, ~] = Library.RepairSchedulePriority('Communication', Comm, 1000);
[TransSchedule, ~] = Library.RepairSchedulePriority('Transportation', Trans, 1000);

[PowFun, CommFun, TransFun] = Library.Repairation(450, 0, 0, 1000, 1000, 1000, 1, 1, 1, PowSchedule, CommSchedule, TransSchedule, Pow, Comm, Trans);

actSolution = (PowFun(450) + CommFun(450) + TransFun(450))/3;
expSolution = 1;
verifyEqual(testCase,actSolution,expSolution)
end
