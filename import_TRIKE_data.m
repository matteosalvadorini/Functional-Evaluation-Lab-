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
datatrike.cadence        = T.cadence;
datatrike.angle          = T.angle;
datatrike.linearVelocity = T.linearVelocity;
datatrike.powerLeft      = T.powerLeft;
datatrike.powerRight     = T.powerRight;
datatrike.totalDistance  = T.totalDistance;

fprintf('✅ Loaded %d rows from: %s\n', height(T), fullPath);
clear T