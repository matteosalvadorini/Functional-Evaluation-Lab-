function [datatrike, filename] = import_trike_data_function()

%% --- IMPORT TRIKE DATA ---

[fileName, filePath] = uigetfile('*.csv', 'Select a TRIKE CSV file');

if isequal(fileName, 0) || isequal(filePath, 0)
    error('No TRIKE file selected.');
end

fullPath = fullfile(filePath, fileName);

T = readtable(fullPath);

requiredCols = {'cadence', 'angle', 'linearVelocity', ...
                'powerLeft', 'powerRight', 'totalDistance'};

missing = requiredCols(~ismember(requiredCols, T.Properties.VariableNames));

if ~isempty(missing)
    error('Missing columns in TRIKE CSV: %s', strjoin(missing, ', '));
end

datatrike.cadence        = T.cadence;
datatrike.angle          = T.angle;
datatrike.linearVelocity = T.linearVelocity;
datatrike.powerLeft      = T.powerLeft;
datatrike.powerRight     = T.powerRight;
datatrike.totalDistance  = T.totalDistance;

filename = fileName;

fprintf('Loaded TRIKE file: %s\n', fileName);
fprintf('Rows loaded: %d\n', height(T));

end