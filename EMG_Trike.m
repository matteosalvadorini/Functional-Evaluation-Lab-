%% EMG_Trike.m — FES-Cycling EMG Analysis
% Requires: data_resampled (struct from import_EMG_data.m)
%           target (resampling frequency = 2148 Hz)
%           target_cadence (30 or 50 RPM — set this before running!)

%% PARAMETERS — SET THESE BEFORE RUNNING
target_cadence = 35;   % Change to 50 for the 50 RPM session
fs_EMG = target;       % Should be 2148 Hz from import script

channel_names = {'Tibialis Ant R', 'Gastro Lat R', 'Soleus R', 'Gastro Med R', ...
                 'Rectus R', 'Vastus Lat R', 'Vastus Med R', 'Semitendinous R', ...
                 'Tibialis Ant L', 'Gastro Lat L', 'Soleus L', 'Gastro Med L', ...
                 'Rectus L', 'Vastus Lat L', 'Vastus Med L', 'Semitendinous L'};

%% CONVERT STRUCT TO MATRIX
% Trigger is column 1, EMG channels are columns 2-17
data_array = struct2array(data_resampled);
% data_array columns: [trigger, TA_R, GAL_R, SOL_R, GAM_R, RF_R, VL_R, VM_R, SM_R,
%                              TA_L, GAL_L, SOL_L, GAM_L, RF_L, VL_L, VM_L, SM_L]

trigger_col = 1;       % trigger is column 1
emg_cols    = 2:17;    % EMG channels are columns 2-17

n_samples = size(data_array, 1);
t = (0:n_samples-1)' / fs_EMG;

%% PLOT RAW EMG DATA (excluding trigger)
page = 6;
for i = 1:16
    if mod(i-1, page) == 0
        figure('Units','normalized','Position',[0.1 0.1 0.8 0.8]);
        tl = tiledlayout(3, 2, 'TileSpacing','compact');
        title(tl, ['EMG Raw Data (Trike) - Page ' num2str(ceil(i/page))]);
    end
    nexttile;
    plot(t, data_array(:, i+1));   % +1 because col 1 is trigger
    title(channel_names{i}, 'Interpreter','none');
    xlabel('Time (s)'); ylabel('Amplitude (mV)');
end

%% BAND-PASS FILTERING (EMG only, NOT trigger)
W  = [20 400];
Wn = W / (fs_EMG / 2);
[b, a] = butter(4, Wn, 'bandpass');   % 4th order

emg_raw   = data_array(:, emg_cols);  % [N x 16]
emg_clean = fillmissing(emg_raw, 'constant', 0);
data_f    = filtfilt(b, a, emg_clean);  % [N x 16]

%% PLOT FILTERED EMG
for i = 1:16
    if mod(i-1, page) == 0
        figure('Units','normalized','Position',[0.1 0.1 0.8 0.8]);
        tl = tiledlayout(3, 2, 'TileSpacing','compact');
        title(tl, ['EMG Filtered (Trike) - Page ' num2str(ceil(i/page))]);
    end
    nexttile;
    plot(t, data_f(:,i));
    title(channel_names{i}, 'Interpreter','none');
    xlabel('Time (s)'); ylabel('Amplitude (mV)');
end

%% TRIGGER-BASED CYCLE DETECTION
trigger_sig = data_array(:, trigger_col);

% Adaptive threshold: 50% of trigger max
trig_thresh = 0.5 * max(trigger_sig);
min_cycle_samples = round(fs_EMG * 0.5);  % min 0.5s between cycles

[~, locs_trig] = findpeaks(trigger_sig, ...
    'MinPeakHeight',   trig_thresh, ...
    'MinPeakDistance', min_cycle_samples);

fprintf('Pedaling cycles detected: %d\n', length(locs_trig)-1);

% Plot trigger with detected peaks
figure('Name','Trigger - Cycle Detection');
plot(t, trigger_sig, 'Color',[0.5 0.5 0.5]); hold on;
plot(t(locs_trig), trigger_sig(locs_trig), 'ro', 'MarkerFaceColor','r');
xlabel('Time (s)'); ylabel('Trigger (mV)');
title('Trigger Channel - Detected Cycle Starts');
grid on;

%% CADENCE FILTERING — keep only cycles at target ± 4 RPM
cycle_durations = diff(t(locs_trig));          % seconds per cycle
cycle_cadence   = 60 ./ cycle_durations;       % RPM

good_cycle = find(cycle_cadence >= target_cadence - 4 & ...
                  cycle_cadence <= target_cadence + 4);

fprintf('Good cycles (%.0f ± 4 RPM): %d out of %d\n', ...
        target_cadence, length(good_cycle), length(cycle_cadence));

% Plot cadence
figure('Name','Cadence per Cycle');
plot(cycle_cadence, '--*b'); hold on;
plot(good_cycle, cycle_cadence(good_cycle), '*r');
yline(target_cadence, 'k--');
yline(target_cadence+4, 'r:');
yline(target_cadence-4, 'r:');
xlabel('Cycle #'); ylabel('Cadence (RPM)');
title(['Cadence per Cycle — target: ' num2str(target_cadence) ' RPM']);
legend('All cycles','Good cycles','Target'); grid on;

%% TIME NORMALIZATION (0-360° per cycle) — ALL 16 EMG CHANNELS
AngBase = linspace(0, 359, 360);
n_cycles_total = length(locs_trig) - 1;

% EMG_mat: cell array {16 channels}, each [360 x n_cycles]
EMG_mat = cell(1, 16);
for m = 1:16
    EMG_mat{m} = zeros(360, n_cycles_total);
end

for i = 1:n_cycles_total
    idx_start = locs_trig(i);
    idx_end   = locs_trig(i+1);
    t_orig = linspace(idx_start, idx_end, idx_end - idx_start + 1);
    t_norm = linspace(idx_start, idx_end, 360);

    for m = 1:16   % FIXED: was 1:12, now correctly 1:16
        seg = data_f(idx_start:idx_end, m);
        EMG_mat{m}(:,i) = interp1(t_orig, seg, t_norm, 'spline');
    end
end

%% AMPLITUDE NORMALIZATION + MEAN PROFILE (good cycles only)
n_valid = length(good_cycle);

EMG_good      = cell(1, 16);
norm_value    = zeros(1, 16);
EMG_good_norm = cell(1, 16);
EMG_mean      = zeros(16, 360);
EMG_std       = zeros(16, 360);

for m = 1:16
    EMG_good{m} = EMG_mat{m}(:, good_cycle);  % [360 x n_valid]

    % Normalization: median of peak values across good cycles
    peak_vals    = max(abs(EMG_good{m}), [], 1);  % 1 x n_valid
    norm_value(m) = median(peak_vals);
    if norm_value(m) == 0, norm_value(m) = 1; end

    EMG_good_norm{m} = EMG_good{m} ./ norm_value(m);

    % Mean and std across cycles (dim 2 = cycles)
    EMG_mean(m,:) = mean(EMG_good_norm{m}, 2)';
    EMG_std(m,:)  = std(EMG_good_norm{m}, 0, 2)';
end

%% PLOT TRIGGER-BASED CYCLE DETECTION


figure('Name', 'Sincronizzazione Trigger e Canale 7');

% Subplot 1: Canale Trigger (1)
ax1 = subplot(2,1,1);
plot(t, data_array(:,1), 'Color', [0.4 0.4 0.4]); % Grigio
hold on;
plot(t(locs_trig), data_array(locs_trig, 1), 'ro', 'MarkerFaceColor', 'r'); % Picchi rossi
ylabel('Trigger [mV]');
title('Canale 17 - Picchi identificati');
grid on;

% Subplot 2: Canale 7 (EMG Rectus Femoralis)
ax2 = subplot(2,1,2);
plot(t, data_f(:,8), 'b'); % Blu
hold on;
% USIAMO GLI STESSI IDENTICI INDICI (locs_trig)
plot(t(locs_trig), data_f(locs_trig, 8), 'ro', 'MarkerFaceColor', 'r');
ylabel('EMG - Canale 7 [mV]');
xlabel('Tempo [s]');
title('Canale 7 - Punti di sincronizzazione');
grid on;

% Collega gli assi per lo zoom
linkaxes([ax1, ax2], 'x');




%% PLOT NORMALIZED MEAN PROFILES
c_cycles = [0.7 0.7 0.7];
c_mean   = [0 0.4470 0.7410];

for i = 1:16
    if mod(i-1, page) == 0
        figure('Units','normalized','Position',[0.1 0.1 0.8 0.8]);
        tl = tiledlayout(3, 2, 'TileSpacing','compact');
        title(tl, ['EMG Normalized Profiles (Trike) - Page ' num2str(ceil(i/page))]);
    end
    nexttile; hold on;

    % Individual cycles in grey
    plot(AngBase, EMG_good_norm{i}, 'Color', c_cycles, 'LineWidth', 0.5);
    % Mean in blue
    plot(AngBase, EMG_mean(i,:), 'Color', c_mean, 'LineWidth', 2);
    % ±1 SD dashed
    plot(AngBase, EMG_mean(i,:) + EMG_std(i,:), '--', 'Color', c_mean, 'LineWidth', 1);
    plot(AngBase, EMG_mean(i,:) - EMG_std(i,:), '--', 'Color', c_mean, 'LineWidth', 1);

    title(channel_names{i}, 'Interpreter','none');
    xlim([0 360]); xticks([0 90 180 270 360]);
    xlabel('Crank angle (°)'); ylabel('Norm. Amplitude');
    grid on;
end

%% iEMG AREA PER CYCLE AND MUSCLE
AUC = zeros(n_valid, 16);
for i = 1:n_valid
    for m = 1:16
        AUC(i,m) = trapz(AngBase, abs(EMG_good_norm{m}(:,i)));
    end
end

mean_AUC = mean(AUC, 1);  % 1x16

% Display table
T_results = table(channel_names', mean_AUC', ...
    'VariableNames', {'Muscle', 'Mean_iEMG_AUC'});
disp('--- MEAN iEMG AUC PER MUSCLE ---');
disp(T_results);

%% SYMMETRY INDEX (standard formula, per muscle pair, per cycle)
% Muscle pairs: TA, GastroLat, Soleus, GastroMed, Rectus, VastusLat, VastusMed, Semitend
muscle_pairs = {'TA','Gastro Lat','Soleus','Gastro Med', ...
                'Rectus','Vastus Lat','Vastus Med','Semitendinous'};

SI       = zeros(n_valid, 8);
for k = 1:8
    R = AUC(:, k);      % right muscle
    L = AUC(:, k+8);    % left muscle (homologous)
    SI(:,k) = abs(R - L) ./ (0.5*(R + L)) * 100;
end

SI_mean     = mean(SI, 1);
SI_abs_mean = mean(abs(SI), 1);

fprintf('\n--- SYMMETRY INDEX PER MUSCLE PAIR ---\n');
T_SI = table(muscle_pairs', SI_mean', SI_abs_mean', ...
    'VariableNames', {'Muscle_Pair','SI_mean_pct','SI_abs_mean_pct'});
disp(T_SI);

% Overall symmetry
area_R = mean(mean_AUC(1:8));
area_L = mean(mean_AUC(9:16));
SI_overall = abs(area_R - area_L) / (0.5*(area_R + area_L)) * 100;
fprintf('Overall Symmetry Index: %.2f%%\n', SI_overall);

%% PLOT iEMG BAR CHART
figure('Name','Mean iEMG per Muscle (Trike)', ...
       'Units','normalized','Position',[0.1 0.1 0.8 0.5]);
bar(mean_AUC);
hold on;
xline(8.5, 'r--', 'LineWidth', 2);
xticks(1:16); xticklabels(channel_names); xtickangle(45);
ylabel('Mean iEMG AUC (normalized)');
title(['Mean iEMG per Muscle — ' num2str(target_cadence) ' RPM']);
grid on;

%% PLOT SYMMETRY INDEX BAR CHART
figure('Name','Symmetry Index per Muscle Pair (Trike)', ...
       'Units','normalized','Position',[0.1 0.1 0.7 0.45]);
bar(SI_mean);
xticks(1:8); xticklabels(muscle_pairs); xtickangle(30);
ylabel('Mean SI (%)');
title(['Symmetry Index per Muscle Pair — ' num2str(target_cadence) ' RPM']);
yline(0, 'k--'); grid on;

%% EXAMPLE CYCLE PLOT (middle good cycle)
mid = good_cycle(round(end/2));
idx_s = locs_trig(mid);
idx_e = locs_trig(mid+1);
gradi = linspace(0, 360, idx_e - idx_s + 1);

figure('Name','Example Pedaling Cycle - All Muscles', ...
       'Units','normalized','Position',[0.05 0.05 0.9 0.85]);
for i = 1:16
    subplot(4,4,i);
    seg = data_f(idx_s:idx_e, i);
    env = movmean(abs(seg), round(fs_EMG*0.05));  % 50ms envelope
    plot(gradi, seg, 'Color',[0.7 0.7 0.7]); hold on;
    plot(gradi, env, 'b', 'LineWidth', 1.5);
    title(channel_names{i}); grid on;
    xlim([0 360]); xticks([0 90 180 270 360]);
    xlabel('Crank angle (°)');
end
sgtitle(['Example Pedaling Cycle — Cycle #' num2str(mid)]);fprintf('Indice di Simmetria Muscolare: %.2f%%\n', SI_muscolare);