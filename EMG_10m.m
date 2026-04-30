%% EMG_10m.m — 10-Meter Walking Test EMG Analysis
% Per-step iEMG + Symmetry Index
% Requires: data [N x 17] already loaded (EMG cols 1-16, trigger col 17)

%% PARAMETERS
fs_EMG = 2148.1481;   % Correct EMG sampling frequency [Hz]

channel_names = {'Tibialis Ant R', 'Gastro Lat R', 'Soleus R', 'Gastro Med R', ...
                 'Rectus R', 'Vastus Lat R', 'Vastus Med R', 'Semitendinous R', ...
                 'Tibialis Ant L', 'Gastro Lat L', 'Soleus L', 'Gastro Med L', ...
                 'Rectus L', 'Vastus Lat L', 'Vastus Med L', 'Semitendinous L'};

% Convert table to matrix if needed
if istable(data)
    data = table2array(data);
end

% Separate EMG and trigger
data_emg     = data(:, 1:16);
data_trigger = data(:, 17);   % NOT filtered

%% PLOT RAW EMG
page = 6;
for i = 1:16
    if mod(i-1, page) == 0
        figure('Units','normalized','Position',[0.1 0.1 0.8 0.8]);
        tl = tiledlayout(3, 2, 'TileSpacing', 'compact');
        title(tl, ['EMG Raw Data (10mWT) - Page ' num2str(ceil(i/page))]);
    end
    nexttile;
    n = size(data_emg, 1);
    t = (0:n-1) / fs_EMG;
    plot(t, data_emg(:,i));
    title(channel_names{i}, 'Interpreter', 'none');
    xlabel('Time (s)'); ylabel('Amplitude (mV)');
end

%% BAND-PASS FILTERING (EMG only)
W  = [20 400];
Wn = W / (fs_EMG / 2);
[b, a] = butter(4, Wn, 'bandpass');   % 4th order

data_emg_clean = fillmissing(data_emg, 'constant', 0);
data_f = filtfilt(b, a, data_emg_clean);  % [N x 16]
%% ARTIFACT REJECTION — Combined approach
N_samples = size(data_f, 1);
data_f_clean = data_f;

for j = 1:16
    ch = data_f(:,j);
    
    % Step 1: Find the "quiet" baseline using median absolute deviation (MAD)
    % MAD is robust to outliers unlike std
    mad_val = median(abs(ch - median(ch)));
    sigma_robust = 1.4826 * mad_val;  % converts MAD to std equivalent
    
    % Step 2: Reject anything beyond 4x robust sigma
    artifact_idx = abs(ch) > 4 * sigma_robust;
    data_f_clean(artifact_idx, j) = NaN;
    
    fprintf('Channel %d (%s): %.1f%% samples removed\n', ...
        j, channel_names{j}, 100*mean(artifact_idx));
end


%% PLOT FILTERED EMG
for i = 1:16
    if mod(i-1, page) == 0
        figure('Units','normalized','Position',[0.1 0.1 0.8 0.8]);
        tl = tiledlayout(3, 2, 'TileSpacing', 'compact');
        title(tl, ['EMG Filtered (10mWT) - Page ' num2str(ceil(i/page))]);
    end
    nexttile;
    n = size(data_f, 1);
    t = (0:n-1) / fs_EMG;
    plot(t, data_f(:,i));
    title(channel_names{i}, 'Interpreter', 'none');
    xlabel('Time (s)'); ylabel('Amplitude (mV)');
end

%% ARTIFACT REJECTION — STEP 1: Global threshold (3x std)
N_samples = size(data_f, 1);
artifact_mask = false(N_samples, 1);
for j = 1:16
    ch = data_f(:,j);
    artifact_mask = artifact_mask | (abs(ch) > 3 * std(ch));
end
data_f_clean = data_f;
data_f_clean(artifact_mask, :) = NaN;

fprintf('Global artifact samples removed: %d (%.1f%%)\n', ...
        sum(artifact_mask), 100*mean(artifact_mask));

%% ARTIFACT REJECTION — STEP 2: Channel-specific 99th percentile clipping
% This fixes channels like Rectus R/L that have extreme motion spikes
for j = 1:16
    col = data_f_clean(:,j);
    p99 = prctile(abs(col(~isnan(col))), 99);
    data_f_clean(abs(data_f_clean(:,j)) > p99, j) = NaN;
end

fprintf('Channel-specific clipping applied (99th percentile per channel)\n');

%% GAIT SEGMENTATION (Virtual Heel Strike via Tibialis Anterior)
% Use BOTH left and right TA for robustness
ta_R = abs(data_f_clean(:,1));   % Tibialis Ant R
ta_L = abs(data_f_clean(:,9));   % Tibialis Ant L

% Fill NaN for peak detection only
ta_R(isnan(ta_R)) = 0;
ta_L(isnan(ta_L)) = 0;

% Smooth with low-pass filter
[b_lp, a_lp] = butter(4, 3/(fs_EMG/2), 'low');
ta_R_smooth = filtfilt(b_lp, a_lp, ta_R);
ta_L_smooth = filtfilt(b_lp, a_lp, ta_L);

% Adaptive threshold: 40% of max
thresh_R = 0.4 * max(ta_R_smooth);
thresh_L = 0.4 * max(ta_L_smooth);

min_step_samples = round(fs_EMG * 0.3);  % min 0.3s between steps

[~, hs_R] = findpeaks(ta_R_smooth, ...
    'MinPeakHeight',   thresh_R, ...
    'MinPeakDistance', min_step_samples);

[~, hs_L] = findpeaks(ta_L_smooth, ...
    'MinPeakHeight',   thresh_L, ...
    'MinPeakDistance', min_step_samples);

fprintf('\nRight heel strikes detected: %d\n', length(hs_R));
fprintf('Left heel strikes detected:  %d\n', length(hs_L));

if length(hs_R) < 2 || length(hs_L) < 2
    warning('Too few steps detected. Check MinPeakHeight threshold.');
end

%% GAIT TIMING PARAMETERS
% Use all heel strikes combined for timing
all_hs = sort([hs_R; hs_L]);

t_start   = all_hs(1)   / fs_EMG;
t_end     = all_hs(end) / fs_EMG;
walk_time = t_end - t_start;

distance  = 10;  % meters
speed_ms  = distance / walk_time;

n_steps   = length(all_hs) - 1;
cadence   = (n_steps / walk_time) * 60;  % steps/min

step_durations = diff(all_hs) / fs_EMG;
mean_step_dur  = mean(step_durations);

fprintf('\n--- 10mWT GAIT PARAMETERS ---\n');
fprintf('Walking time:   %.2f s\n', walk_time);
fprintf('Speed:          %.3f m/s\n', speed_ms);
fprintf('Cadence:        %.1f steps/min\n', cadence);
fprintf('Mean step dur:  %.3f s\n', mean_step_dur);
fprintf('Total steps:    %d\n', n_steps);

%% iEMG PER RIGHT STEPS (hs_R(s) → hs_R(s+1))
n_R = length(hs_R) - 1;
iEMG_right_steps = zeros(n_R, 16);

for s = 1:n_R
    idx_s = hs_R(s);
    idx_e = hs_R(s+1);
    for j = 1:16
        seg = data_f_clean(idx_s:idx_e, j);
        seg = seg(~isnan(seg));
        if length(seg) > 10
            iEMG_right_steps(s,j) = trapz(abs(seg)) / length(seg);
        else
            iEMG_right_steps(s,j) = NaN;
        end
    end
end

%% iEMG PER LEFT STEPS (hs_L(s) → hs_L(s+1))
n_L = length(hs_L) - 1;
iEMG_left_steps = zeros(n_L, 16);

for s = 1:n_L
    idx_s = hs_L(s);
    idx_e = hs_L(s+1);
    for j = 1:16
        seg = data_f_clean(idx_s:idx_e, j);
        seg = seg(~isnan(seg));
        if length(seg) > 10
            iEMG_left_steps(s,j) = trapz(abs(seg)) / length(seg);
        else
            iEMG_left_steps(s,j) = NaN;
        end
    end
end

%% MEAN iEMG ACROSS ALL STEPS
mean_iEMG_R_steps = mean(iEMG_right_steps, 1, 'omitnan');  % mean over right strides
mean_iEMG_L_steps = mean(iEMG_left_steps,  1, 'omitnan');  % mean over left strides

% Overall mean iEMG per muscle (average of R and L stride means)
mean_iEMG = (mean_iEMG_R_steps + mean_iEMG_L_steps) / 2;

%% SYMMETRY INDEX per muscle
% SI = 0% → perfect symmetry, higher → more asymmetric
SI_per_muscle = abs(mean_iEMG_R_steps - mean_iEMG_L_steps) ./ ...
                (0.5 * (mean_iEMG_R_steps + mean_iEMG_L_steps)) * 100;

% Overall SI: comparing right leg muscles vs left leg muscles
R_total = mean(mean_iEMG(1:8),  'omitnan');
L_total = mean(mean_iEMG(9:16), 'omitnan');
SI_overall = abs(R_total - L_total) / (0.5*(R_total + L_total)) * 100;

fprintf('\n--- MUSCULAR SYMMETRY ---\n');
fprintf('Mean iEMG Right leg: %.4f mV\n', R_total);
fprintf('Mean iEMG Left leg:  %.4f mV\n', L_total);
fprintf('Overall Symmetry Index: %.2f%%\n', SI_overall);

%% PLOTS

% --- Mean iEMG per muscle bar chart ---
figure('Name','Mean iEMG per Muscle (10mWT)', ...
       'Units','normalized','Position',[0.1 0.1 0.8 0.5]);
bar(mean_iEMG);
xticks(1:16);
xticklabels(channel_names);
xtickangle(45);
ylabel('iEMG (normalized)');
title('Mean iEMG per Muscle - 10mWT');
hold on;
xline(8.5, 'r--', 'LineWidth', 2);
legend({'iEMG', 'R|L boundary'});
grid on;

% --- SI per muscle bar chart ---
figure('Name','SI per Muscle (10mWT)', ...
       'Units','normalized','Position',[0.1 0.1 0.8 0.5]);
bar(SI_per_muscle);
xticks(1:16);
xticklabels(channel_names);
xtickangle(45);
ylabel('SI (%)');
title('Symmetry Index per Muscle - 10mWT');
hold on;
yline(SI_overall, 'r--', ...
      sprintf('Overall SI = %.1f%%', SI_overall), 'LineWidth', 1.5);
grid on;

% --- iEMG trend across right steps: R vs L muscles ---
figure('Name','iEMG Trend - Right Steps (10mWT)', ...
       'Units','normalized','Position',[0.1 0.1 0.8 0.4]);
plot(1:n_R, mean(iEMG_right_steps(:,1:8),  2, 'omitnan'), '-ob', 'LineWidth',2); hold on;
plot(1:n_R, mean(iEMG_right_steps(:,9:16), 2, 'omitnan'), '-sr', 'LineWidth',2);
xlabel('Right step number'); ylabel('iEMG (normalized)');
title('iEMG per Right Step - Right vs Left Muscles');
legend('Right leg muscles','Left leg muscles'); grid on;

% --- iEMG trend across left steps: R vs L muscles ---
figure('Name','iEMG Trend - Left Steps (10mWT)', ...
       'Units','normalized','Position',[0.1 0.1 0.8 0.4]);
plot(1:n_L, mean(iEMG_left_steps(:,1:8),  2, 'omitnan'), '-ob', 'LineWidth',2); hold on;
plot(1:n_L, mean(iEMG_left_steps(:,9:16), 2, 'omitnan'), '-sr', 'LineWidth',2);
xlabel('Left step number'); ylabel('iEMG (normalized)');
title('iEMG per Left Step - Right vs Left Muscles');
legend('Right leg muscles','Left leg muscles'); grid on;

% --- Example step: all muscles (middle right step) ---
step_to_plot = max(1, round(n_R/2));
idx_s = hs_R(step_to_plot);
idx_e = hs_R(step_to_plot+1);
t_step = (0:(idx_e-idx_s)) / fs_EMG;

figure('Name','Example Step - All Muscles (10mWT)', ...
       'Units','normalized','Position',[0.05 0.05 0.9 0.85]);
for i = 1:16
    subplot(4,4,i);
    seg = data_f(idx_s:idx_e, i);
    plot(t_step, seg, 'Color',[0.6 0.6 0.6]); hold on;
    % Moving average envelope
    win = round(fs_EMG * 0.05);  % 50ms window
    env = movmean(abs(seg), win);
    plot(t_step, env, 'r', 'LineWidth', 1.2);
    title(channel_names{i}); grid on; axis tight;
    xlabel('Time (s)');
end
sgtitle(['Example Gait Cycle - Right Step ' num2str(step_to_plot)]);

% --- Summary table in command window ---
fprintf('\n--- iEMG SUMMARY TABLE ---\n');
fprintf('%-20s %12s %12s %10s\n', 'Muscle', 'iEMG_R_step', 'iEMG_L_step', 'SI(%)');
fprintf('%s\n', repmat('-', 1, 58));
for j = 1:16
    fprintf('%-20s %12.4f %12.4f %10.2f\n', ...
        channel_names{j}, mean_iEMG_R_steps(j), mean_iEMG_L_steps(j), SI_per_muscle(j));
end
fprintf('%s\n', repmat('-', 1, 58));
fprintf('%-20s %12.4f %12.4f %10.2f\n', 'OVERALL', R_total, L_total, SI_overall);