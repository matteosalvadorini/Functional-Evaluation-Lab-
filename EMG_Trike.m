clear all
close all
clc

% PIPELINE OVERVIEW
%
% The aim of this script is to describe muscle activity during pedaling
% from two points of view: how much each muscle activates over the cycle,
% and when that activation happens.
%
% After import and resampling, the EMG channels are band-pass filtered to
% remove drift, movement artefacts and high-frequency noise. The trigger is
% kept separate and is used only to identify the pedaling cycles.
%
% The filtered EMG is then rectified. This makes the signal fully positive
% and allows the overall amount of activity to be quantified. For this
% reason, the rectified EMG is used to compute iEMG, which is the main
% quantity-based metric adopted here.
%
% Starting from the rectified EMG, a linear envelope is also extracted. The
% envelope is a smoother version of the signal and is easier to interpret
% over the cycle. It is therefore used for analyses that depend more on the
% shape and timing of the activation profile, such as timing parameters and
% co-contraction.
%
% The trigger peaks are used to divide the recording into pedaling cycles.
% Cadence is computed from consecutive peaks, and only cycles close to the
% target cadence are retained as good cycles, so that the analysis is
% performed on cycles produced at a comparable speed.
%
% Each good cycle is then time-normalized to 360 points, so that all cycles
% are expressed on the same 0°–360° scale. After that, amplitude
% normalization is performed muscle by muscle using the median peak across
% good cycles, in order to make the comparison across cycles more reliable.
%
% Once the rectified EMG has been normalized, iEMG is computed for each
% muscle and cycle. These values are then used to calculate the symmetry
% index between right and left homologous muscles, as well as a global
% symmetry index comparing the total activation of the two legs.
%
% The normalized envelope is used in a second stage. First, it is used to
% compute the co-contraction index (CCI) between selected antagonist muscle
% pairs. Second, it is used for timing analysis, by extracting onset,
% offset, burst duration, peak timing and peak amplitude for each muscle
% and each good cycle.
%
% Finally, right and left homologous muscles are compared also from a
% temporal point of view. Since the two legs are expected to work about
% 180° out of phase, the left side is shifted by 180° before the
% comparison. On this basis, temporal symmetry errors are computed and then
% combined into a Timing Score, where lower values indicate better
% temporal symmetry.



%% --- 1 IMPORT AND INITIAL DEFINITIONS ---

import_EMG_data

channels = {'Trigger','Tibialis Ant R', 'Gastro Lat R', 'Soleus R', 'Gastro Med R', ...
           'Rectus R', 'Vastus Lat R', 'Vastus Med R', 'Semitendinous R', ...
           'Tibialis Ant L', 'Gastro Lat L', 'Soleus L', 'Gastro Med L', ...
           'Rectus L', 'Vastus Lat L', 'Vastus Med L', 'Semitendinous L'};

muscle_names = channels(2:17);

pair_names_short = {'TA','Gastro Lat','Soleus','Gastro Med', ...
                    'Rectus','Vastus Lat','Vastus Med','Semitendinous'};

data_array = struct2array(data_resampled);

trig_raw = data_array(:,1);
emg_raw  = data_array(:,2:17);

fs_EMG = target;

if any(isnan(data_array), 'all')
    error('NaN values detected after import. Check import_EMG_data.')
end

n_samples = size(data_array,1);
t = (0:n_samples-1)' / fs_EMG;

%% --- 2 PLOT RAW SIGNALS --- 

page = 6;

for i = 1:17

    if mod(i-1, page) == 0
        figure('Units','normalized','Position',[0.1 0.1 0.8 0.8]);
        tl = tiledlayout(3,2,'TileSpacing','compact');
        on_page = ceil(i / page);
        title(tl, ['Raw signals - Page ' num2str(on_page)]);
    end

    nexttile;
    plot(t, data_array(:,i));
    title(channels{i}, 'Interpreter','none');
    xlabel('Time [s]');
    ylabel('Amplitude');
    grid on;
end

%% --- 3 BAND-PASS FILTERING ---
% A 5th-order Butterworth band-pass filter between 20 and 400 Hz is
% applied to the raw EMG signals. This step removes low-frequency drift
% and movement artefacts, as well as high-frequency noise, while preserving
% the main frequency content of the EMG signal.

W = [20 400];
Wn = W / (fs_EMG/2);
[b_bp, a_bp] = butter(5, Wn, 'bandpass');

emg_filt = filtfilt(b_bp, a_bp, emg_raw);

%% --- 4 EMG RECTIFICATION ---
% The filtered EMG signals are rectified by taking their absolute value.
% This makes all signal oscillations positive, so that the overall muscle
% activation can be quantified more easily.

emg_rect = abs(emg_filt);

%% --- 5 EMG ENVELOPE ---
% A low-pass Butterworth filter at 5 Hz is applied to the rectified EMG to
% obtain the linear envelope. This gives a smoother signal easier
% to interpret and useful to describe timing and shape of muscle
% activation during the cycle.

env_cutoff = 5;
Wenv = env_cutoff / (fs_EMG/2);
[b_env, a_env] = butter(4, Wenv, 'low');

emg_env = filtfilt(b_env, a_env, emg_rect);

%% --- 6 PLOT FILTERED / RECTIFIED / ENVELOPE ---

plot_sets = {emg_filt, 'EMG filtered'; ...
             emg_rect, 'EMG rectified'; ...
             emg_env,  'EMG envelope'};

for s = 1:size(plot_sets,1)

    current_data  = plot_sets{s,1};
    current_title = plot_sets{s,2};

    for i = 1:17

        if mod(i-1, page) == 0
            figure('Units','normalized','Position',[0.1 0.1 0.8 0.8]);
            tl = tiledlayout(3,2,'TileSpacing','compact');
            on_page = ceil(i / page);
            title(tl, [current_title ' - Page ' num2str(on_page)]);
        end

        nexttile;
        if i == 17
            plot(t, trig_raw);
            title('Trigger', 'Interpreter','none');
        else
            plot(t, current_data(:,i));
            title(channels{i+1}, 'Interpreter','none');
        end
        xlabel('Time [s]');
        ylabel('Amplitude');
        grid on;
    end
end

%% --- 7 CYCLE DETECTION ---
% Trigger peaks are detected throught 'findpeaks' and used as markers of 
% the pedaling cycles in order to segment the EMG activity cycle by cycle.
% only peaks of at least trig_thresh amplitude are considered.


trig_thresh = 0.5 * max(trig_raw);
min_cycle_samples = round(fs_EMG * 0.5);

[~, locs_trig] = findpeaks(trig_raw, 'MinPeakHeight', trig_thresh, 'MinPeakDistance', min_cycle_samples);

fprintf('Detected pedaling cycles: %d\n', length(locs_trig)-1);


figure('Name','Trigger / EMG synchronization');

ax1 = subplot(2,1,1);
plot(t, trig_raw, 'Color', [0.4 0.4 0.4]); hold on
plot(t(locs_trig), trig_raw(locs_trig), 'ro', 'MarkerFaceColor','r')
ylabel('Trigger [mV]')
title('Detected trigger peaks')
grid on

ax2 = subplot(2,1,2);
plot(t, emg_filt(:,7), 'b'); hold on
plot(t(locs_trig), emg_filt(locs_trig,7), 'ro', 'MarkerFaceColor','r')
ylabel('EMG [mV]')
xlabel('Time [s]')
title('Same trigger locations projected onto EMG')
grid on

linkaxes([ax1 ax2],'x')

%% --- 8 CADENCE AND GOOD CYCLES ---
% The cadence of each pedaling cycle is computed from the time interval
% between two consecutive trigger peaks. Only the cycles within +-4rpm wrt
% target cadence are retained in order to have cycles with more stable and
% comparable pedaling speed.

cycle_duration = diff(t(locs_trig));
cadence = 60 ./ cycle_duration;

target_cadence = 35;

good_cycles = find(cadence >= target_cadence-4 & cadence <= target_cadence+4);
n_valid = min(30, length(good_cycles));

fprintf('Good cycles selected: %d\n', n_valid);

cycle_idx = 1:length(cadence);

figure('Name','Cadence per cycle');
plot(cycle_idx, cadence, '--*b');
hold on;
plot(good_cycles, cadence(good_cycles), 'or', 'MarkerFaceColor','r');
yline(target_cadence,   'k--');
yline(target_cadence+4, 'r:');
yline(target_cadence-4, 'r:');
xlabel('Cycle number');
ylabel('Cadence [RPM]');
title(['Cadence per cycle - target: ' num2str(target_cadence) ' RPM']);
grid on;

%% --- 9 CYCLE SEGMENTATION AND TIME NORMALIZATION ---
% We normalize each cycle to 360 points so that all cycles have the same
% length and can be compared point by point.

% 1) to identify the start and the end of one pedaling cycle we use two
% consecutive trigger peaks. 
% 2) The portion of rectified EMG and envelope corresponding to that cycle
% is extracted
% 3) the original length of that cycle (number of samples) is interpolated
% to a new X axis with exactly 360 points
% 4) Saves the normalized cycle on the preallocated cell

n_cycles_total = length(locs_trig) - 1;
AngBase = linspace(0,359,360);

EMG_rect_cycles_norm = cell(n_cycles_total,1);
EMG_env_cycles_norm  = cell(n_cycles_total,1);

for c = 1:n_cycles_total

    idx_start = locs_trig(c);                              % 1)
    idx_end   = locs_trig(c+1) - 1;

    rect_cycle = emg_rect(idx_start:idx_end, :);           % 2)
    env_cycle  = emg_env(idx_start:idx_end, :);

    x_old = linspace(0,360,size(rect_cycle,1));            % 3)
    x_new = linspace(0,360,360);

    rect_norm = zeros(360,16);
    env_norm  = zeros(360,16);

    for m = 1:16
        rect_norm(:,m) = interp1(x_old, rect_cycle(:,m), x_new, 'spline');
        env_norm(:,m)  = interp1(x_old, env_cycle(:,m),  x_new, 'spline');
    end

    EMG_rect_cycles_norm{c} = rect_norm;                  % 4)
    EMG_env_cycles_norm{c}  = env_norm;
end

%% --- 10 AMPLITUDE NORMALIZATION ---
% We normalize the amplitude so that the signals can be compared more
% fairly across cycles and muscles. Without this step, some differences in
% EMG size could depend more on recording conditions than on the actual
% muscle activity, and this would make the comparison less reliable.

% 1) In each good cycle the peak value of each muscle is found separately on
% both rectified EMG and envelope
% 2) The median is computed and used as normalization factor for that
% muscle (if is 0 is replaced by 1 to avoid /0)
% 3) Each signal is divided by the corresponding normalization factor

rect_norm_factor = zeros(1,16);
env_norm_factor  = zeros(1,16);

for m = 1:16

    rect_peaks = zeros(n_valid,1);                                  % 1)
    env_peaks  = zeros(n_valid,1);

    for i = 1:n_valid
        cyc = good_cycles(i);

        rect_peaks(i) = max(EMG_rect_cycles_norm{cyc}(:,m));
        env_peaks(i)  = max(EMG_env_cycles_norm{cyc}(:,m));
    end

    rect_norm_factor(m) = median(rect_peaks);                       % 2)
    env_norm_factor(m)  = median(env_peaks);

    if rect_norm_factor(m) == 0
        rect_norm_factor(m) = 1;
    end
    if env_norm_factor(m) == 0
        env_norm_factor(m) = 1;
    end
end

EMG_rect_good_norm = cell(n_valid,1);
EMG_env_good_norm  = cell(n_valid,1);

for i = 1:n_valid
    cyc = good_cycles(i);

    EMG_rect_good_norm{i} = zeros(360,16);
    EMG_env_good_norm{i}  = zeros(360,16);

    for m = 1:16                                                   % 3)
        EMG_rect_good_norm{i}(:,m) = EMG_rect_cycles_norm{cyc}(:,m) / rect_norm_factor(m);
        EMG_env_good_norm{i}(:,m)  = EMG_env_cycles_norm{cyc}(:,m)  / env_norm_factor(m);
    end
end

%% --- 11 PLOT NORMALIZED ENVELOPE PROFILES ---
% Good cycles in gray, mean and SD in blue

c_cycles = [0.7 0.7 0.7];
c_mean   = [0 0.4470 0.7410];

EMG_env_mean = zeros(16,360);
EMG_env_std  = zeros(16,360);

for m = 1:16

    temp_mat = zeros(360, n_valid);

    for i = 1:n_valid
        temp_mat(:,i) = EMG_env_good_norm{i}(:,m);
    end

    EMG_env_mean(m,:) = mean(temp_mat, 2)';
    EMG_env_std(m,:)  = std(temp_mat, 0, 2)';

    if mod(m-1, page) == 0
        figure('Units','normalized','Position',[0.1 0.1 0.8 0.8]);
        tl = tiledlayout(3,2,'TileSpacing','compact');
        title(tl, ['Normalized EMG envelope profiles - Page ' num2str(ceil(m/page))], ...
            'FontSize', 14);
    end

    nexttile;
    hold on;
    plot(AngBase, temp_mat, 'Color', c_cycles, 'LineWidth', 0.5);
    plot(AngBase, EMG_env_mean(m,:), 'Color', c_mean, 'LineWidth', 2);
    plot(AngBase, EMG_env_mean(m,:) + EMG_env_std(m,:), '--', 'Color', c_mean, 'LineWidth', 1);
    plot(AngBase, EMG_env_mean(m,:) - EMG_env_std(m,:), '--', 'Color', c_mean, 'LineWidth', 1);

    title(muscle_names{m}, 'Interpreter','none');
    xlim([0 360]);
    xticks([0 90 180 270 360]);
    xlabel('Crank angle [°]');
    ylabel('Normalized amplitude');
    grid on;
end

%% --- 12 EXAMPLE PEDALING CYCLE PLOT ---
% One good cycle, all muscles

mid_idx = round(n_valid/2);
cyc = good_cycles(mid_idx);

idx_s = locs_trig(cyc);
idx_e = locs_trig(cyc+1) - 1;
gradi = linspace(0,360,idx_e-idx_s+1);

figure('Name','Example pedaling cycle - all muscles', ...
       'Units','normalized','Position',[0.05 0.05 0.9 0.85]);

for m = 1:16
    subplot(4,4,m);

    seg_filt = emg_filt(idx_s:idx_e, m);
    seg_env  = emg_env(idx_s:idx_e, m);

    plot(gradi, seg_filt, 'Color',[0.7 0.7 0.7]);
    hold on;
    plot(gradi, seg_env, 'b', 'LineWidth', 1.5);

    title(muscle_names{m}, 'Interpreter','none');
    xlabel('Crank angle [°]');
    ylabel('Amplitude');
    xlim([0 360]);
    xticks([0 90 180 270 360]);
    grid on;
end
sgtitle(['Example pedaling cycle - cycle #' num2str(cyc)]);

%% --- 13 TOTAL ACTIVATION METRIC: iEMG ---
% iEMG is used as a measure of how much the muscle worked over
% the whole pedaling cycle. It sums the rectified EMG over the
% cycle

iEMG = zeros(n_valid,16);

for i = 1:n_valid
    for m = 1:16
        iEMG(i,m) = trapz(AngBase, EMG_rect_good_norm{i}(:,m));
    end
end

mean_iEMG = mean(iEMG, 1);

T_activation = table(muscle_names', mean_iEMG', ...
    'VariableNames', {'Muscle','Mean_iEMG'});

disp('--- TOTAL ACTIVATION METRIC: iEMG ---');
disp(T_activation);

%% --- 14 MUSCULAR SYMMETRY COMPUTATION ---
% The symmetry index is computed by comparing the iEMG of each right
% muscle with the iEMG of its matching left muscle. The mean value assumed 
% among all the good cycles is computed
% 
%
% Close to 0  -> good symmetry
% Positive    -> right side more active
% Negative    -> left side more active
% Absolute SI -> size of asymmetry, no matter the side

SI_iEMG = zeros(n_valid,8);

for k = 1:8
    R_i = iEMG(:,k);
    L_i = iEMG(:,k+8);

    SI_iEMG(:,k) = ((R_i - L_i) ./ (0.5*(R_i + L_i))) * 100;
end

SI_iEMG_mean     = mean(SI_iEMG, 1);
SI_iEMG_abs_mean = mean(abs(SI_iEMG), 1);

T_SI = table(pair_names_short', SI_iEMG_mean', SI_iEMG_abs_mean', ...
    'VariableNames', {'MusclePair', 'SI_iEMG_mean', 'SI_iEMG_abs_mean'});

disp('--- SYMMETRY INDEX PER MUSCLE PAIR ---');
disp(T_SI);

%% --- 15 GLOBAL SYMMETRY INDEX ---
% Here the total iEMG of all right-leg muscles is compared with the total
% iEMG of all left-leg muscles in order to  retrieve an overall symmetry value

iEMG_right_total = sum(iEMG(:,1:8), 2);
iEMG_left_total  = sum(iEMG(:,9:16), 2);

SI_global_iEMG = ((iEMG_right_total - iEMG_left_total) ./ ...
                 (0.5*(iEMG_right_total + iEMG_left_total))) * 100;

fprintf('\n--- GLOBAL SYMMETRY INDEX ---\n');
fprintf('SI_global_iEMG_mean     = %.2f\n', mean(SI_global_iEMG));
fprintf('SI_global_iEMG_abs_mean = %.2f\n', mean(abs(SI_global_iEMG)));

%% --- 16 CO-CONTRACTION INDEX (CCI) ---
% In this section the CCI is computed from the envelope, because the
% goal is not to measure how much the muscle works overall, but how much
% two antagonist muscles are active together during the cycle. For this,
% the envelope is more useful because it gives a smoother and clearer 
% profile of muscle activation over time.
%
% The CCI is calculated with the Falconer and Winter formula:
% CCI = 2 * sum(min(E1,E2)) / (sum(E1) + sum(E2))
% where E1 and E2 are the activation profiles of the two muscles.
% This formula compares the part of the two signals that
% overlaps with their total activation.
%
% Low CCI  -> little overlap between antagonist muscles 
% High CCI -> more overlap / more co-contraction

pair_names = { ...
    'TA_R vs GastroLat_R', ...
    'TA_R vs Soleus_R', ...
    'Rectus_R vs Semitend_R', ...
    'TA_L vs GastroLat_L', ...
    'TA_L vs Soleus_L', ...
    'Rectus_L vs Semitend_L'};

pairs = [ ...
    1 2;
    1 3;
    5 8;
    9 10;
    9 11;
    13 16];

n_pairs = size(pairs,1);
CCI_env = zeros(n_valid, n_pairs);

for c = 1:n_valid

    cycle_env = EMG_env_good_norm{c};

    for p = 1:n_pairs

        m1 = pairs(p,1);
        m2 = pairs(p,2);

        E1_env = cycle_env(:,m1);
        E2_env = cycle_env(:,m2);

        num_env = 2 * sum(min(E1_env, E2_env));
        den_env = sum(E1_env) + sum(E2_env);

        if den_env == 0
            CCI_env(c,p) = NaN;
        else
            CCI_env(c,p) = num_env / den_env;
        end
    end
end

CCI_env_mean = mean(CCI_env, 1, 'omitnan');
CCI_env_std  = std(CCI_env, 0, 1, 'omitnan');

T_CCI = table(pair_names', CCI_env_mean', CCI_env_std', ...
    'VariableNames', {'MusclePair', 'CCI_env_mean', 'CCI_env_std'});

disp('--- CCI RESULTS ---');
disp(T_CCI);

%% --- 17 TIMING ANALYSIS FROM THE ENVELOPE ---
% Timing analysis is carried out on the envelope because we are interested 
% in understanding when the muscle is active during the pedaling cycle 
% instead of simple overall activation. 
% Envelope has a smoother and more readable activation profile, so it is 
% easier to identify the main activation phase
%
% For each good cycle and for each muscle, we extract: 
%  - onset angle (when the muscle starts to become active)
%  - offset angle (when it stops)
%  - burst duration (how long it stays active)
%  - peak timing (where the maximum activation occurs)
%  - peak amplitude. 
% These values may be used to describe temporal stability, regularity and simmetry
% of activation
%
% 1) for each muscle, we look for the maximum value of the profile and
%    store both the peak amplitude and the angle where that peak occurs
% 2) we mark the points of the cycle where the envelope is above threshold 
% -> where the muscle is considered active (if E > thr -> active = 1)
% 3) we duplicate the activity vector so that a burst crossing the end of the
%    cycle can still be treated as one continuous activation instead
%    of being split into two separate parts
% 4) we find all active segments and keep the longest one (main activation
%    burst of the muscle)
% 5) we convert the start and end of that burst into onset and offset
%    angles
% 6) we compute the burst duration taking into account also the case in
%    which the burst wraps around the end of the cycle


k_thr = 3;              % threshold = baseline_mean + k_thr * baseline_std
baseline_prct = 30;     % use the lowest 30% of the envelope samples as baseline
n_points = 360;

onset_angle    = NaN(n_valid,16);
offset_angle   = NaN(n_valid,16);
burst_duration = NaN(n_valid,16);
peak_angle     = NaN(n_valid,16);
peak_amplitude = NaN(n_valid,16);
thr_used       = NaN(n_valid,16);

for c = 1:n_valid

    cycle_env = EMG_env_good_norm{c};

    for m = 1:16

        E = cycle_env(:,m);                                     % 1)

        [peak_amplitude(c,m), idx_peak] = max(E);
        peak_angle(c,m) = AngBase(idx_peak);

        if peak_amplitude(c,m) <= 0
            continue
        end

        % 2) Estimate baseline from the low-activity portion of the cycle
        base_limit = prctile(E, baseline_prct);
        baseline_samples = E(E <= base_limit);

        if isempty(baseline_samples)
            continue
        end

        baseline_mean = mean(baseline_samples);
        baseline_std  = std(baseline_samples);

        % 3) Adaptive threshold
        thr = baseline_mean + k_thr * baseline_std;
        thr_used(c,m) = thr;

        % Safety check: threshold should not exceed the peak
        if thr >= peak_amplitude(c,m)
            thr = 0.8 * peak_amplitude(c,m);
            thr_used(c,m) = thr;
        end

        % 4) Active points above threshold
        active = E >= thr;

        if ~any(active)
            continue
        end

        % Duplicate logical vector to handle bursts crossing 360 -> 0
        active_ext = [active; active];

        % If the peak is also active in the duplicated copy, move the peak
        idx_peak_ext = idx_peak;
        if active_ext(idx_peak + n_points)
            idx_peak_ext = idx_peak + n_points;
        end

        % 5) Find all active segments and keep the one containing the peak
        d = diff([0; active_ext; 0]);
        seg_start = find(d == 1);
        seg_end   = find(d == -1) - 1;

        idx_seg_peak = find(seg_start <= idx_peak_ext & seg_end >= idx_peak_ext, 1);

        if isempty(idx_seg_peak)
            continue
        end

        start_idx_ext = seg_start(idx_seg_peak);
        end_idx_ext   = seg_end(idx_seg_peak);

        onset_idx  = mod(start_idx_ext - 1, n_points) + 1;
        offset_idx = mod(end_idx_ext   - 1, n_points) + 1;

        onset_angle(c,m)  = AngBase(onset_idx);
        offset_angle(c,m) = AngBase(offset_idx);

        % 6) Burst duration
        if offset_angle(c,m) >= onset_angle(c,m)
            burst_duration(c,m) = offset_angle(c,m) - onset_angle(c,m);
        else
            burst_duration(c,m) = (360 - onset_angle(c,m)) + offset_angle(c,m);
        end
    end
end

% Mean values
onset_mean    = mean(onset_angle, 1, 'omitnan');
offset_mean   = mean(offset_angle, 1, 'omitnan');
duration_mean = mean(burst_duration, 1, 'omitnan');
peak_mean     = mean(peak_angle, 1, 'omitnan');
peak_amp_mean = mean(peak_amplitude, 1, 'omitnan');

% Variability across cycles
onset_std     = std(onset_angle, 0, 1, 'omitnan');
offset_std    = std(offset_angle, 0, 1, 'omitnan');
duration_std  = std(burst_duration, 0, 1, 'omitnan');
peak_std      = std(peak_angle, 0, 1, 'omitnan');
peak_amp_std  = std(peak_amplitude, 0, 1, 'omitnan');

TimingSummary = table(muscle_names', ...
    onset_mean', onset_std', ...
    offset_mean', offset_std', ...
    duration_mean', duration_std', ...
    peak_mean', peak_std', ...
    peak_amp_mean', peak_amp_std', ...
    'VariableNames', {'Muscle', ...
    'OnsetMean_deg','OnsetSD_deg', ...
    'OffsetMean_deg','OffsetSD_deg', ...
    'DurationMean_deg','DurationSD_deg', ...
    'PeakTimingMean_deg','PeakTimingSD_deg', ...
    'PeakAmpMean','PeakAmpSD'});

disp('--- TIMING ANALYSIS FROM ENVELOPE ---');
disp(TimingSummary);

%% --- 17B TIMING MEAN ± SD BAR PLOTS ---
% These plots show the mean temporal parameters of each muscle together
% with their standard deviation across good cycles.
% A lower SD means that the timing of that muscle is more stable from
% cycle to cycle, while a higher SD indicates greater variability.

x = 1:16;

figure('Name','Timing parameters per muscle (mean ± SD)', ...
       'Units','normalized','Position',[0.05 0.05 0.9 0.8]);

% --- Onset ---
subplot(2,2,1)
bar(x, onset_mean);
hold on;
errorbar(x, onset_mean, onset_std, 'k.', 'LineWidth', 1.2, 'CapSize', 10);
xticks(x);
xticklabels(muscle_names);
xtickangle(45);
ylabel('Degrees [°]');
title('Onset angle (mean ± SD)');
grid on;

% --- Offset ---
subplot(2,2,2)
bar(x, offset_mean);
hold on;
errorbar(x, offset_mean, offset_std, 'k.', 'LineWidth', 1.2, 'CapSize', 10);
xticks(x);
xticklabels(muscle_names);
xtickangle(45);
ylabel('Degrees [°]');
title('Offset angle (mean ± SD)');
grid on;

% --- Duration ---
subplot(2,2,3)
bar(x, duration_mean);
hold on;
errorbar(x, duration_mean, duration_std, 'k.', 'LineWidth', 1.2, 'CapSize', 10);
xticks(x);
xticklabels(muscle_names);
xtickangle(45);
ylabel('Degrees [°]');
title('Burst duration (mean ± SD)');
grid on;

% --- Peak timing ---
subplot(2,2,4)
bar(x, peak_mean);
hold on;
errorbar(x, peak_mean, peak_std, 'k.', 'LineWidth', 1.2, 'CapSize', 10);
xticks(x);
xticklabels(muscle_names);
xtickangle(45);
ylabel('Degrees [°]');
title('Peak timing (mean ± SD)');
grid on;

%% --- 18 TEMPORAL SYMMETRY ANALYSIS ---
% The timing of the right and left side is compared. Since in pedaling the 
% two legs are expected to work with about 180° shift, the left side is
% shifted by 180° before the comparison in order to check whether the two 
% sides are activating with the expected alternation.
%
% Three temporal symmetry measures are then computed for each pair of
% homologous muscles:
% - onset symmetry error -> how far the start of activation is
%   from the expected 180° shift
% - peak timing symmetry error -> how far the peak activation
%   is from that same expected shift
% - duration symmetry error -> how different the burst
%   duration is between the two sides
%
% These three values are combined into a single Timing Score, obtained
% as their average. Lower values mean better temporal symmetry, while
% higher values mean that the two sides are less well aligned in time.
% 
% 1) we shift the left-side value by 180°
% 2) we compute the circular difference between the right onset/peak 
%    timing and the shifted left onset/peak timing so that the error is 
%    measured correctly even when angles wrap around 360° to 0°
% 3) we take the absolute value of that circular difference and store it
%    as the onset/peak timing symmetry error: lower values -> better symmetry
% 4) for burst duration it takes the absolute difference between right and left


TimingSym_Onset    = NaN(n_valid,8);
TimingSym_Peak     = NaN(n_valid,8);
TimingSym_Duration = NaN(n_valid,8);

for k = 1:8
    R_idx = k;
    L_idx = k + 8;

    ideal_onset_L = mod(onset_angle(:,L_idx) + 180, 360);                      % 1)
    diff_onset = mod(onset_angle(:,R_idx) - ideal_onset_L + 180, 360) - 180;   % 2)
    TimingSym_Onset(:,k) = abs(diff_onset);                                    % 3)

    ideal_peak_L = mod(peak_angle(:,L_idx) + 180, 360);                        % 1)
    diff_peak = mod(peak_angle(:,R_idx) - ideal_peak_L + 180, 360) - 180;      % 2)
    TimingSym_Peak(:,k) = abs(diff_peak);                                      % 3)

    TimingSym_Duration(:,k) = abs(burst_duration(:,R_idx) - burst_duration(:,L_idx)); % 4)
end

% Mean values across cycles
TimingSym_Onset_mean    = mean(TimingSym_Onset, 1, 'omitnan');
TimingSym_Peak_mean     = mean(TimingSym_Peak, 1, 'omitnan');
TimingSym_Duration_mean = mean(TimingSym_Duration, 1, 'omitnan');

% Timing score:
% simple average of onset error, peak error and duration error
% Lower score = better temporal symmetry
TimingScore = (TimingSym_Onset_mean + TimingSym_Peak_mean + TimingSym_Duration_mean) / 3;

T_TimingSym = table(pair_names_short', ...
    TimingSym_Onset_mean', TimingSym_Peak_mean', TimingSym_Duration_mean', TimingScore', ...
    'VariableNames', {'MusclePair', ...
    'OnsetSymError_deg', ...
    'PeakSymError_deg', ...
    'DurationSymError_deg', ...
    'TimingScore'});

disp('--- TEMPORAL SYMMETRY ANALYSIS ---');
disp(T_TimingSym);

%% --- 19 TIMING SUMMARY BAR PLOTS ---

figure('Name','Timing summary per muscle pair', ...
       'Units','normalized','Position',[0.1 0.1 0.9 0.75]);

subplot(2,2,1)
bar(TimingSym_Onset_mean)
xticks(1:8); xticklabels(pair_names_short); xtickangle(30)
ylabel('Degrees')
title('Onset symmetry error')
grid on

subplot(2,2,2)
bar(TimingSym_Peak_mean)
xticks(1:8); xticklabels(pair_names_short); xtickangle(30)
ylabel('Degrees')
title('Peak timing symmetry error')
grid on

subplot(2,2,3)
bar(TimingSym_Duration_mean)
xticks(1:8); xticklabels(pair_names_short); xtickangle(30)
ylabel('Degrees')
title('Burst duration symmetry error')
grid on

subplot(2,2,4)
bar(TimingScore)
xticks(1:8); xticklabels(pair_names_short); xtickangle(30)
ylabel('Score')
title('Timing score')
grid on

%% --- 20 TIMING VARIABILITY PLOTS ---
% Useful to see if the timing is stable across cycles

figure('Name','Peak timing variability','Units','normalized','Position',[0.1 0.1 0.85 0.8]);
tl = tiledlayout(4,4,'TileSpacing','compact');
title(tl, 'Peak timing variability across good cycles');

for m = 1:16
    nexttile;
    plot(1:n_valid, peak_angle(:,m), '-o', 'LineWidth', 1);
    title(muscle_names{m}, 'Interpreter','none');
    xlabel('Good cycle');
    ylabel('Peak angle [°]');
    ylim([0 360]);
    yticks([0 90 180 270 360]);
    grid on;
end

figure('Name','Onset timing variability','Units','normalized','Position',[0.1 0.1 0.85 0.8]);
tl = tiledlayout(4,4,'TileSpacing','compact');
title(tl, 'Onset timing variability across good cycles');

for m = 1:16
    nexttile;
    plot(1:n_valid, onset_angle(:,m), '-o', 'LineWidth', 1);
    title(muscle_names{m}, 'Interpreter','none');
    xlabel('Good cycle');
    ylabel('Onset angle [°]');
    ylim([0 360]);
    yticks([0 90 180 270 360]);
    grid on;
end

%% --- 21 ACTIVATION AND SYMMETRY BAR PLOTS ---

figure('Name','Mean total activation per muscle', ...
       'Units','normalized','Position',[0.1 0.1 0.85 0.5]);

bar(mean_iEMG);
xticks(1:16); xticklabels(muscle_names); xtickangle(45);
ylabel('Mean iEMG');
title('Mean iEMG per muscle');
grid on;

figure('Name','Symmetry Index per muscle pair', ...
       'Units','normalized','Position',[0.1 0.1 0.85 0.45]);

bar(SI_iEMG_mean);
xticks(1:8); xticklabels(pair_names_short); xtickangle(30);
ylabel('SI iEMG [%]');
title('Mean symmetry index from iEMG');
grid on;

figure('Name','CCI per muscle pair', ...
       'Units','normalized','Position',[0.1 0.1 0.85 0.45]);

bar(CCI_env_mean);
xticks(1:n_pairs); xticklabels(pair_names); xtickangle(30);
ylabel('CCI');
title('Mean co-contraction index from envelope');
grid on;

%% --- 11 PLOT NORMALIZED ENVELOPE PROFILES ---
% Good cycles in gray, mean and SD in blue.
% The mean threshold used for timing detection is also shown, together with
% its standard deviation across good cycles.

page = 6;

c_cycles = [0.7 0.7 0.7];
c_mean   = [0 0.4470 0.7410];

EMG_env_mean = zeros(16,360);
EMG_env_std  = zeros(16,360);

for m = 1:16

    temp_mat = zeros(360, n_valid);

    for i = 1:n_valid
        temp_mat(:,i) = EMG_env_good_norm{i}(:,m);
    end

    EMG_env_mean(m,:) = mean(temp_mat, 2)';
    EMG_env_std(m,:)  = std(temp_mat, 0, 2)';

    % Mean and SD of the adaptive threshold used for this muscle
    thr_mean_m = mean(thr_used(:,m), 'omitnan');
    thr_std_m  = std(thr_used(:,m), 0, 'omitnan');

    if mod(m-1, page) == 0
        figure('Units','normalized','Position',[0.1 0.1 0.8 0.8]);
        tl = tiledlayout(3,2,'TileSpacing','compact');
        title(tl, ['Normalized EMG envelope profiles - Page ' num2str(ceil(m/page))], ...
            'FontSize', 14);
    end

    nexttile;
    hold on;

    % Good cycles in gray
    plot(AngBase, temp_mat, 'Color', c_cycles, 'LineWidth', 0.5);

    % Mean envelope in blue
    plot(AngBase, EMG_env_mean(m,:), 'Color', c_mean, 'LineWidth', 2);

    % Mean ± SD of the envelope
    plot(AngBase, EMG_env_mean(m,:) + EMG_env_std(m,:), '--', 'Color', c_mean, 'LineWidth', 1);
    plot(AngBase, EMG_env_mean(m,:) - EMG_env_std(m,:), '--', 'Color', c_mean, 'LineWidth', 1);

    % Mean threshold in red
    yline(thr_mean_m, 'r-', 'LineWidth', 1.5);

    % Threshold mean ± SD in red dashed lines
    yline(thr_mean_m + thr_std_m, 'r--', 'LineWidth', 1);
    yline(thr_mean_m - thr_std_m, 'r--', 'LineWidth', 1);

    title(muscle_names{m}, 'Interpreter','none');
    xlim([0 360]);
    xticks([0 90 180 270 360]);
    xlabel('Crank angle [°]');
    ylabel('Normalized amplitude');
    grid on;
end