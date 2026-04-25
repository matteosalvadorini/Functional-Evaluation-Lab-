function angoli = importAngoli(filename, startRow, endRow)

% IMPORTANGOLI Import numeric data from a text file as a matrix.
%   ANGLES = IMPORTANGOLI(FILENAME)
%   Reads data from text file FILENAME for the default selection.
%
%   ANGLES = IMPORTANGOLI(FILENAME, STARTROW, ENDROW)
%   Reads data from rows STARTROW through ENDROW of text file FILENAME.

%% Initialize variables
if nargin<=2
    startRow = 6;
    endRow = inf;
end

%% Read columns of data as text:
% For more information, see the TEXTSCAN documentation
formatSpec = '%8s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%11s%20s%20s%20s%20s%21s%21s%21s%21s%23s%23s%23s%s%[^\n\r]';

%% Open the text file
fileID = fopen(filename,'r');

%% Read columns of data according to the format
% This call is based on the structure of the file used to generate this code. If an error occurs for a different file, try regenerating the code from the Import Tool
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

%% Close the text file
fclose(fileID);

%% Convert the contents of columns containing numeric text to numbers
% Replace non-numeric text with NaN
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57]
    % Converts text in the input cell array to numbers. Replaced non-numeric text with NaN
    rawData = dataArray{col};
    for row=1:size(rawData, 1)
        % Create a regular expression to detect and remove non-numeric prefixes and suffixes
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData(row), regexstr, 'names');
            numbers = result.numbers;

            % Detected commas in non-thousand locations
            invalidThousandsSeparator = false;
            if numbers.contains(',')
                thousandsRegExp = '^[-/+]*\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'))
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric text to numbers
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


%% Exclude rows with non-numeric cells
I = ~all(cellfun(@(x) (isnumeric(x) || islogical(x)) && ~isnan(x),raw),2); % Find rows with non-numeric cells
raw(I,:) = [];

%% Create output variable
angoli = table;
angoli.Sample = cell2mat(raw(:, 1));
angoli.aRAFEM = cell2mat(raw(:, 2));
angoli.aRAFES = cell2mat(raw(:, 3));
angoli.aRAIEM = cell2mat(raw(:, 4));
angoli.aRAIES = cell2mat(raw(:, 5));
angoli.aRKFEM = cell2mat(raw(:, 6));
angoli.aRKFES = cell2mat(raw(:, 7));
angoli.aRKAAM = cell2mat(raw(:, 8));
angoli.aRKAAS = cell2mat(raw(:, 9));
angoli.aRKIEM = cell2mat(raw(:, 10));
angoli.aRKIES = cell2mat(raw(:, 11));
angoli.aRHPFEM = cell2mat(raw(:, 12));
angoli.aRHPFES = cell2mat(raw(:, 13));
angoli.aRHPAAM = cell2mat(raw(:, 14));
angoli.aRHPAAS = cell2mat(raw(:, 15));
angoli.aRHPIEM = cell2mat(raw(:, 16));
angoli.aRHPIES = cell2mat(raw(:, 17));
angoli.aLAFEM = cell2mat(raw(:, 18));
angoli.aLAFES = cell2mat(raw(:, 19));
angoli.aLAIEM = cell2mat(raw(:, 20));
angoli.aLAIES = cell2mat(raw(:, 21));
angoli.aLKFEM = cell2mat(raw(:, 22));
angoli.aLKFES = cell2mat(raw(:, 23));
angoli.aLKAAM = cell2mat(raw(:, 24));
angoli.aLKAAS = cell2mat(raw(:, 25));
angoli.aLKIEM = cell2mat(raw(:, 26));
angoli.aLKIES = cell2mat(raw(:, 27));
angoli.aLHPFEM = cell2mat(raw(:, 28));
angoli.aLHPFES = cell2mat(raw(:, 29));
angoli.aLHPAAM = cell2mat(raw(:, 30));
angoli.aLHPAAS = cell2mat(raw(:, 31));
angoli.aLHPIEM = cell2mat(raw(:, 32));
angoli.aLHPIES = cell2mat(raw(:, 33));
angoli.aRPTILTM = cell2mat(raw(:, 34));
angoli.aRPTILTS = cell2mat(raw(:, 35));
angoli.aRPOBLIM = cell2mat(raw(:, 36));
angoli.aRPOBLIS = cell2mat(raw(:, 37));
angoli.aRPROTM = cell2mat(raw(:, 38));
angoli.aRPROTS = cell2mat(raw(:, 39));
angoli.aLPTILTM = cell2mat(raw(:, 40));
angoli.aLPTILTS = cell2mat(raw(:, 41));
angoli.aLPOBLIM = cell2mat(raw(:, 42));
angoli.aLPOBLIS = cell2mat(raw(:, 43));
angoli.aLPROTM = cell2mat(raw(:, 44));
angoli.aLPROTS = cell2mat(raw(:, 45));
angoli.MediaFlexextDxM = cell2mat(raw(:, 46));
angoli.MediaFlexextDxS = cell2mat(raw(:, 47));
angoli.MediaFlexextSxM = cell2mat(raw(:, 48));
angoli.MediaFlexextSxS = cell2mat(raw(:, 49));
angoli.MediaObliquitaDxM = cell2mat(raw(:, 50));
angoli.MediaObliquitaDxS = cell2mat(raw(:, 51));
angoli.MediaObliquitaSxM = cell2mat(raw(:, 52));
angoli.MediaObliquitaSxS = cell2mat(raw(:, 53));
angoli.MediaIntraextraDxM = cell2mat(raw(:, 54));
angoli.MediaIntraextraDxS = cell2mat(raw(:, 55));
angoli.MediaIntraextraSxM = cell2mat(raw(:, 56));
angoli.MediaIntraextraSxS = cell2mat(raw(:, 57));

