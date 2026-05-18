

% Prompt user to pick a CSV file
[filename, pathname] = uigetfile('*.csv', 'Select a CSV file');
if isequal(filename,0) || isequal(pathname,0)
    error('No file selected.');
end
fullpath_emg = fullfile(pathname, filename);

% Detect import options with semicolon delimiter and comma decimal separator
opts = detectImportOptions(fullpath_emg, 'Delimiter', ';', 'DecimalSeparator', ',');

% Read table and save to data variable
data = readtable(fullpath_emg, opts);


%% TO RUN ONLY IN CASE OF EMG DATA FROM PEDALLING TESTS
% Resampling to perform in case of pedaling EMG data !!!

    %% TO RUN ONLY IN CASE OF EMG DATA FROM PEDALLING TESTS

vars = data.Properties.VariableNames;

% Trigger (always last Analog Input column)
trigger = data{:, contains(vars,'AnalogInputAdapter')};

% Right side muscles
rightTA  = data{:, contains(vars,'RightTA')};
rightGAL = data{:, contains(vars,'RightGAL')};
rightSOL = data{:, contains(vars,'RightSOL')};
rightGAM = data{:, contains(vars,'RightGAM')};
rightRF  = data{:, contains(vars,'RightRF')};
rightVM  = data{:, contains(vars,'RightVM')};
rightVL  = data{:, contains(vars,'RightVL')};
rightSM  = data{:, contains(vars,'RightSM')};

% Left side muscles
leftTA   = data{:, contains(vars,'LeftTA')};
leftGAL  = data{:, contains(vars,'LeftGAL')};
leftSOL  = data{:, contains(vars,'LeftSOL')};
leftGAM  = data{:, contains(vars,'LeftGAM')};
leftRF   = data{:, contains(vars,'LeftRF')};
leftVM   = data{:, contains(vars,'LeftVM')};
leftVL   = data{:, contains(vars,'LeftVL')};
leftSM   = data{:, contains(vars,'LeftSM')};
    
    target = 2148;
    fs_trigger = 2222.2222;
    fs_channels = 2148.1481;
    
    [up_trigger, down_trigger] = rat(target / fs_trigger);
    [up_channel, down_channel] = rat(target / fs_channels);

    trigger_resampled = resample(trigger, up_trigger, down_trigger);
    rightTA = resample(rightTA, up_channel, down_channel);
    rightGAL = resample(rightGAL, up_channel, down_channel);
    rightSOL = resample(rightSOL, up_channel, down_channel);
    rightGAM = resample(rightGAM, up_channel, down_channel);
    rightRF = resample(rightRF, up_channel, down_channel);
    rightVM = resample(rightVM, up_channel, down_channel);
    rightVL = resample(rightVL, up_channel, down_channel);
    rightSM = resample(rightSM, up_channel, down_channel);
    leftTA = resample(leftTA, up_channel, down_channel);
    leftGAL = resample(leftGAL, up_channel, down_channel);
    leftSOL = resample(leftSOL, up_channel, down_channel);
    leftGAM = resample(leftGAM, up_channel, down_channel);
    leftRF = resample(leftRF, up_channel, down_channel);
    leftVM = resample(leftVM, up_channel, down_channel);
    leftVL = resample(leftVL, up_channel, down_channel);
    leftSM = resample(leftSM, up_channel, down_channel);
    
    % Truncate to the minimum common length
    
    min_length = min([length(trigger_resampled), length(rightTA), ...
        length(rightGAL), length(rightSOL), length(rightGAM), ...
        length(rightRF), length(rightVM), length(rightVL), ...
        length(rightSM), length(leftTA), length(leftGAL), ...
        length(leftSOL), length(leftGAM), length(leftRF), ...
        length(leftVM), length(leftSM), length(leftVL)]);
    
    trigger_resampled = trigger_resampled(1 : min_length);
    rightTA_resampled = rightTA(1 : min_length);
    rightGAL_resampled = rightGAL(1 : min_length);
    rightSOL_resampled = rightSOL(1 : min_length);
    rightGAM_resampled = rightGAM(1 : min_length);
    rightRF_resampled = rightRF(1 : min_length);
    rightVM_resampled = rightVM(1 : min_length);
    rightVL_resampled = rightVL(1 : min_length);
    rightSM_resampled = rightSM(1 : min_length);
    leftTA_resampled = leftTA(1 : min_length);
    leftGAL_resampled = leftGAL(1 : min_length);
    leftSOL_resampled = leftSOL(1 : min_length);
    leftGAM_resampled = leftGAM(1 : min_length);
    leftRF_resampled = leftRF(1 : min_length);
    leftVM_resampled = leftVM(1 : min_length);
    leftSM_resampled = leftSM(1 : min_length);
    leftVL_resampled = leftVL(1 : min_length);
    
    % Remove NaN values
    
    nan_rows = isnan(trigger_resampled) | isnan(rightTA_resampled) ...
        | isnan(rightGAL_resampled) | isnan(rightSOL_resampled) ...
        | isnan(rightGAM_resampled) | isnan(rightRF_resampled) ...
        | isnan(rightVM_resampled) | isnan(rightVL_resampled) ...
        | isnan(rightSM_resampled) | isnan(leftTA_resampled) ...
        | isnan(leftGAL_resampled) | isnan(leftSOL_resampled) ...
        | isnan(leftGAM_resampled) | isnan(leftRF_resampled) ...
        | isnan(leftVM_resampled) | isnan(leftSM_resampled) ...
        | isnan(leftVL_resampled);
    
    % Store in a single data structure 
    data_resampled.trigger_resampled = trigger_resampled(~nan_rows);
    data_resampled.rightTA_resampled = rightTA_resampled(~nan_rows);
    data_resampled.rightGAL_resampled = rightGAL_resampled(~nan_rows);
    data_resampled.rightSOL_resampled = rightSOL_resampled(~nan_rows);
    data_resampled.rightGAM_resampled = rightGAM_resampled(~nan_rows);
    data_resampled.rightRF_resampled = rightRF_resampled(~nan_rows);
    data_resampled.rightVM_resampled = rightVM_resampled(~nan_rows);
    data_resampled.rightVL_resampled = rightVL_resampled(~nan_rows);
    data_resampled.rightSM_resampled = rightSM_resampled(~nan_rows);
    data_resampled.leftTA_resampled = leftTA_resampled(~nan_rows);
    data_resampled.leftGAL_resampled = leftGAL_resampled(~nan_rows);
    data_resampled.leftSOL_resampled = leftSOL_resampled(~nan_rows);
    data_resampled.leftGAM_resampled = leftGAM_resampled(~nan_rows);
    data_resampled.leftRF_resampled = leftRF_resampled(~nan_rows);
    data_resampled.leftVM_resampled = leftVM_resampled(~nan_rows);
    data_resampled.leftSM_resampled = leftSM_resampled(~nan_rows);
    data_resampled.leftVL_resampled = leftVL_resampled(~nan_rows);
%%


