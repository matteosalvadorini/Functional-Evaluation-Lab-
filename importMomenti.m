function momenti = importMomenti(filename, startRow, endRow)

% IMPORTMOMENTI Import numeric data from a text file as a matrix.
%   MOMENTI = IMPORTMOMENTI(FILENAME)
%   Reads data from text file FILENAME for the default selection.
%
%   MOMENTI = IMPORTMOMENTI(FILENAME, STARTROW, ENDROW)
%   Reads data from rows STARTROW through ENDROW of text file FILENAME.

%% Initialize variables.
if nargin<=2
    startRow = 6;
    endRow = inf;
end

%% Read columns of data as text:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%8s%*11*s%*11*s%*11*s%*11*s%*11*s%*11*s%*11*s%*11*s%*11*s%*11*s%*11*s%*11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this code. If an error occurs for a different file, try regenerating the code from the Import Tool.
textscan(fileID, '%[^\n\r]', startRow(1)-1, 'WhiteSpace', '', 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'ReturnOnError', false, 'EndOfLine', '\r\n');
for block=2:length(startRow)
    frewind(fileID);
    textscan(fileID, '%[^\n\r]', startRow(block)-1, 'WhiteSpace', '', 'ReturnOnError', false);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'ReturnOnError', false, 'EndOfLine', '\r\n');
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric text to numbers.
% Replace non-numeric text with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29]
    % Converts text in the input cell array to numbers. Replaced non-numeric text with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1)
        % Create a regular expression to detect and remove non-numeric prefixes and suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData(row), regexstr, 'names');
            numbers = result.numbers;

            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if numbers.contains(',')
                thousandsRegExp = '^[-/+]*\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'))
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric text to numbers.
            if ~invalidThousandsSeparator
                numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch
            raw{row, col} = rawData{row};
        end
    end
end


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells

%% Create output variable
momenti = table;
momenti.Sample = cell2mat(raw(:, 1));
momenti.tRAFEM = cell2mat(raw(:, 2));
momenti.tRAFES = cell2mat(raw(:, 3));
momenti.tRKFEM = cell2mat(raw(:, 4));
momenti.tRKFES = cell2mat(raw(:, 5));
momenti.tRKAAM = cell2mat(raw(:, 6));
momenti.tRKAAS = cell2mat(raw(:, 7));
momenti.tRKIEM = cell2mat(raw(:, 8));
momenti.tRKIES = cell2mat(raw(:, 9));
momenti.tRHPFEM = cell2mat(raw(:, 10));
momenti.tRHPFES = cell2mat(raw(:, 11));
momenti.tRHPAAM = cell2mat(raw(:, 12));
momenti.tRHPAAS = cell2mat(raw(:, 13));
momenti.tRHPIEM = cell2mat(raw(:, 14));
momenti.tRHPIES = cell2mat(raw(:, 15));
momenti.tLAFEM = cell2mat(raw(:, 16));
momenti.tLAFES = cell2mat(raw(:, 17));
momenti.tLKFEM = cell2mat(raw(:, 18));
momenti.tLKFES = cell2mat(raw(:, 19));
momenti.tLKAAM = cell2mat(raw(:, 20));
momenti.tLKAAS = cell2mat(raw(:, 21));
momenti.tLKIEM = cell2mat(raw(:, 22));
momenti.tLKIES = cell2mat(raw(:, 23));
momenti.tLHPFEM = cell2mat(raw(:, 24));
momenti.tLHPFES = cell2mat(raw(:, 25));
momenti.tLHPAAM = cell2mat(raw(:, 26));
momenti.tLHPAAS = cell2mat(raw(:, 27));
momenti.tLHPIEM = cell2mat(raw(:, 28));
momenti.tLHPIES = cell2mat(raw(:, 29));

