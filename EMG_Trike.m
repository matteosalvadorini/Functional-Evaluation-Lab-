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
data_array = struct2array(data_resampled);

time_col    = 1;
emg_cols    = 2:17;
trigger_col = 1;   % last column = Analog Input Adapter

n_samples = size(data_array,1);

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

% For 35 RPM, expected cycle duration ≈ 1.7 sec
% We only enforce minimum distance between peaks
min_cycle_samples = round(fs_EMG * 1.2);

% Detect peaks WITHOUT amplitude threshold
[~, locs_trig] = findpeaks(trigger_sig, ...
    'MinPeakDistance', min_cycle_samples);

fprintf('Pedaling cycles detected: %d\n', length(locs_trig)-1);

%% Remove abnormal cycles (missing trigger cases)
cycle_lengths = diff(locs_trig);

valid_cycles = cycle_lengths < mean(cycle_lengths) + 2*std(cycle_lengths);

locs_trig = locs_trig([true; valid_cycles]);

fprintf('Valid cycles after removing abnormal ones: %d\n', length(locs_trig)-1);

%% Plot trigger with detected peaks
figure('Name','Trigger - Cycle Detection');
plot(t, trigger_sig, 'Color',[0.5 0.5 0.5]); 
hold on;

plot(t(locs_trig), trigger_sig(locs_trig), ...
    'ro', 'MarkerFaceColor','r');

xlabel('Time (s)');
ylabel('Trigger (mV)');
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
%NON USIAMO QUESTO, MA QUELLO SOTTO, QUA FACCIAMO ABS ALL'INTERNO DEL FOR
%QUINDI MENO PRECISO


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






%%


% Definiamo i parametri per l'inviluppo (es. finestra mobile di 50ms)
win_size = round(fs_EMG * 0.05); 

% Creiamo le strutture attese dalla logica di temporal_symmetry
EMG_rect_good_norm = cell(n_valid, 1);
EMG_env_good_norm  = cell(n_valid, 1);

for i = 1:n_valid
    cycle_rect = zeros(360, 16);
    cycle_env  = zeros(360, 16);
    for m = 1:16
        % Prendiamo il segnale rettificato (abs)
        rect_sig = abs(EMG_good_norm{m}(:,i));
        cycle_rect(:, m) = rect_sig;
        % Calcoliamo l'inviluppo lineare
        cycle_env(:, m)  = movmean(rect_sig, win_size);
    end
    EMG_rect_good_norm{i} = cycle_rect;
    EMG_env_good_norm{i}  = cycle_env;
end

% Alias per compatibilità con il codice originale
muscle_names = channel_names;
pair_names_short = muscle_pairs;


%% --- 13 TOTAL ACTIVATION METRIC: iEMG ---
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
iEMG_right_total = sum(iEMG(:,1:8), 2);
iEMG_left_total  = sum(iEMG(:,9:16), 2);
SI_global_iEMG = ((iEMG_right_total - iEMG_left_total) ./ ...
                 (0.5*(iEMG_right_total + iEMG_left_total))) * 100;
fprintf('\n--- GLOBAL SYMMETRY INDEX ---\n');
fprintf('SI_global_iEMG_mean     = %.2f\n', mean(SI_global_iEMG));
fprintf('SI_global_iEMG_abs_mean = %.2f\n', mean(abs(SI_global_iEMG)));


%% --- 16 CO-CONTRACTION INDEX (CCI) ---
% Definiamo le coppie basandoci sugli indici di channel_names (1-16)
% R: 1-TA, 2-GL, 3-SO, 5-RF, 8-ST | L: 9-TA, 10-GL, 11-SO, 13-RF, 16-ST
pairs = [1 2; 1 3; 5 8; 9 10; 9 11; 13 16]; 
pair_names = cell(1, size(pairs,1));
for p = 1:size(pairs,1)
    pair_names{p} = [channel_names{pairs(p,1)} ' vs ' channel_names{pairs(p,2)}];
end

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
k_thr = 3;              
baseline_prct = 30;     
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
        E = cycle_env(:,m);                                     
        [peak_amplitude(c,m), idx_peak] = max(E);
        peak_angle(c,m) = AngBase(idx_peak);
        if peak_amplitude(c,m) <= 0, continue, end
        
        base_limit = prctile(E, baseline_prct);
        baseline_samples = E(E <= base_limit);
        if isempty(baseline_samples), continue, end
        
        baseline_mean = mean(baseline_samples);
        baseline_std  = std(baseline_samples);
        thr = baseline_mean + k_thr * baseline_std;
        
        if thr >= peak_amplitude(c,m)
            thr = 0.8 * peak_amplitude(c,m);
        end
        thr_used(c,m) = thr;
        
        active = E >= thr;
        if ~any(active), continue, end
        
        active_ext = [active; active];
        idx_peak_ext = idx_peak;
        if active_ext(idx_peak + n_points), idx_peak_ext = idx_peak + n_points; end
        
        d = diff([0; active_ext; 0]);
        seg_start = find(d == 1);
        seg_end   = find(d == -1) - 1;
        idx_seg_peak = find(seg_start <= idx_peak_ext & seg_end >= idx_peak_ext, 1);
        if isempty(idx_seg_peak), continue, end
        
        start_idx_ext = seg_start(idx_seg_peak);
        end_idx_ext   = seg_end(idx_seg_peak);
        onset_idx  = mod(start_idx_ext - 1, n_points) + 1;
        offset_idx = mod(end_idx_ext   - 1, n_points) + 1;
        onset_angle(c,m)  = AngBase(onset_idx);
        offset_angle(c,m) = AngBase(offset_idx);
        
        if offset_angle(c,m) >= onset_angle(c,m)
            burst_duration(c,m) = offset_angle(c,m) - onset_angle(c,m);
        else
            burst_duration(c,m) = (360 - onset_angle(c,m)) + offset_angle(c,m);
        end
    end
end

% Media e Variabilità
TimingSummary = table(muscle_names', ...
    mean(onset_angle, 1, 'omitnan')', std(onset_angle, 0, 1, 'omitnan')', ...
    mean(offset_angle, 1, 'omitnan')', std(offset_angle, 0, 1, 'omitnan')', ...
    mean(burst_duration, 1, 'omitnan')', std(burst_duration, 0, 1, 'omitnan')', ...
    mean(peak_angle, 1, 'omitnan')', std(peak_angle, 0, 1, 'omitnan')', ...
    'VariableNames', {'Muscle', 'OnsetMean','OnsetSD','OffsetMean','OffsetSD',...
    'DurationMean','DurationSD','PeakMean','PeakSD'});
disp('--- TIMING SUMMARY ---');
disp(TimingSummary);


%% --- 18 TEMPORAL SYMMETRY ANALYSIS ---
TimingSym_Onset    = NaN(n_valid,8);
TimingSym_Peak     = NaN(n_valid,8);
TimingSym_Duration = NaN(n_valid,8);

for k = 1:8
    R_idx = k;
    L_idx = k + 8;
    
    % Shift di 180° per la gamba sinistra
    ideal_onset_L = mod(onset_angle(:,L_idx) + 180, 360);                      
    diff_onset = mod(onset_angle(:,R_idx) - ideal_onset_L + 180, 360) - 180;   
    TimingSym_Onset(:,k) = abs(diff_onset);                                    
    
    ideal_peak_L = mod(peak_angle(:,L_idx) + 180, 360);                        
    diff_peak = mod(peak_angle(:,R_idx) - ideal_peak_L + 180, 360) - 180;      
    TimingSym_Peak(:,k) = abs(diff_peak);                                      
    
    TimingSym_Duration(:,k) = abs(burst_duration(:,R_idx) - burst_duration(:,L_idx)); 
end

TimingScore = (mean(TimingSym_Onset,1,'omitnan') + mean(TimingSym_Peak,1,'omitnan') + ...
               mean(TimingSym_Duration,1,'omitnan')) / 3;

T_TimingSym = table(pair_names_short', ...
    mean(TimingSym_Onset,1,'omitnan')', mean(TimingSym_Peak,1,'omitnan')', ...
    mean(TimingSym_Duration,1,'omitnan')', TimingScore', ...
    'VariableNames', {'MusclePair', 'OnsetError', 'PeakError', 'DurError', 'TimingScore'});
disp('--- TEMPORAL SYMMETRY ANALYSIS ---');
disp(T_TimingSym);



%% --- PLOT 1: SYMMETRY INDEX DIREZIONALE ---
% Mostra se il soggetto usa più la destra (barre positive) o la sinistra (negative)
figure('Name','Symmetry Index Direzionale','Units','normalized','Position',[0.1 0.1 0.6 0.4]);
b = bar(SI_iEMG_mean, 'FaceColor', 'flat');
% Coloriamo in rosso le asimmetrie forti (> 15% o < -15%)
for k = 1:8
    if abs(SI_iEMG_mean(k)) > 15
        b.CData(k,:) = [0.8 0.2 0.2]; % Rosso
    else
        b.CData(k,:) = [0.2 0.6 0.2]; % Verde
    end
end
xticks(1:8); xticklabels(pair_names_short); xtickangle(30);
ylabel('SI (%) [Positivo = Destra, Negativo = Sinistra]');
title('Muscular Symmetry Index (Mean)');
yline(0, 'k-', 'LineWidth', 1.5);
grid on;

%% --- PLOT 2: CO-CONTRACTION INDEX (CCI) ---
% Mostra quanto i muscoli antagonisti lavorano insieme
figure('Name','Co-Contraction Index','Units','normalized','Position',[0.1 0.5 0.6 0.4]);
bar(CCI_env_mean, 'FaceColor', [0.4 0.4 0.8]);
hold on;
errorbar(1:n_pairs, CCI_env_mean, CCI_env_std, 'k.', 'LineWidth', 1.2);
xticks(1:n_pairs); xticklabels(pair_names); xtickangle(30);
ylabel('CCI (0 to 1)');
title('Co-Contraction Index (Antagonist Pairs)');
grid on;

%% --- PLOT 3: TIMING MAP (Onset to Offset) ---
% Visualizza graficamente quando ogni muscolo è "acceso" durante il ciclo
figure('Name','Muscle Timing Map','Units','normalized','Position',[0.1 0.1 0.7 0.7]);
hold on;
for m = 1:16
    start_ang = TimingSummary.OnsetMean(m);
    dur = TimingSummary.DurationMean(m);
    
    % Se il burst attraversa lo 0 (es. inizia a 350 e finisce a 20)
    if (start_ang + dur) > 360
        % Disegna fino a 360
        rectangle('Position', [start_ang, m-0.4, 360-start_ang, 0.8], 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'none');
        % Disegna il pezzo rimanente da 0
        rectangle('Position', [0, m-0.4, (start_ang + dur)-360, 0.8], 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'none');
    else
        rectangle('Position', [start_ang, m-0.4, dur, 0.8], 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'none');
    end
    
    % Aggiungi un punto per il picco massimo
    plot(TimingSummary.PeakMean(m), m, 'k*', 'MarkerSize', 8);
end
yticks(1:16); yticklabels(muscle_names);
xlabel('Crank Angle [°]');
ylabel('Muscles');
title('Muscle Activation Timing (Onset-Offset & Peak)');
xlim([0 360]); xticks(0:45:360);
grid on;
set(gca, 'YDir', 'reverse'); % Mette il primo muscolo in alto
