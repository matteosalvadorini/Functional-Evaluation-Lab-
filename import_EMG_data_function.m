function [data_resampled, target, filename, fullpath_emg] = import_EMG_data_function()
%IMPORT_EMG_DATA_FUNCTION Imports and resamples one EMG pedalling CSV file.
%
% This function asks the user to select one CSV file, reads the EMG and
% trigger channels, resamples all signals to a common sampling frequency,
% removes rows containing NaN values, and returns the final synchronized
% data inside the structure data_resampled.
%
% OUTPUTS:
%
% data_resampled:
%   Structure containing the trigger and the 16 EMG channels after
%   resampling, truncation to common length, and NaN removal.
%
% target:
%   Final sampling frequency used after resampling.
%
% filename:
%   Name of the selected CSV file.
%
% fullpath_emg:
%   Full path of the selected CSV file.

    %% --- 1. SELECT CSV FILE ---

    % Open a file selection window and ask the user to select a CSV file.
    [filename, pathname] = uigetfile('*.csv', 'Select a CSV file');

    % If the user closes the window or does not select any file, stop the
    % function and return an error.
    if isequal(filename,0) || isequal(pathname,0)
        error('No file selected.');
    end

    % Build the full file path by combining folder path and file name.
    fullpath_emg = fullfile(pathname, filename);


    %% --- 2. READ CSV FILE ---

    % Detect import options.
    % The CSV file is assumed to use:
    % - semicolon as column delimiter
    % - comma as decimal separator
    opts = detectImportOptions(fullpath_emg, ...
        'Delimiter', ';', ...
        'DecimalSeparator', ',');

    % Read the CSV file as a MATLAB table.
    data = readtable(fullpath_emg, opts);

    % Extract the list of variable names contained in the table.
    % This allows us to search columns by partial names instead of exact IDs.
    vars = data.Properties.VariableNames;


    %% --- 3. EXTRACT TRIGGER AND EMG CHANNELS ---

    % Find the trigger column.
    % We search for columns containing 'AnalogInputAdapter'.
    % If more than one exists, we take the last one, because in these files
    % the trigger is expected to be the last Analog Input Adapter column.
    trigger_idx = find(contains(vars, 'AnalogInputAdapter'), 1, 'last');

    % If no trigger column is found, stop the function.
    if isempty(trigger_idx)
        error('No AnalogInputAdapter column found. Cannot identify trigger channel.');
    end

    % Extract trigger signal as a numeric vector.
    trigger = data{:, trigger_idx};

    % Extract right-side muscle channels.
    rightTA  = getSingleColumn(data, vars, 'RightTA');
    rightGAL = getSingleColumn(data, vars, 'RightGAL');
    rightSOL = getSingleColumn(data, vars, 'RightSOL');
    rightGAM = getSingleColumn(data, vars, 'RightGAM');
    rightRF  = getSingleColumn(data, vars, 'RightRF');
    rightVM  = getSingleColumn(data, vars, 'RightVM');
    rightVL  = getSingleColumn(data, vars, 'RightVL');
    rightSM  = getSingleColumn(data, vars, 'RightSM');

    % Extract left-side muscle channels.
    leftTA  = getSingleColumn(data, vars, 'LeftTA');
    leftGAL = getSingleColumn(data, vars, 'LeftGAL');
    leftSOL = getSingleColumn(data, vars, 'LeftSOL');
    leftGAM = getSingleColumn(data, vars, 'LeftGAM');
    leftRF  = getSingleColumn(data, vars, 'LeftRF');
    leftVM  = getSingleColumn(data, vars, 'LeftVM');
    leftVL  = getSingleColumn(data, vars, 'LeftVL');
    leftSM  = getSingleColumn(data, vars, 'LeftSM');


    %% --- 4. DEFINE SAMPLING FREQUENCIES ---

    % Target sampling frequency after resampling.
    target = 2148;

    % Original trigger sampling frequency.
    fs_trigger = 2222.2222;

    % Original EMG channel sampling frequency.
    fs_channels = 2148.1481;

    % Compute rational resampling factors for the trigger.
    [up_trigger, down_trigger] = rat(target / fs_trigger);

    % Compute rational resampling factors for the EMG channels.
    [up_channel, down_channel] = rat(target / fs_channels);


    %% --- 5. RESAMPLE ALL SIGNALS ---

    % Resample trigger to the target sampling frequency.
    trigger_resampled = resample(trigger, up_trigger, down_trigger);

    % Resample right-side EMG channels.
    rightTA  = resample(rightTA,  up_channel, down_channel);
    rightGAL = resample(rightGAL, up_channel, down_channel);
    rightSOL = resample(rightSOL, up_channel, down_channel);
    rightGAM = resample(rightGAM, up_channel, down_channel);
    rightRF  = resample(rightRF,  up_channel, down_channel);
    rightVM  = resample(rightVM,  up_channel, down_channel);
    rightVL  = resample(rightVL,  up_channel, down_channel);
    rightSM  = resample(rightSM,  up_channel, down_channel);

    % Resample left-side EMG channels.
    leftTA  = resample(leftTA,  up_channel, down_channel);
    leftGAL = resample(leftGAL, up_channel, down_channel);
    leftSOL = resample(leftSOL, up_channel, down_channel);
    leftGAM = resample(leftGAM, up_channel, down_channel);
    leftRF  = resample(leftRF,  up_channel, down_channel);
    leftVM  = resample(leftVM,  up_channel, down_channel);
    leftVL  = resample(leftVL,  up_channel, down_channel);
    leftSM  = resample(leftSM,  up_channel, down_channel);


    %% --- 6. TRUNCATE ALL SIGNALS TO COMMON LENGTH ---

    % Find the shortest signal length after resampling.
    % This is needed because resampling can create slightly different
    % lengths between trigger and EMG channels.
    min_length = min([ ...
        length(trigger_resampled), ...
        length(rightTA), length(rightGAL), length(rightSOL), length(rightGAM), ...
        length(rightRF), length(rightVM), length(rightVL), length(rightSM), ...
        length(leftTA), length(leftGAL), length(leftSOL), length(leftGAM), ...
        length(leftRF), length(leftVM), length(leftVL), length(leftSM)]);

    % Truncate trigger to common length.
    trigger_resampled = trigger_resampled(1:min_length);

    % Truncate right-side channels to common length.
    rightTA_resampled  = rightTA(1:min_length);
    rightGAL_resampled = rightGAL(1:min_length);
    rightSOL_resampled = rightSOL(1:min_length);
    rightGAM_resampled = rightGAM(1:min_length);
    rightRF_resampled  = rightRF(1:min_length);
    rightVM_resampled  = rightVM(1:min_length);
    rightVL_resampled  = rightVL(1:min_length);
    rightSM_resampled  = rightSM(1:min_length);

    % Truncate left-side channels to common length.
    leftTA_resampled  = leftTA(1:min_length);
    leftGAL_resampled = leftGAL(1:min_length);
    leftSOL_resampled = leftSOL(1:min_length);
    leftGAM_resampled = leftGAM(1:min_length);
    leftRF_resampled  = leftRF(1:min_length);
    leftVM_resampled  = leftVM(1:min_length);
    leftVL_resampled  = leftVL(1:min_length);
    leftSM_resampled  = leftSM(1:min_length);


    %% --- 7. REMOVE NaN ROWS ---

    % Identify samples where at least one signal contains NaN.
    nan_rows = isnan(trigger_resampled) | ...
        isnan(rightTA_resampled)  | isnan(rightGAL_resampled) | ...
        isnan(rightSOL_resampled) | isnan(rightGAM_resampled) | ...
        isnan(rightRF_resampled)  | isnan(rightVM_resampled)  | ...
        isnan(rightVL_resampled)  | isnan(rightSM_resampled)  | ...
        isnan(leftTA_resampled)   | isnan(leftGAL_resampled)  | ...
        isnan(leftSOL_resampled)  | isnan(leftGAM_resampled)  | ...
        isnan(leftRF_resampled)   | isnan(leftVM_resampled)   | ...
        isnan(leftVL_resampled)   | isnan(leftSM_resampled);

    % Keep only samples where all channels are valid.
    valid_rows = ~nan_rows;


    %% --- 8. STORE FINAL DATA IN STRUCTURE ---

    % Store the trigger first.
    % This order is important because the analysis script uses struct2array.
    data_resampled.trigger_resampled = trigger_resampled(valid_rows);

    % Store right-side EMG channels.
    data_resampled.rightTA_resampled  = rightTA_resampled(valid_rows);
    data_resampled.rightGAL_resampled = rightGAL_resampled(valid_rows);
    data_resampled.rightSOL_resampled = rightSOL_resampled(valid_rows);
    data_resampled.rightGAM_resampled = rightGAM_resampled(valid_rows);
    data_resampled.rightRF_resampled  = rightRF_resampled(valid_rows);
    data_resampled.rightVM_resampled  = rightVM_resampled(valid_rows);
    data_resampled.rightVL_resampled  = rightVL_resampled(valid_rows);
    data_resampled.rightSM_resampled  = rightSM_resampled(valid_rows);

    % Store left-side EMG channels.
    data_resampled.leftTA_resampled  = leftTA_resampled(valid_rows);
    data_resampled.leftGAL_resampled = leftGAL_resampled(valid_rows);
    data_resampled.leftSOL_resampled = leftSOL_resampled(valid_rows);
    data_resampled.leftGAM_resampled = leftGAM_resampled(valid_rows);
    data_resampled.leftRF_resampled  = leftRF_resampled(valid_rows);
    data_resampled.leftVM_resampled  = leftVM_resampled(valid_rows);
    data_resampled.leftVL_resampled  = leftVL_resampled(valid_rows);
    data_resampled.leftSM_resampled  = leftSM_resampled(valid_rows);

end


%% --- LOCAL HELPER FUNCTION ---

function column_data = getSingleColumn(data, vars, keyword)
%GETSINGLECOLUMN Extracts one column from a table using a partial name.
%
% INPUTS:
%
% data:
%   MATLAB table containing all imported CSV columns.
%
% vars:
%   Cell array containing the names of all table variables.
%
% keyword:
%   Text pattern used to identify the required column.
%
% OUTPUT:
%
% column_data:
%   Numeric vector corresponding to the selected column.
%
% The function searches for variables containing the keyword.
% It stops with an error if:
% - no matching column is found
% - more than one matching column is found

    % Find all columns whose name contains the required keyword.
    idx = find(contains(vars, keyword));

    % Stop if no matching column is found.
    if isempty(idx)
        error(['No column found for keyword: ' keyword]);
    end

    % Stop if more than one column matches.
    % This avoids accidentally selecting the wrong channel.
    if numel(idx) > 1
        error(['More than one column found for keyword: ' keyword ...
               '. Please check variable names manually.']);
    end

    % Extract the selected column as a numeric vector.
    column_data = data{:, idx};

end