clear;
clc;

results = runtests('UnitTestCases.m');

disp(results);
disp(table(results));