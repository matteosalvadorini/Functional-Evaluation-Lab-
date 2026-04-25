% ── File picker ────────────────────────────────────────────────────────────────
[fileName, filePath] = uigetfile('*.csv', 'Select a CSV file');

if isequal(fileName, 0)
    error('No file selected.');
end

fullPath = fullfile(filePath, fileName);

% ── Load CSV ───────────────────────────────────────────────────────────────────
T = readtable(fullPath);

% ── Validate required columns ──────────────────────────────────────────────────
requiredCols = {'cadence', 'angle', 'linearVelocity', ...
                'powerLeft', 'powerRight', 'totalDistance'};

missing = requiredCols(~ismember(requiredCols, T.Properties.VariableNames));

if ~isempty(missing)
    error('Missing columns in CSV: %s', strjoin(missing, ', '));
end

% ── Save into struct ───────────────────────────────────────────────────────────
data.cadence        = T.cadence;
data.angle          = T.angle;
data.linearVelocity = T.linearVelocity;
data.powerLeft      = T.powerLeft;
data.powerRight     = T.powerRight;
data.totalDistance  = T.totalDistance;

fprintf('✅ Loaded %d rows from: %s\n', height(T), fullPath);
clear T