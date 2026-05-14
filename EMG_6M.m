%% EMG_6M.m — 6-Minute Walk Test EMG Analysis
% Fatigue (Median Frequency) + iEMG Area + Symmetry Index
% Assumes 'data' is already loaded as a matrix [N x 17] (16 EMG + 1 trigger)

%% PARAMETERS
fs_EMG = 2148.1481;

channel_names = {'Tibialis Ant R', 'Gastro Lat R', 'Soleus R', 'Gastro Med R', ...
                 'Rectus R', 'Vastus Lat R', 'Vastus Med R', 'Semitendinous R', ...
                 'Tibialis Ant L', 'Gastro Lat L', 'Soleus L', 'Gastro Med L', ...
                 'Rectus L', 'Vastus Lat L', 'Vastus Med L', 'Semitendinous L'};

% ADD THIS LINE — convert table to numeric matrix
data = table2array(data);

% Separate EMG and trigger
data_emg     = data(:, 1:16);



%% BAND-PASS FILTERING
% 4th order Butterworth bandpass 20-400 Hz
W  = [20 400];
Wn = W / (fs_EMG / 2);
[b, a] = butter(4, Wn, 'bandpass');

% Replace NaN with 0 only for filtering
data_emg_clean = fillmissing(data_emg, 'constant', 0);
data_f = filtfilt(b, a, data_emg_clean);  % [N x 16]



%% ARTIFACT REJECTION
% Remove samples where any channel exceeds 3x its standard deviation
threshold = 3;
N_samples = size(data_f, 1);
artifact_mask = false(N_samples, 1);

for j = 1:16
    ch = data_f(:,j);
    artifact_mask = artifact_mask | (abs(ch) > threshold * std(ch));
end

data_f_clean = data_f;
data_f_clean(artifact_mask, :) = NaN;

fprintf('Artifact samples removed: %d (%.1f%%)\n', ...
        sum(artifact_mask), 100*mean(artifact_mask));


%%

%% TARGETED MINUTE ANALYSIS (First Minute vs Last Minute)

% Define precise time windows in samples
Ns_1min = round(60 * fs_EMG); 

% First minute indices (0 to 60 seconds)
idx_start_first = 1;
idx_end_first   = Ns_1min;

% Last minute indices (Last 60 seconds of the actual recording)
idx_end_last    = N_samples;
idx_start_last  = N_samples - Ns_1min + 1;

% Initialize specific arrays for the two periods
area_first_min = zeros(1, 16);
area_last_min  = zeros(1, 16);
medFreq_first  = zeros(1, 16);
medFreq_last   = zeros(1, 16);

for j = 1:16
    % --- FIRST MINUTE PROCESSING ---
    seg_first = data_f_clean(idx_start_first:idx_end_first, j);
    seg_first = seg_first(~isnan(seg_first)); % Remove artifacts
    
    if length(seg_first) >= 100
        medFreq_first(j) = medfreq(seg_first, fs_EMG);
        % Integrated area with artifact compensation factor
        area_first_min(j) = (trapz(abs(seg_first)) * (1 / fs_EMG)) * (Ns_1min / length(seg_first));
    else
        medFreq_first(j)  = NaN;
        area_first_min(j) = NaN;
    end
    
    % --- LAST MINUTE PROCESSING ---
    seg_last = data_f_clean(idx_start_last:idx_end_last, j);
    seg_last = seg_last(~isnan(seg_last)); % Remove artifacts
    
    if length(seg_last) >= 100
        medFreq_last(j) = medfreq(seg_last, fs_EMG);
        % Integrated area with artifact compensation factor
        area_last_min(j) = (trapz(abs(seg_last)) * (1 / fs_EMG)) * (Ns_1min / length(seg_last));
    else
        medFreq_last(j)  = NaN;
        area_last_min(j) = NaN;
    end
end

%%


% --- NORMALIZATION RELATIVE TO FIRST MINUTE ---
% First minute becomes the 100% reference for each individual channel
area_first_min_norm = (area_first_min ./ area_first_min) * 100; % Will be all 100s
area_last_min_norm  = (area_last_min ./ area_first_min) * 100;

% --- PERCENTAGE REDUCTION CALCULATION ---
% Calculate the final amplitude reduction percentage (First Min vs Last Min)
percent_reduction = 100 - area_last_min_norm;
%%

mean_area_first_min=mean(area_first_min_norm);

mean_area_last_min=mean(area_last_min_norm);















