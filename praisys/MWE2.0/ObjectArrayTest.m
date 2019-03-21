filename = 'PowerPlants.xlsx';
index_Branch = 1;
index_Generator = 1;
tmp = strsplit(filename,'.');
name = tmp{1};
type = tmp{2};
index = 1;
if strcmp(type, 'xlsx')
    [num,txt,raw] = xlsread(filename);
elseif strcmp(type, 'csv')
    table = readtable(filename);
end
array = SystemGeneral.empty;
if strcmp('PowerPlants', name)
    for i = 2:length(raw)
        try
            if  ~isempty(txt(i,1))
                keySet = char(txt(i,1));
                valueSet = 1;
                newMap = containers.Map(keySet,valueSet);
                
                try
                    if ~isnan(num(i - 1,1))
                        cap = num(i - 1,1);
                    else
                        message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 2');
                        error(message);
                    end
                catch exception
                    msg = getReport(exception, 'basic');
                    disp(msg);
                    return;
                end
                
                try
                    if ~isempty(txt(i,3))
                        type = char(txt(i,3));
                    else
                        message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 3');
                        error(message);
                    end
                catch exception
                    msg = getReport(exception, 'basic');
                    disp(msg);
                    return;
                end
                
                try
                    if ~isnan(num(i - 1,4))
                        startlocation = num(i - 1,4);
                    else
                        message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 3');
                        error(message);
                    end
                catch exception
                    msg = getReport(exception, 'basic');
                    disp(msg);
                    return;
                end
                
                try
                    if ~isnan(num(i - 1,3))
                        endlocation = num(i - 1,3);
                    else
                        message = strcat('ERROR: Empty value in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                        error(message);
                    end
                catch exception
                    msg = getReport(exception, 'basic');
                    disp(msg);
                    return;
                end
                
                
                array{index} = Branch(int2str(index_Branch), cap, type, keySet, [startlocation, endlocation]);
                array{index + 1} = Generator(int2str(index_Generator), [startlocation, endlocation]);
                
                index_Branch = index_Branch + 1;
                index_Generator = index_Generator + 1;
                index = index + 2;
            else
                message = strcat('ERROR: Empty Name or Name already exist in file: ', filename, ' found at line: ', num2str(i), ' column: 4');
                error(message);
            end
        catch exception
            msg = getReport(exception, 'basic');
            disp(msg);
            return;
        end
    end
end