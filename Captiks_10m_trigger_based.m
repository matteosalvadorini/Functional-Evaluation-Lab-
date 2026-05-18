%% EMG_10mWT_FINAL.m
% =========================================================================
% COMPLETE 10-Meter Walk Test EMG + CAPTIKS Analysis
% Single script — run once per subject per time point (T0/T1/T2/T3)
%
% PIPELINE:
%   1. Load & validate data
%   2. Dead channel detection
%   3. EMG preprocessing (bandpass → MAD rejection → envelope)
%   4. Trigger window extraction
%   5. CAPTIKS FSM heel strike detection (adaptive thresholds)
%   6. Cross-correlation synchronization (EMG ↔ CAPTIKS)
%   7. iEMG per gait cycle (first pass)
%   8. Outlier channel detection (modified Z-score)
%   9. Right heel strike supplementation if needed
%  10. Final iEMG + Symmetry Index (corrected)
%  11. Gait parameters
%  12. All plots
%  13. Output struct (ready for T0/T1/T2/T3 comparison)
%
% REQUIRED IN WORKSPACE BEFORE RUNNING:
%   data                   — [N x 17] matrix: cols 1-16 EMG, col 17 trigger
%   cpk_anatomical_angles* — CAPTIKS struct (loaded from import)
%
% OPTIONAL:
%   mvc_values             — [1x16] MVC amplitudes in mV (if available)
%
% OUTPUT:
%   results_10m            — struct with all final results
%   sync_info              — struct with synchronization details
% =========================================================================

%% =========================================================================
%  SECTION 0 — PARAMETERS (edit here if needed)
% =========================================================================
fs_EMG     = 2148.1481;   % EMG sampling frequency [Hz]
fs_CAPTIKS = 100;         % CAPTIKS sampling frequency [Hz]

% EMG bandpass filter
bp_low  = 20;             % [Hz]
bp_high = 400;            % [Hz]

% EMG envelope low-pass cutoff (standard: 6-10 Hz)
fc_env  = 6;              % [Hz]

% MAD artifact rejection multiplier (4 = standard robust threshold)
mad_mult = 4;

% Dead channel threshold: max(abs(signal)) < this → flagged as dead
dead_ch_threshold = 1e-3; % [mV]

% Outlier detection: modified Z-score threshold (Iglewicz & Hoaglin 1993)
outlier_zscore_thresh = 3.5;

% Minimum right heel strikes needed before TA-R supplement kicks in
min_hs_needed = 5;

% CAPTIKS FSM low-pass cutoff
fc_captiks = 6;           % [Hz]

% Minimum stride duration for peak detection fallback
min_stride_s = 0.8;       % [s]

% MVC normalization — set mvc_available = true and fill mvc_values if available
mvc_available = false;
mvc_values    = zeros(1,16);  % [1x16] mV — fill if mvc_available = true

% Channel names and leg indices
channel_names = {
    'Tibialis Ant R',  'Gastro Lat R', 'Soleus R',      'Gastro Med R', ...
    'Rectus R',        'Vastus Lat R', 'Vastus Med R',   'Semitendinous R', ...
    'Tibialis Ant L',  'Gastro Lat L', 'Soleus L',       'Gastro Med L', ...
    'Rectus L',        'Vastus Lat L', 'Vastus Med L',   'Semitendinous L'};
idx_R = 1:8;
idx_L = 9:16;

fprintf('=== EMG 10mWT FINAL Analysis ===\n');
fprintf('Parameters: fs_EMG=%.1f Hz | fc_env=%d Hz | MAD x%d\n', ...
    fs_EMG, fc_env, mad_mult);

%% =========================================================================
%  SECTION 1 — LOAD AND VALIDATE DATA
% =========================================================================
if istable(data)
    data = table2array(data);
end
assert(size(data,2) >= 17, ...
    'ERROR: data must have 17 columns (16 EMG + 1 trigger).');

data_emg     = data(:, 1:16);
data_trigger = data(:, 17);
N_emg        = size(data_emg, 1);
t_emg_full   = (0:N_emg-1)' / fs_EMG;

% Load CAPTIKS angles
vars = who('cpk_anatomical_angles*');
if isempty(vars)
    error('No cpk_anatomical_angles variable found. Run CAPTIKS import first.');
end
data_angles = eval(vars{1});

fprintf('EMG: %d samples @ %.1f Hz (%.1f s)\n', N_emg, fs_EMG, N_emg/fs_EMG);

%% =========================================================================
%  SECTION 2 — DEAD CHANNEL DETECTION
%  Flags channels with no real signal before any processing.
%  Dead channels are excluded from all computations and shown gray in plots.
% =========================================================================
dead_channels = false(1,16);
for j = 1:16
    ch = data_emg(:,j);
    % Criterion 1: absolute amplitude too small
    if max(abs(ch)) < dead_ch_threshold
        dead_channels(j) = true;
        continue;
    end
    % Criterion 2: nearly zero variance relative to range (DC offset noise)
    if std(ch) < 0.005 * (max(ch) - min(ch))
        dead_channels(j) = true;
    end
end

fprintf('\n--- Channel Quality Check ---\n');
for j = 1:16
    tag = ''; if dead_channels(j), tag = '  *** DEAD — will be excluded ***'; end
    fprintf('  Ch%2d %-22s max=%.4f mV%s\n', j, channel_names{j}, ...
        max(abs(data_emg(:,j))), tag);
end
fprintf('  Dead channels: %d\n', sum(dead_channels));

%% =========================================================================
%  SECTION 3 — EMG PREPROCESSING
%  Pipeline: bandpass filter → MAD artifact rejection → rectify → envelope
% =========================================================================

% --- 3a: Bandpass filter (zero-phase, 4th order Butterworth) ---
Wn     = [bp_low bp_high] / (fs_EMG/2);
[b, a] = butter(4, Wn, 'bandpass');
data_f = filtfilt(b, a, fillmissing(data_emg, 'constant', 0));

% --- 3b: MAD artifact rejection (single robust pass) ---
data_f_clean = data_f;
fprintf('\n--- MAD Artifact Rejection ---\n');
for j = 1:16
    if dead_channels(j), continue; end
    ch      = data_f(:,j);
    med_ch  = median(ch, 'omitnan');
    mad_val = median(abs(ch - med_ch), 'omitnan');
    sigma_r = 1.4826 * mad_val;
    art_idx = abs(ch - med_ch) > mad_mult * sigma_r;
    data_f_clean(art_idx, j) = NaN;
    fprintf('  Ch%2d %-22s: %.1f%% flagged\n', j, channel_names{j}, ...
        100*mean(art_idx));
end

% --- 3c: Rectify + low-pass envelope ---
[blp, alp] = butter(4, fc_env/(fs_EMG/2), 'low');
data_rect  = abs(data_f_clean);
nan_mask   = isnan(data_rect);
tmp        = data_rect;
tmp(nan_mask) = 0;
data_env   = filtfilt(blp, alp, tmp);
data_env(nan_mask) = NaN;

% --- 3d: MVC normalization ---
data_env_norm = data_env;
if mvc_available
    for j = 1:16
        if mvc_values(j) > 0
            data_env_norm(:,j) = data_env(:,j) / mvc_values(j) * 100;
        end
    end
    norm_label = '% MVC';
    fprintf('\nMVC normalization applied.\n');
else
    norm_label = 'a.u. (no MVC)';
    fprintf('\nNo MVC — reporting in relative units.\n');
end

%% =========================================================================
%  SECTION 4 — TRIGGER-BASED EMG WINDOW EXTRACTION
%  Column 17 marks the actual 10m walking window (clinician-controlled).
%  This removes acceleration/deceleration phases outside the test zone.
% =========================================================================
trig_bin  = data_trigger > 0.5 * max(abs(data_trigger));
trig_diff = diff([0; double(trig_bin)]);
trig_on   = find(trig_diff ==  1);
trig_off  = find(trig_diff == -1);

if isempty(trig_on) || isempty(trig_off)
    warning('No trigger detected — using full EMG signal as test window.');
    emg_win_start = 1;
    emg_win_end   = N_emg;
else
    emg_win_start = trig_on(1);
    emg_win_end   = trig_off(end);
    fprintf('\nTrigger window: %.2f → %.2f s (%.2f s)\n', ...
        emg_win_start/fs_EMG, emg_win_end/fs_EMG, ...
        (emg_win_end - emg_win_start)/fs_EMG);
end

env_win = data_env_norm(emg_win_start:emg_win_end, :);
f_win   = data_f_clean(emg_win_start:emg_win_end, :);
N_win   = size(env_win, 1);
t_win   = (0:N_win-1)' / fs_EMG;

%% =========================================================================
%  SECTION 5 — CAPTIKS FSM HEEL STRIKE DETECTION
%  Reproduces the FSM from the CAPTIKS code with ADAPTIVE thresholds.
%  Fixed thresholds fail on the paretic leg — adaptive thresholds scale
%  to each leg's actual signal range, handling weak stroke patients.
%
%  FSM states:
%    0 = Stance / reset
%    1 = Push-off initiation
%    2 = Toe-off
%    3 = Mid-swing
%    4 = Terminal swing
%  Heel strike = State 4 → State 0 transition
% =========================================================================
fprintf('\n--- CAPTIKS FSM ---\n');

T_sample = mean(diff(data_angles.TIMESTAMPRELATIVE));
if isduration(T_sample), T_sample = seconds(T_sample); end

% Extract and offset-correct ankle angles
la = data_angles.ANKLEDORSIFLEXION_PLANTARFLEXIONLEFT;
ra = data_angles.ANKLEDORSIFLEXION_PLANTARFLEXIONRIGHT;
la = la - la(1);
ra = ra - ra(1);

% Synthetic gyro (derivative of ankle angle)
lg_raw = -[0; diff(la) / T_sample];
rg_raw = -[0; diff(ra) / T_sample];

% Filter gyro and ankle signals
[bf, af] = butter(4, fc_captiks/(fs_CAPTIKS/2), 'low');
lg = filtfilt(bf, af, medfilt1(lg_raw, 15));
rg = filtfilt(bf, af, medfilt1(rg_raw, 15));
la = filtfilt(bf, af, la);
ra = filtfilt(bf, af, ra);

% Print signal diagnostics
fprintf('  Left  ankle: [%.2f, %.2f] deg | gyro: [%.2f, %.2f] deg/s\n', ...
    min(la), max(la), min(lg), max(lg));
fprintf('  Right ankle: [%.2f, %.2f] deg | gyro: [%.2f, %.2f] deg/s\n', ...
    min(ra), max(ra), min(rg), max(rg));

% Adaptive FSM thresholds (scaled to each leg's actual signal range)
thresh_L.AngleLimit    = min(la) * 0.30;
thresh_L.SpeedLimitMax = max(lg) * 0.40;
thresh_L.SpeedLimitMin = min(lg) * 0.40;
thresh_L.SpeedLimitMin2= min(lg) * 0.15;

thresh_R.AngleLimit    = min(ra) * 0.30;
thresh_R.SpeedLimitMax = max(rg) * 0.40;
thresh_R.SpeedLimitMin = min(rg) * 0.40;
thresh_R.SpeedLimitMin2= min(rg) * 0.15;

fprintf('  LEFT  thresholds: AL=%.2f SpMax=%.2f SpMin=%.2f SpMin2=%.2f\n', ...
    thresh_L.AngleLimit, thresh_L.SpeedLimitMax, thresh_L.SpeedLimitMin, thresh_L.SpeedLimitMin2);
fprintf('  RIGHT thresholds: AL=%.2f SpMax=%.2f SpMin=%.2f SpMin2=%.2f\n', ...
    thresh_R.AngleLimit, thresh_R.SpeedLimitMax, thresh_R.SpeedLimitMin, thresh_R.SpeedLimitMin2);

% High-pass style filter (exactly as in original CAPTIKS code)
omega_hp = 1.5;  K_hp = 1;
N_cap    = length(la);
la_hp    = zeros(N_cap,1);  ra_hp = zeros(N_cap,1);
la_hp(1) = la(1);           ra_hp(1) = ra(1);
for ii = 2:N_cap
    la_hp(ii) = exp(-omega_hp*T_sample)*la_hp(ii-1) + K_hp*(la(ii)-la(ii-1));
    ra_hp(ii) = exp(-omega_hp*T_sample)*ra_hp(ii-1) + K_hp*(ra(ii)-ra(ii-1));
end

% LEFT FSM
State_left = zeros(N_cap,1);
CPL = 0;
for ii = 3:N_cap
    if sign(lg(ii)*lg(ii-1))<=0 && sign(lg(ii))<0 && la(ii)>thresh_L.AngleLimit
        CPL = 0;
    end
    switch CPL
        case 0, if sign(la_hp(ii)*la_hp(ii-1))<=0,               CPL=1; end
        case 1, if lg(ii-1) <= thresh_L.SpeedLimitMin,            CPL=2; end
        case 2, if lg(ii-1) >= thresh_L.SpeedLimitMin2,           CPL=3; end
        case 3, if lg(ii)   >  thresh_L.SpeedLimitMax,            CPL=4; end
        case 4, if sign(lg(ii)*lg(ii-1))<=0 && sign(lg(ii))<0,   CPL=0; end
    end
    State_left(ii) = CPL;
end

% RIGHT FSM
State_right = zeros(N_cap,1);
CPR = 0;
for ii = 3:N_cap
    if sign(rg(ii)*rg(ii-1))<=0 && sign(rg(ii))<0 && ra(ii)>thresh_R.AngleLimit
        CPR = 0;
    end
    switch CPR
        case 0, if sign(ra_hp(ii)*ra_hp(ii-1))<=0,               CPR=1; end
        case 1, if rg(ii-1) <= thresh_R.SpeedLimitMin,            CPR=2; end
        case 2, if rg(ii-1) >= thresh_R.SpeedLimitMin2,           CPR=3; end
        case 3, if rg(ii)   >  thresh_R.SpeedLimitMax,            CPR=4; end
        case 4, if sign(rg(ii)*rg(ii-1))<=0 && sign(rg(ii))<0,   CPR=0; end
    end
    State_right(ii) = CPR;
end

% Extract heel strikes: State 4 → 0 transition
hs_L_cap = find(State_left(1:end-1)==4  & State_left(2:end)==0)  + 1;
hs_R_cap = find(State_right(1:end-1)==4 & State_right(2:end)==0) + 1;

fprintf('  FSM heel strikes — Left: %d | Right: %d\n', ...
    length(hs_L_cap), length(hs_R_cap));

% FALLBACK: If FSM fails on either side, use ankle angle minima
min_stride_samp = round(min_stride_s * fs_CAPTIKS);

if length(hs_L_cap) < 3
    warning('Left FSM failed — using ankle angle minima as fallback.');
    [~, hs_L_cap] = findpeaks(-la, 'MinPeakDistance', min_stride_samp, ...
        'MinPeakHeight', 0.3*max(-la));
    fprintf('  Left fallback: %d ankle minima\n', length(hs_L_cap));
end

if length(hs_R_cap) < 3
    warning('Right FSM failed — using ankle angle minima as fallback.');
    [~, hs_R_cap] = findpeaks(-ra, 'MinPeakDistance', min_stride_samp, ...
        'MinPeakHeight', 0.3*max(-ra));
    fprintf('  Right fallback: %d ankle minima\n', length(hs_R_cap));
end

assert(length(hs_L_cap)>=2 && length(hs_R_cap)>=2, ...
    'Too few heel strikes detected. Check CAPTIKS data quality.');

%% =========================================================================
%  SECTION 6 — CROSS-CORRELATION SYNCHRONIZATION
%  Finds the time lag between CAPTIKS start and EMG trigger using
%  cross-correlation of motion signals. No hardware sync pulse needed.
% =========================================================================
fprintf('\n--- Cross-Correlation Synchronization ---\n');

% CAPTIKS motion proxy: sum of absolute gyro signals
cap_motion = abs(lg) + abs(rg);
cap_motion = cap_motion / (max(cap_motion) + eps);

% EMG motion proxy: mean envelope across good channels, resampled to CAPTIKS rate
good_ch      = find(~dead_channels);
emg_rms_full = mean(abs(data_f_clean(:, good_ch)), 2, 'omitnan');
emg_rms_full(isnan(emg_rms_full)) = 0;
emg_rms_cap  = resample(emg_rms_full(emg_win_start:emg_win_end), ...
                         fs_CAPTIKS, round(fs_EMG));
emg_rms_cap  = emg_rms_cap / (max(emg_rms_cap) + eps);

% Cross-correlate (max lag = 3s)
N_xcorr      = min(length(cap_motion), length(emg_rms_cap));
max_lag_samp = round(3 * fs_CAPTIKS);
[xc, lags]   = xcorr(emg_rms_cap(1:N_xcorr), cap_motion(1:N_xcorr), max_lag_samp);
[~, best_idx]       = max(xc);
best_lag_samp       = lags(best_idx);
sync_offset_s       = best_lag_samp / fs_CAPTIKS;

fprintf('  Best lag: %d CAPTIKS samples = %.3f s\n', best_lag_samp, sync_offset_s);

% Convert CAPTIKS heel strikes → EMG window-relative sample indices
convert_to_win = @(cap_idx) ...
    (emg_win_start + round(((cap_idx-1)/fs_CAPTIKS - sync_offset_s)*fs_EMG)) ...
    - emg_win_start + 1;

hs_L_win = convert_to_win(hs_L_cap);
hs_R_win = convert_to_win(hs_R_cap);

% Keep only indices inside the window
hs_L_win = hs_L_win(hs_L_win >= 1 & hs_L_win <= N_win);
hs_R_win = hs_R_win(hs_R_win >= 1 & hs_R_win <= N_win);

fprintf('  Valid HS in EMG window — Left: %d | Right: %d\n', ...
    length(hs_L_win), length(hs_R_win));

% Extended window fallback if right HS still missing
if length(hs_R_win) < 2
    warning('Right HS not in trigger window — trying full EMG signal.');
    hs_R_win2 = round(1 + ((hs_R_cap-1)/fs_CAPTIKS - sync_offset_s)*fs_EMG);
    hs_R_win2 = hs_R_win2(hs_R_win2 >= 1 & hs_R_win2 <= N_win);
    if length(hs_R_win2) >= 2
        hs_R_win = hs_R_win2;
        fprintf('  Extended window: %d Right HS found\n', length(hs_R_win));
    end
end

sync_info.sync_offset_s  = sync_offset_s;
sync_info.hs_L_cap       = hs_L_cap;
sync_info.hs_R_cap       = hs_R_cap;
sync_info.hs_L_win       = hs_L_win;
sync_info.hs_R_win       = hs_R_win;

%% =========================================================================
%  SECTION 7 — GAIT PARAMETERS (from CAPTIKS FSM)
% =========================================================================
t_cap = double(data_angles.TIMESTAMPRELATIVE - data_angles.TIMESTAMPRELATIVE(1));
if isduration(t_cap(1)), t_cap = seconds(t_cap); end

all_hs_cap    = sort([hs_L_cap; hs_R_cap]);
walk_time     = t_cap(all_hs_cap(end)) - t_cap(all_hs_cap(1));
speed_ms      = 10 / walk_time;
n_steps       = length(all_hs_cap) - 1;
cadence       = (n_steps / walk_time) * 60;
step_dur_s    = diff(t_cap(all_hs_cap));
mean_step_dur = mean(step_dur_s, 'omitnan');
std_step_dur  = std(step_dur_s,  'omitnan');
step_dur_cv   = std_step_dur / mean_step_dur * 100;
stride_R      = diff(t_cap(hs_R_cap));
stride_L      = diff(t_cap(hs_L_cap));

stance_L=[]; swing_L=[]; stance_R=[]; swing_R=[];
for s = 1:length(hs_L_cap)-1
    seg = State_left(hs_L_cap(s):hs_L_cap(s+1));
    stance_L(end+1) = sum(seg==0)/fs_CAPTIKS;
    swing_L(end+1)  = sum(seg>0) /fs_CAPTIKS;
end
for s = 1:length(hs_R_cap)-1
    seg = State_right(hs_R_cap(s):hs_R_cap(s+1));
    stance_R(end+1) = sum(seg==0)/fs_CAPTIKS;
    swing_R(end+1)  = sum(seg>0) /fs_CAPTIKS;
end

gait_params.walk_time_s   = walk_time;
gait_params.speed_ms      = speed_ms;
gait_params.cadence_spm   = cadence;
gait_params.n_steps       = n_steps;
gait_params.step_dur_cv   = step_dur_cv;
gait_params.mean_stride_R = mean(stride_R,'omitnan');
gait_params.mean_stride_L = mean(stride_L,'omitnan');
gait_params.stance_pct_R  = mean(stance_R,'omitnan')/mean(stride_R,'omitnan')*100;
gait_params.stance_pct_L  = mean(stance_L,'omitnan')/mean(stride_L,'omitnan')*100;
gait_params.mean_swing_R  = mean(swing_R,'omitnan');
gait_params.mean_swing_L  = mean(swing_L,'omitnan');

fprintf('\n--- Gait Parameters ---\n');
fprintf('  Speed:        %.3f m/s\n',      speed_ms);
fprintf('  Cadence:      %.1f steps/min\n', cadence);
fprintf('  Walk time:    %.2f s\n',         walk_time);
fprintf('  Step CV:      %.1f%%\n',          step_dur_cv);
fprintf('  Stride R:     %.3f s | L: %.3f s\n', ...
    gait_params.mean_stride_R, gait_params.mean_stride_L);
fprintf('  Stance %% R:   %.1f%% | L: %.1f%%\n', ...
    gait_params.stance_pct_R, gait_params.stance_pct_L);
fprintf('  Swing R:      %.3f s | L: %.3f s\n', ...
    gait_params.mean_swing_R, gait_params.mean_swing_L);

%% =========================================================================
%  SECTION 8 — FIRST-PASS iEMG (needed for outlier detection)
% =========================================================================
n_R = length(hs_R_win) - 1;
n_L = length(hs_L_win) - 1;

iEMG_R = nan(max(n_R,1), 16);
iEMG_L = nan(max(n_L,1), 16);

for s = 1:n_R
    i1=hs_R_win(s); i2=hs_R_win(s+1);
    if i1<1||i2>N_win, continue; end
    for j=1:16
        if dead_channels(j), continue; end
        seg=env_win(i1:i2,j); seg=seg(~isnan(seg));
        if length(seg)>10, iEMG_R(s,j)=trapz(seg)/length(seg); end
    end
end
for s = 1:n_L
    i1=hs_L_win(s); i2=hs_L_win(s+1);
    if i1<1||i2>N_win, continue; end
    for j=1:16
        if dead_channels(j), continue; end
        seg=env_win(i1:i2,j); seg=seg(~isnan(seg));
        if length(seg)>10, iEMG_L(s,j)=trapz(seg)/length(seg); end
    end
end

mean_iEMG_R_pass1 = mean(iEMG_R,1,'omitnan');
mean_iEMG_L_pass1 = mean(iEMG_L,1,'omitnan');
mean_iEMG_pass1   = (mean_iEMG_R_pass1 + mean_iEMG_L_pass1) / 2;

%% =========================================================================
%  SECTION 9 — OUTLIER CHANNEL DETECTION
%  Uses modified Z-score (Iglewicz & Hoaglin 1993) within each leg group.
%  Channels >3.5 modified Z-scores from their leg-group median are excluded.
%  This objectively catches residual artifact channels like Vastus Med R.
% =========================================================================
outlier_channels = dead_channels;

fprintf('\n--- Outlier Channel Detection ---\n');
for leg_idx = {idx_R, idx_L}
    leg = leg_idx{1};
    vals = mean_iEMG_pass1(leg);
    vals(dead_channels(leg)) = NaN;
    med_val = median(vals,'omitnan');
    mad_val = median(abs(vals - med_val),'omitnan');
    for j = leg
        if dead_channels(j), continue; end
        mz = 0.6745 * abs(mean_iEMG_pass1(j) - med_val) / (mad_val + eps);
        if mz > outlier_zscore_thresh
            outlier_channels(j) = true;
            fprintf('  Ch%2d %-22s: OUTLIER (Z=%.1f) — excluded\n', ...
                j, channel_names{j}, mz);
        end
    end
end
if sum(outlier_channels) == sum(dead_channels)
    fprintf('  No outlier channels detected beyond dead channels.\n');
end

%% =========================================================================
%  SECTION 10 — RIGHT HEEL STRIKE SUPPLEMENTATION
%  If the paretic (right) leg has fewer cycles than min_hs_needed,
%  TA-R envelope peaks are added as supplementary heel strikes.
%  Duplicates within 200ms are removed to avoid double-counting.
% =========================================================================
fprintf('\n--- Right Heel Strike Check ---\n');
fprintf('  Current right HS count: %d (minimum needed: %d)\n', ...
    length(hs_R_win), min_hs_needed);

if length(hs_R_win) < min_hs_needed
    fprintf('  Supplementing with TA-R envelope peaks...\n');

    ta_R_env = env_win(:,1);
    ta_R_env(isnan(ta_R_env)) = 0;

    ta_thresh = 0.25 * max(ta_R_env);
    min_dist  = round(min_stride_s * fs_EMG);

    [~, ta_R_peaks] = findpeaks(ta_R_env, ...
        'MinPeakHeight',   ta_thresh, ...
        'MinPeakDistance', min_dist);

    fprintf('  TA-R peaks found: %d\n', length(ta_R_peaks));

    % Merge and remove duplicates within 200ms
    merge_tol      = round(0.2 * fs_EMG);
    hs_R_combined  = sort([hs_R_win(:); ta_R_peaks(:)]);
    keep           = true(size(hs_R_combined));
    for k = 2:length(hs_R_combined)
        if hs_R_combined(k) - hs_R_combined(k-1) < merge_tol
            keep(k) = false;
        end
    end
    hs_R_win = hs_R_combined(keep);
    fprintf('  After merge + dedup: %d right HS\n', length(hs_R_win));
else
    fprintf('  Sufficient — no supplement needed.\n');
end

%% =========================================================================
%  SECTION 11 — FINAL iEMG COMPUTATION (outliers excluded)
% =========================================================================
n_R = length(hs_R_win) - 1;
n_L = length(hs_L_win) - 1;

iEMG_R_final = nan(max(n_R,1), 16);
iEMG_L_final = nan(max(n_L,1), 16);

for s = 1:n_R
    i1=hs_R_win(s); i2=hs_R_win(s+1);
    if i1<1||i2>N_win, continue; end
    for j=1:16
        if outlier_channels(j), continue; end
        seg=env_win(i1:i2,j); seg=seg(~isnan(seg));
        if length(seg)>10, iEMG_R_final(s,j)=trapz(seg)/length(seg); end
    end
end
for s = 1:n_L
    i1=hs_L_win(s); i2=hs_L_win(s+1);
    if i1<1||i2>N_win, continue; end
    for j=1:16
        if outlier_channels(j), continue; end
        seg=env_win(i1:i2,j); seg=seg(~isnan(seg));
        if length(seg)>10, iEMG_L_final(s,j)=trapz(seg)/length(seg); end
    end
end

mean_iEMG_R = mean(iEMG_R_final,1,'omitnan');
mean_iEMG_L = mean(iEMG_L_final,1,'omitnan');
mean_iEMG   = (mean_iEMG_R + mean_iEMG_L) / 2;
peak_iEMG   = max(env_win,[],1,'omitnan');
peak_iEMG(outlier_channels) = NaN;

%% =========================================================================
%  SECTION 12 — SYMMETRY INDEX
% =========================================================================
SI_per_muscle = nan(1,16);
for j = 1:16
    if outlier_channels(j), continue; end
    r=mean_iEMG_R(j); l=mean_iEMG_L(j);
    if ~isnan(r)&&~isnan(l)&&(r+l)>0
        SI_per_muscle(j) = abs(r-l)/(0.5*(r+l))*100;
    end
end

valid_R_ch  = idx_R(~outlier_channels(idx_R));
valid_L_ch  = idx_L(~outlier_channels(idx_L));
R_leg_mean  = mean(mean_iEMG(valid_R_ch),'omitnan');
L_leg_mean  = mean(mean_iEMG(valid_L_ch),'omitnan');
SI_overall  = abs(R_leg_mean-L_leg_mean)/(0.5*(R_leg_mean+L_leg_mean))*100;

% Print final summary table
fprintf('\n=== FINAL RESULTS ===\n');
fprintf('%-22s %10s %10s %10s %8s  %s\n', ...
    'Muscle','iEMG_R','iEMG_L','Peak','SI(%%)','Status');
fprintf('%s\n', repmat('-',1,76));
for j = 1:16
    if dead_channels(j),                      tag = '[DEAD]';
    elseif outlier_channels(j),               tag = '[OUTLIER]';
    else,                                      tag = 'OK';
    end
    fprintf('%-22s %10.5f %10.5f %10.5f %8.2f  %s\n', ...
        channel_names{j}, mean_iEMG_R(j), mean_iEMG_L(j), ...
        peak_iEMG(j), SI_per_muscle(j), tag);
end
fprintf('%s\n', repmat('-',1,76));
fprintf('%-22s %10.5f %10.5f %10s %8.2f\n', ...
    'LEGS (valid only)', R_leg_mean, L_leg_mean, '---', SI_overall);
fprintf('\nNorm: %s | R cycles: %d | L cycles: %d\n', norm_label, n_R, n_L);

%% =========================================================================
%  SECTION 13 — PLOTS
% =========================================================================

% Bar colors: blue=right valid, red=left valid, gray=excluded
bar_colors = zeros(16,3);
for j=1:16
    if outlier_channels(j), bar_colors(j,:)=[0.75 0.75 0.75];
    elseif j<=8,            bar_colors(j,:)=[0.18 0.38 0.75];
    else,                   bar_colors(j,:)=[0.78 0.18 0.18];
    end
end

% --- Plot A: Cross-correlation sync verification ---
t_cap_vec = t_cap;
figure('Name','A: Cross-Correlation Sync','Units','normalized','Position',[0.05 0.7 0.5 0.22]);
[xc2,lags2] = xcorr(emg_rms_cap(1:N_xcorr), cap_motion(1:N_xcorr), max_lag_samp);
plot(lags2/fs_CAPTIKS, xc2,'b','LineWidth',1.2); hold on;
xline(sync_offset_s,'r--','LineWidth',2,'Label',sprintf('Lag=%.2fs',sync_offset_s));
xlabel('Lag (s)'); ylabel('XCorr');
title('EMG–CAPTIKS Cross-Correlation'); grid on;

% --- Plot B: Sync verification (3 subplots) ---
figure('Name','B: Sync Verification','Units','normalized','Position',[0.05 0.42 0.9 0.26]);
subplot(3,1,1);
plot(t_cap_vec,la,'r','LineWidth',1.2); hold on;
plot(t_cap_vec,ra,'b','LineWidth',1.2);
plot(t_cap_vec(hs_L_cap),la(hs_L_cap),'rv','MarkerSize',7,'MarkerFaceColor','r');
plot(t_cap_vec(hs_R_cap),ra(hs_R_cap),'bv','MarkerSize',7,'MarkerFaceColor','b');
legend('Left ankle','Right ankle','HS-L','HS-R');
title('CAPTIKS Ankle Angles + Heel Strikes'); ylabel('deg'); grid on;

subplot(3,1,2);
good_R = find(~outlier_channels & (1:16)<=8, 1);
plot(t_win, env_win(:,good_R),'k','LineWidth',0.8); hold on;
for k=1:length(hs_L_win), xline(hs_L_win(k)/fs_EMG,'r--','Alpha',0.5,'LineWidth',0.8); end
for k=1:length(hs_R_win), xline(hs_R_win(k)/fs_EMG,'b--','Alpha',0.5,'LineWidth',0.8); end
title(sprintf('EMG: %s + HS (red=L, blue=R)',channel_names{good_R}));
ylabel(norm_label); xlabel('Time (s)'); grid on;

subplot(3,1,3);
good_L = find(~outlier_channels & (1:16)>=9, 1);
if ~isempty(good_L)
    plot(t_win, env_win(:,good_L),'Color',[0.6 0.2 0.2],'LineWidth',0.8); hold on;
    for k=1:length(hs_L_win), xline(hs_L_win(k)/fs_EMG,'r--','Alpha',0.5,'LineWidth',0.8); end
    for k=1:length(hs_R_win), xline(hs_R_win(k)/fs_EMG,'b--','Alpha',0.5,'LineWidth',0.8); end
    title(sprintf('EMG: %s + HS',channel_names{good_L}));
    ylabel(norm_label); xlabel('Time (s)'); grid on;
end
sgtitle('SYNC CHECK — Lines should align with EMG burst onsets');

% --- Plot C: FSM gait phase timeline ---
figure('Name','C: FSM Gait Phases','Units','normalized','Position',[0.05 0.12 0.9 0.28]);
subplot(2,1,1);
area(t_cap_vec,State_left,'FaceColor',[0.9 0.5 0.5],'FaceAlpha',0.4); hold on;
plot(t_cap_vec,la,'r','LineWidth',1.2);
plot(t_cap_vec(hs_L_cap),la(hs_L_cap),'kv','MarkerSize',7,'MarkerFaceColor','k');
ylabel('State/Angle'); legend('FSM','Ankle','HS');
title('Left leg FSM'); grid on;

subplot(2,1,2);
area(t_cap_vec,State_right,'FaceColor',[0.5 0.5 0.9],'FaceAlpha',0.4); hold on;
plot(t_cap_vec,ra,'b','LineWidth',1.2);
plot(t_cap_vec(hs_R_cap),ra(hs_R_cap),'kv','MarkerSize',7,'MarkerFaceColor','k');
ylabel('State/Angle'); legend('FSM','Ankle','HS');
title('Right leg FSM'); xlabel('Time (s)'); grid on;
sgtitle('CAPTIKS FSM Gait Phase Detection — 10mWT');

% --- Plot D: Mean iEMG per muscle ---
figure('Name','D: Mean iEMG','Units','normalized','Position',[0.05 0.55 0.9 0.35]);
b1=bar(1:16,mean_iEMG,'FaceColor','flat'); b1.CData=bar_colors;
xticks(1:16); xticklabels(channel_names); xtickangle(45);
ylabel(['iEMG (' norm_label ')'],'FontSize',11);
title('Mean iEMG per Muscle — 10mWT','FontSize',12);
xline(8.5,'k--','LineWidth',2);
text(8.7,max(mean_iEMG,[],'omitnan')*0.95,'Gray=excluded','Color',[0.5 0.5 0.5],'FontSize',9);
grid on; box on;

% --- Plot E: SI per muscle ---
si_plot = SI_per_muscle;
si_plot(outlier_channels|isnan(SI_per_muscle)) = 0;
figure('Name','E: Symmetry Index','Units','normalized','Position',[0.05 0.1 0.9 0.35]);
b2=bar(1:16,si_plot,'FaceColor','flat'); b2.CData=bar_colors;
xticks(1:16); xticklabels(channel_names); xtickangle(45);
ylabel('SI (%)','FontSize',11);
title(sprintf('Symmetry Index per Muscle — 10mWT  (Overall SI = %.1f%%)', SI_overall),'FontSize',12);
yline(SI_overall,'r--','LineWidth',2,'Label',sprintf('Overall=%.1f%%',SI_overall),'LabelHorizontalAlignment','left');
yline(10,'g:','LineWidth',1.5,'Label','10% threshold');
grid on; box on;

% --- Plot F: iEMG trend across cycles (fatigue check) ---
figure('Name','F: iEMG Trend','Units','normalized','Position',[0.05 0.1 0.9 0.3]);
subplot(1,2,1);
if n_R>0
    plot(1:n_R,mean(iEMG_R_final(:,valid_R_ch),2,'omitnan'),'-ob','LineWidth',2,'MarkerSize',5); hold on;
    plot(1:n_R,mean(iEMG_R_final(:,valid_L_ch),2,'omitnan'),'-sr','LineWidth',2,'MarkerSize',5);
    if n_R>=3
        y_r=mean(iEMG_R_final(:,valid_R_ch),2,'omitnan');
        vf=~isnan(y_r); x_r=(1:n_R)';
        if sum(vf)>=2
            p=polyfit(x_r(vf),y_r(vf),1);
            plot(1:n_R,polyval(p,1:n_R),'b--','LineWidth',1,'DisplayName','R trend');
        end
    end
    xlabel('Right stride #'); ylabel(['iEMG (' norm_label ')']);
    title('Right strides'); legend('Right','Left','R trend'); grid on;
end
subplot(1,2,2);
if n_L>0
    plot(1:n_L,mean(iEMG_L_final(:,valid_R_ch),2,'omitnan'),'-ob','LineWidth',2,'MarkerSize',5); hold on;
    plot(1:n_L,mean(iEMG_L_final(:,valid_L_ch),2,'omitnan'),'-sr','LineWidth',2,'MarkerSize',5);
    xlabel('Left stride #'); ylabel(['iEMG (' norm_label ')']);
    title('Left strides'); legend('Right','Left'); grid on;
end
sgtitle('iEMG Trend — fatigue/consistency check');

% --- Plot G: Matched muscle pairs R vs L ---
figure('Name','G: R vs L Pairs','Units','normalized','Position',[0.05 0.1 0.85 0.4]);
valid_pairs = ~outlier_channels(1:8) & ~outlier_channels(9:16);
r_vals = mean_iEMG(1:8);  r_vals(~valid_pairs)=NaN;
l_vals = mean_iEMG(9:16); l_vals(~valid_pairs)=NaN;
width  = 0.35;
bar((1:8)-width/2, r_vals, width,'FaceColor',[0.18 0.38 0.75]); hold on;
bar((1:8)+width/2, l_vals, width,'FaceColor',[0.78 0.18 0.18]);
muscle_pairs={'Tib Ant','Gastro Lat','Soleus','Gastro Med', ...
              'Rectus','Vastus Lat','Vastus Med','Semitend'};
xticks(1:8); xticklabels(muscle_pairs); xtickangle(30);
ylabel(['iEMG (' norm_label ')'],'FontSize',11);
title('Right vs Left Leg — Matched Muscle Pairs','FontSize',12);
legend('Right leg','Left leg','Location','northeast');
for k=1:8
    if ~valid_pairs(k)||isnan(SI_per_muscle(k)), continue; end
    max_h=max(r_vals(k),l_vals(k));
    text(k, max_h*1.08, sprintf('SI=%d%%',round(SI_per_muscle(k))), ...
        'HorizontalAlignment','center','FontSize',8,'Color',[0.3 0.3 0.3]);
end
grid on; box on;

%% =========================================================================
%  SECTION 14 — OUTPUT STRUCT
%  Save everything needed for T0/T1/T2/T3 comparison
% =========================================================================
results_10m.mean_iEMG_per_muscle = mean_iEMG;
results_10m.mean_iEMG_R          = mean_iEMG_R;
results_10m.mean_iEMG_L          = mean_iEMG_L;
results_10m.peak_iEMG            = peak_iEMG;
results_10m.SI_per_muscle        = SI_per_muscle;
results_10m.SI_overall           = SI_overall;
results_10m.R_leg_mean           = R_leg_mean;
results_10m.L_leg_mean           = L_leg_mean;
results_10m.dead_channels        = dead_channels;
results_10m.outlier_channels     = outlier_channels;
results_10m.gait_params          = gait_params;
results_10m.norm_label           = norm_label;
results_10m.channel_names        = channel_names;
results_10m.n_R_cycles           = n_R;
results_10m.n_L_cycles           = n_L;
results_10m.iEMG_R_all_cycles    = iEMG_R_final;
results_10m.iEMG_L_all_cycles    = iEMG_L_final;
results_10m.sync_offset_s        = sync_offset_s;
results_10m.hs_R_win             = hs_R_win;
results_10m.hs_L_win             = hs_L_win;
results_10m.fs_EMG               = fs_EMG;

fprintf('\n=== DONE — results_10m saved ===\n');
fprintf('SI_overall     = %.2f%%\n',    SI_overall);
fprintf('Speed          = %.3f m/s\n',  speed_ms);
fprintf('Cadence        = %.1f spm\n',  cadence);
fprintf('R cycles used  = %d\n',        n_R);
fprintf('L cycles used  = %d\n',        n_L);
fprintf('Sync offset    = %.3f s\n',    sync_offset_s);
fprintf('\nFor T0/T1/T2/T3 comparison use: results_10m\n');
