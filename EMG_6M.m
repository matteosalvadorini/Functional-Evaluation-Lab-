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
data_trigger = data(:, 17);
%% PLOT RAW EMG DATA
page = 6;
for i = 1:16
    if mod(i-1, page) == 0
        figure('Units','normalized','Position',[0.1 0.1 0.8 0.8]);
        tl = tiledlayout(3, 2, 'TileSpacing', 'compact');
        title(tl, ['EMG Raw Data - Page ' num2str(ceil(i/page))]);
    end
    nexttile;
    n = size(data_emg, 1);
    t = (0:n-1) / fs_EMG;
    plot(t, data_emg(:,i));
    title(channel_names{i}, 'Interpreter', 'none');
    xlabel('Time (s)'); ylabel('Amplitude (mV)');
end

%% BAND-PASS FILTERING (EMG only, NOT trigger)
% 4th order Butterworth bandpass 20-400 Hz
W  = [20 400];
Wn = W / (fs_EMG / 2);
[b, a] = butter(4, Wn, 'bandpass');

% Replace NaN with 0 only for filtering
data_emg_clean = fillmissing(data_emg, 'constant', 0);
data_f = filtfilt(b, a, data_emg_clean);  % [N x 16]

%% PLOT FILTERED EMG
for i = 1:16
    if mod(i-1, page) == 0
        figure('Units','normalized','Position',[0.1 0.1 0.8 0.8]);
        tl = tiledlayout(3, 2, 'TileSpacing', 'compact');
        title(tl, ['EMG Filtered - Page ' num2str(ceil(i/page))]);
    end
    nexttile;
    n = size(data_f, 1);
    t = (0:n-1) / fs_EMG;
    plot(t, data_f(:,i));
    title(channel_names{i}, 'Interpreter', 'none');
    xlabel('Time (s)'); ylabel('Amplitude (mV)');
end

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

%% PER-MINUTE ANALYSIS (Fatigue + iEMG)
Ns   = round(60 * fs_EMG);        % samples per minute
nSeg = floor(N_samples / Ns);     % number of complete 1-min segments

fprintf('Total duration: %.1f min → %d complete segments\n', ...
        N_samples/fs_EMG/60, nSeg);

medFreq    = zeros(nSeg, 16);
areaMinuto = zeros(nSeg, 16);

for i = 1:nSeg
    idx_start = (i-1)*Ns + 1;
    idx_end   = i*Ns;

    for j = 1:16
        seg = data_f_clean(idx_start:idx_end, j);
        seg = seg(~isnan(seg));  % remove artifact samples

        if length(seg) < 100
            % Skip if too few clean samples remain
            medFreq(i,j)    = NaN;
            areaMinuto(i,j) = NaN;
            warning('Segment %d, channel %d: too few clean samples', i, j);
            continue
        end

        % A. Fatigue: Median Frequency
        medFreq(i,j) = medfreq(seg, fs_EMG);

        % B. iEMG: normalized area under rectified signal
        areaMinuto(i,j) = trapz(abs(seg)) / length(seg);
    end
end

%% SYMMETRY INDEX
% Standard formula: 0% = perfect symmetry, higher = more asymmetric
SI = zeros(nSeg, 1);
for i = 1:nSeg
    R = mean(areaMinuto(i, 1:8),  'omitnan');
    L = mean(areaMinuto(i, 9:16), 'omitnan');
    SI(i) = abs(R - L) / (0.5*(R + L)) * 100;
end

fprintf('\n--- SYMMETRY INDEX ---\n');
fprintf('Minute 1:  SI = %.2f%%\n', SI(1));
fprintf('Minute %d: SI = %.2f%%\n', nSeg, SI(end));

%% FATIGUE SLOPE
fprintf('\n--- FATIGUE SLOPE (medFreq trend) ---\n');
slopes = zeros(16,1);
for j = 1:16
    valid = ~isnan(medFreq(:,j));
    if sum(valid) >= 2
        p = polyfit(find(valid)', medFreq(valid,j), 1);
        slopes(j) = p(1);
        fprintf('%s: %.4f Hz/min\n', channel_names{j}, slopes(j));
    else
        slopes(j) = NaN;
        fprintf('%s: not enough data\n', channel_names{j});
    end
end

%% PLOT RESULTS

% --- iEMG Area: Right vs Left + Symmetry Index ---
figure('Name','iEMG Area - R vs L (6MWT)', ...
       'Units','normalized','Position',[0.1 0.1 0.8 0.4]);

subplot(1,2,1);
plot(1:nSeg, mean(areaMinuto(:,1:8),  2, 'omitnan'), '-ob', 'LineWidth',2); hold on;
plot(1:nSeg, mean(areaMinuto(:,9:16), 2, 'omitnan'), '-sr', 'LineWidth',2);
xlabel('Minute'); ylabel('iEMG (normalized)');
title('Mean iEMG - Right vs Left');
legend('Right leg','Left leg'); grid on;

subplot(1,2,2);
plot(1:nSeg, SI, '-ok', 'LineWidth',2);
xlabel('Minute'); ylabel('SI (%)');
title('Symmetry Index over 6MWT');
grid on;

% --- Median Frequency trend: Right leg ---
figure('Name','Fatigue (medFreq) - Right Leg', ...
       'Units','normalized','Position',[0.1 0.1 0.8 0.8]);
for j = 1:8
    subplot(2,4,j);
    plot(1:nSeg, medFreq(:,j), '-ob', 'LineWidth',1.5);
    title(channel_names{j}); 
    xlabel('Minute'); ylabel('MDF (Hz)');
    grid on;
end
sgtitle('Median Frequency Trend - Right Leg');

% --- Median Frequency trend: Left leg ---
figure('Name','Fatigue (medFreq) - Left Leg', ...
       'Units','normalized','Position',[0.1 0.1 0.8 0.8]);
for j = 9:16
    subplot(2,4,j-8);
    plot(1:nSeg, medFreq(:,j), '-sr', 'LineWidth',1.5);
    title(channel_names{j}); 
    xlabel('Minute'); ylabel('MDF (Hz)');
    grid on;
end
sgtitle('Median Frequency Trend - Left Leg');

% --- Fatigue slope summary bar chart ---
figure('Name','Fatigue Slope Summary', ...
       'Units','normalized','Position',[0.1 0.1 0.8 0.5]);
bar(slopes);
hold on;
yline(0, 'r--', 'LineWidth', 1.5);
xticks(1:16);
xticklabels(channel_names);
xtickangle(45);
ylabel('Slope (Hz/min)');
title('Fatigue Slope per Muscle (negative = fatigue)');
grid on;