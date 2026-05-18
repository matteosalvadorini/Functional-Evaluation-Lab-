%% Make sure you have first imported CAPTIKS, run 'CAPTIKS.m', and imported 'EMG 10m walk test'.

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
    data_array = table2array(data);
end

% Separate EMG and trigger
data_emg     = data_array(:, 1:16);
%trigger_sig = data_array(:, 17);   % NOT filtered

n_samples = size(data_array,1);

t = (0:n_samples-1)' / fs_EMG;



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

fprintf('\nRight heel strikesx detected: %d\n', length(hs_R));
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







fprintf('\n--- Avvio Sincronizzazione Specifica Tibialis Ant L ---\n');

idx_TA_L = 9; % Il Tibialis Ant L è il nono canale dell'EMG

% --- 1. Calcolo Inviluppo del Tibialis Anterior Left ---
fc_env = 6; % Frequenza di taglio per l'inviluppo (6 Hz)
[b_env, a_env] = butter(4, fc_env/(fs_EMG/2), 'low');

ta_l_rect = abs(data_f_clean(:, idx_TA_L));
ta_l_rect(isnan(ta_l_rect)) = 0; % Gestione dei NaN dovuti all'artifact rejection
ta_l_env = filtfilt(b_env, a_env, ta_l_rect);

% --- 2. Preparazione del Proxy di Movimento CAPTIKS (Giroscopio Sinistro) ---
% Usiamo il modulo del giroscopio sinistro normalizzato a 1
cap_proxy = abs(left_Gyro_foot);
cap_proxy = cap_proxy / (max(cap_proxy) + eps);

% --- 3. Ricampionamento dell'Inviluppo EMG a 100 Hz (Frequenza CAPTIKS) ---
ta_l_env_res = resample(ta_l_env, fs, round(fs_EMG));
ta_l_env_res = ta_l_env_res / (max(ta_l_env_res) + eps); % Normalizzazione a 1

% --- 4. Cross-Correlazione per trovare il Ritardo (Lag) ---
% Configura un ritardo massimo esplorabile di 5 secondi
N_xcorr = min(length(cap_proxy), length(ta_l_env_res));
max_lag_samp = round(5 * fs); 

[xc, lags] = xcorr(ta_l_env_res(1:N_xcorr), cap_proxy(1:N_xcorr), max_lag_samp);

% Trova il picco massimo di correlazione
[~, best_idx] = max(xc);
best_lag_samp = lags(best_idx);
sync_offset_s = best_lag_samp / fs; % Disallineamento temporale in secondi

fprintf('  Lag Ottimale Rilevato: %d campioni CAPTIKS = %.3f secondi\n', ...
    best_lag_samp, sync_offset_s);

% --- 5. Creazione degli Assi Temporali Sincronizzati ---
% Costruiamo un asse temporale comune per poterli graficare insieme
t_cap = (0:length(cap_proxy)-1)' / fs;
t_emg_aligned = ((0:length(ta_l_env)-1)' / fs_EMG) - sync_offset_s;

% --- 6. Grafico di Verifica dell'Allineamento ---
figure('Name','Verifica Sincronizzazione TA-L e CAPTIKS', 'Units','normalized', 'Position',[0.1 0.3 0.8 0.4]);
plot(t_emg_aligned, ta_l_env / max(ta_l_env), 'r', 'LineWidth', 1.5); hold on;
plot(t_cap, cap_proxy, 'k', 'LineWidth', 1.2);
xlabel('Tempo Sincronizzato (secondi)');
ylabel('Ampiezza Normalizzata (a.u.)');
title(sprintf('Allineamento Segnali (Ritardo Corretto = %.3f s)', sync_offset_s));
legend('Inviluppo EMG Tibialis Ant L', 'Modulazione Giroscopio CAPTIKS L');
grid on;




%% =========================================================================
%% PLOT COMPLETO CON RETTANGOLO INTERATTIVO POSIZIONATO SULLA FSM (GRAFICO 3)
%% =========================================================================
fprintf('\n=== AVVIO PROCEDURA DI RITAGLIO INTERATTIVO (RETTANGOLO SU FSM/ANGOLO) ===\n');

idx_TA_L = 9; % Canale Tibialis Ant L

% 1. Estrazione Heel Strikes della gamba sinistra (dalla FSM del tuo codice)
hs_L_idx = find(State_left(1:end-1) ~= 0 & State_left(2:end) == 0) + 1;

% 2. Calcolo Inviluppo EMG per il confronto visivo
fc_env = 6; 
[b_env, a_env] = butter(4, fc_env/(fs_EMG/2), 'low');
ta_l_rect = abs(data_f_clean(:, idx_TA_L));
ta_l_rect(isnan(ta_l_rect)) = 0; 
ta_l_env = filtfilt(b_env, a_env, ta_l_rect);

% 3. Calcolo del Lag ottimale (Cross-correlazione di background)
cap_proxy = abs(left_Gyro_foot);
cap_proxy = cap_proxy / (max(cap_proxy) + eps);
ta_l_env_res = resample(ta_l_env, fs, round(fs_EMG));
ta_l_env_res = ta_l_env_res / (max(ta_l_env_res) + eps);

N_xcorr = min(length(cap_proxy), length(ta_l_env_res));
max_lag_samp = round(5 * fs); 
[xc, lags] = xcorr(ta_l_env_res(1:N_xcorr), cap_proxy(1:N_xcorr), max_lag_samp);
[~, best_idx] = max(xc);
sync_offset_s = lags(best_idx) / fs;

% 4. Creazione degli assi temporali REALI Sincronizzati
t_cap = (0:length(cap_proxy)-1)' / fs;
t_emg = ((0:length(ta_l_env)-1)' / fs_EMG) - sync_offset_s;

emg_grezzo_canale = data_f_clean(:, idx_TA_L);

% 5. Creazione della figura a 3 grafici
fig_select = figure('Name', 'Ritaglio Sincronizzato: Selezione attiva su FSM/Angolo', ...
                    'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);

% --- GRAFICO 1: EMG (Sopra) ---
ax1 = subplot(3,1,1);
plot(t_emg, emg_grezzo_canale, 'b'); hold on;
plot(t_emg, ta_l_env, 'r', 'LineWidth', 1.5); 
ylabel('EMG Tibialis Ant L (mV)');
grid on;
legend('Grezzo', 'Inviluppo');

% --- GRAFICO 2: Giroscopio CAPTIKS (Centro) ---
ax2 = subplot(3,1,2);
plot(t_cap, left_Gyro_foot, 'k', 'LineWidth', 1.2);
ylabel('Giroscopio Caviglia L (deg/s)');
grid on;

% --- GRAFICO 3: FSM e Fasi del Passo (Sotto) -> QUI METTIAMO IL RETTANGOLO ---
ax3 = subplot(3,1,3);
yyaxis left
plot(t_cap, left_Ankle_angle_phi_x, 'm-', 'LineWidth', 1.5);
ylabel('Angolo Caviglia L (deg)');
hold on;
if ~isempty(hs_L_idx)
    plot(t_cap(hs_L_idx), left_Ankle_angle_phi_x(hs_L_idx), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
end

yyaxis right
plot(t_cap, State_left, 'g--', 'LineWidth', 1.2);
ylabel('Stato FSM (Fasi)');
ylim([-0.5 4.5]);
xlabel('Tempo Sincronizzato (secondi)');
grid on;
title('Regola il rettangolo VERDE QUI SOTTO sulle fasi del passo. Poi premi INVIO.');

% COLLEGAMENTO DELLE TRE TIMELINE (linkaxes)
linkaxes([ax1, ax2, ax3], 'x');

% Limitiamo la visualizzazione alla finestra utile comune
xmin = max(min(t_emg), min(t_cap));
xmax = min(max(t_emg), max(t_cap));
xlim([xmin xmax]);

% --- ATTIVAZIONE RETTANGOLO SULLA FSM (ax3) ---
% Selezioniamo l'asse Y sinistro di ax3 per prendere i limiti geometrici corretti
yyaxis left
ylim_ax3 = get(ax3, 'YLim');
y_pos = ylim_ax3(1);
h_pos = diff(ylim_ax3);

% Posizione X iniziale (30% centrale del grafico)
x_init = xmin + (xmax-xmin)*0.35;
w_init = (xmax-xmin)*0.3;

% Disegniamo il rettangolo agganciato ad ax3 (FSM / Angolo)
roi = drawrectangle(ax3, 'Position', [x_init, y_pos, w_init, h_pos], 'Color', 'g');

% Listener per forzare il blocco verticale del rettangolo su ax3 durante il movimento
addlistener(roi, 'MovingROI', @(src, evt) set(src, 'Position', [evt.CurrentPosition(1), y_pos, evt.CurrentPosition(3), h_pos]));
addlistener(roi, 'ROIMoved',  @(src, evt) set(src, 'Position', [evt.CurrentPosition(1), y_pos, evt.CurrentPosition(3), h_pos]));

% Pausa per attendere l'invio dell'utente
pause; 

% 6. Estrazione dei limiti temporali scelti
pos = roi.Position; 
t_inizio = pos(1);
t_fine = pos(1) + pos(3);

if ishandle(fig_select), close(fig_select); end

% 7. Taglio dei segnali usando la finestra definita sulla FSM
indici_emg_validi = (t_emg >= t_inizio) & (t_emg <= t_fine);
indici_cap_validi = (t_cap >= t_inizio) & (t_cap <= t_fine);

t_emg_tagliato    = t_emg(indici_emg_validi);
emg_tagliato      = emg_grezzo_canale(indici_emg_validi);
emg_env_tagliato  = ta_l_env(indici_emg_validi);

t_cap_tagliato    = t_cap(indici_cap_validi);
gyro_cap_tagliato = left_Gyro_foot(indici_cap_validi);
angle_cap_tagliato = left_Ankle_angle_phi_x(indici_cap_validi);
fsm_tagliata      = State_left(indici_cap_validi);

fprintf('  Ritaglio completato con successo basandosi sui cicli della FSM!\n');
fprintf('  Intervallo selezionato: da %.2f s a %.2f s\n', t_inizio, t_fine);

% 8. Grafico finale di verifica di tutti i dati pronti all'uso
figure('Name', 'Verifica Dati Finali Sincronizzati e Tagliati');
subplot(3,1,1);
plot(t_emg_tagliato, emg_tagliato, 'b'); hold on;
plot(t_emg_tagliato, emg_env_tagliato, 'r', 'LineWidth', 1.5);
title('EMG Tibialis Ant L Tagliato (Riferimento FSM)'); grid on;

subplot(3,1,2);
plot(t_cap_tagliato, gyro_cap_tagliato, 'k', 'LineWidth', 1.5);
title('Giroscopio CAPTIKS L Tagliato'); grid on;

subplot(3,1,3);
yyaxis left; plot(t_cap_tagliato, angle_cap_tagliato, 'm', 'LineWidth', 1.5); ylabel('Angolo');
yyaxis right; plot(t_cap_tagliato, fsm_tagliata, 'g--', 'LineWidth', 1.5); ylabel('Fase FSM');
title('Angolo e FSM CAPTIKS Tagliati'); grid on; xlabel('Tempo Sincronizzato (s)');











%% =========================================================================
%% ELABORAZIONE E GRAFICI (ATTIVAZIONE E CCI) SULLA FINESTRA GIÀ RITAGLIATA
%% =========================================================================
fprintf('\n=== AVVIO CALCOLO MUSCLE ACTIVATION & CCI SULLA FINESTRA CORRENTE ===\n');

% 1. PROTEZIONE COMPLETA: Creazione forzata delle variabili per evitare qualunque "Undefined"
outlier_channels = false(16, 1); % Inizializza tutti i canali come validi

% Caricamento nomi reali dei muscoli dal tuo protocollo
channel_names = { ...
    'Tibialis Ant R',  'Gastro Lat R', 'Soleus R',      'Gastro Med R', ...
    'Rectus R',        'Vastus Lat R', 'Vastus Med R',   'Semitendinous R', ...
    'Tibialis Ant L',  'Gastro Lat L', 'Soleus L',       'Gastro Med L', ...
    'Rectus L',        'Vastus Lat L', 'Vastus Med L',   'Semitendinous L'};

% Controllo automatico di quale matrice di inviluppi esiste nel tuo script
if exist('data_f', 'var')
    matrix_da_tagliare = data_f;
elseif exist('data_env_norm', 'var')
    matrix_da_tagliare = data_env_norm;
elseif exist('data_f_env', 'var')
    matrix_da_tagliare = data_f_env;
else
    error('Non trovo la matrice degli inviluppi! Controlla come l''hai chiamata nel workspace.');
end

% Controllo e ricostruzione automatica dell'asse dei tempi se mancante
if ~exist('t_emg', 'var')
    if exist('fs_EMG', 'var') && exist('sync_offset_s', 'var')
        t_emg = ((0:size(matrix_da_tagliare,1)-1)' / fs_EMG) - sync_offset_s;
    else
        error('Manca l''asse dei tempi t_emg nel workspace.');
    end
end

% 2. Taglio automatico di tutti i 16 canali sulla base dei tempi già salvati dal rettangolo
indici_emg_validi = (t_emg >= t_inizio) & (t_emg <= t_fine);
t_emg_tagliato = t_emg(indici_emg_validi);

% Creazione asse percentuale (0-100%) riferito alla finestra tagliata
t_pct = (t_emg_tagliato - t_inizio) / (t_fine - t_inizio) * 100;

% Ritaglio effettivo della matrice dei dati
env_tagliato_all = matrix_da_tagliare(indici_emg_validi, :);


soglia_percentuale = 0.25; % 25% come nella sezione 10 del tuo script originale


%% =========================================================================
%% 1. CALCOLO ACCURATO ONSET/OFFSET (METODO DA SCRIPT ORIGINALE)
%% =========================================================================
onsets = nan(16,1); offsets = nan(16,1); peaks = nan(16,1);
min_dist = round(0.5 * fs_EMG); % Distanza minima per picchi consistenti

for j = 1:16
    if outlier_channels(j), continue; end
    
    ch_env = env_tagliato_all(:, j);
    if all(isnan(ch_env)) || max(ch_env) == 0, continue; end
    
    % Applica la logica originale: Trova il picco principale con findpeaks
    ta_thresh = soglia_percentuale * max(ch_env);
    [pks, locs] = findpeaks(ch_env, 'MinPeakHeight', ta_thresh, 'MinPeakDistance', min_dist);
    
    if ~isempty(pks)
        % Se trova dei picchi robusti, prendiamo il picco massimo tra quelli rilevati
        [~, max_p_idx] = max(pks);
        main_peak_idx = locs(max_p_idx);
        peaks(j) = t_pct(main_peak_idx);
        
        % Trova la zona di attivazione attorno al picco (dove il segnale sta sopra la soglia)
        is_above = ch_env > ta_thresh;
        idx_sopra = find(is_above);
        
        % L'onset è il primo punto sopra soglia adiacente alla salita del picco
        idx_prima = idx_sopra(idx_sopra <= main_peak_idx);
        if ~isempty(idx_prima), onsets(j) = t_pct(idx_prima(1)); else, onsets(j) = t_pct(idx_sopra(1)); end
        
        % L'offset è l'ultimo punto sopra soglia prima che scenda definitivamente
        idx_dopo = idx_sopra(idx_sopra >= main_peak_idx);
        if ~isempty(idx_dopo), offsets(j) = t_pct(idx_dopo(end)); else, offsets(j) = t_pct(idx_sopra(end)); end
    else
        % Fallback di sicurezza: se findpeaks non isola picchi ma c'è segnale diffuso
        [max_val, max_idx] = max(ch_env);
        peaks(j) = t_pct(max_idx);
        idx_attivi = find(ch_env > (0.15 * max_val)); % Soglia di tolleranza bassa
        if ~isempty(idx_attivi)
            onsets(j) = t_pct(idx_attivi(1));
            offsets(j) = t_pct(idx_attivi(end));
        end
    end
end

% --- PLOT MULTI-MUSCOLO ACCURATO ---
figure('Name', 'Muscle Activation Timing (Accurate Threshold)', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
hold on;
for j = 1:16
    if outlier_channels(j)
        plot([0 100], [j j], 'Color', [0.8 0.8 0.8], 'LineStyle', ':', 'LineWidth', 1);
        text(-5, j, [channel_names{j} ' [ESCLUSO]'], 'Color', [0.6 0.6 0.6], 'HorizontalAlignment', 'right');
        continue;
    end
    
    text(-5, j, channel_names{j}, 'HorizontalAlignment', 'right', 'FontSize', 10, 'Interpreter', 'none');
    plot([0 100], [j j], 'Color', [0.92 0.92 0.92], 'LineWidth', 1); % Linea di sfondo
    
    if ~isnan(onsets(j)) && ~isnan(offsets(j))
        if j <= 8, col = [0.18 0.38 0.75]; else, col = [0.78 0.18 0.18]; end
        
        % Disegna la barra ristretta basata sulla soglia accurata dello script
        plot([onsets(j) offsets(j)], [j j], 'Color', col, 'LineWidth', 8);
        plot(peaks(j), j, 'ko', 'MarkerFaceColor', [1 0.7 0], 'MarkerSize', 6);
    end
end

set(gca, 'YTick', 1:16, 'YTickLabel', {}, 'YDir', 'reverse');
xlim([-35 105]); ylim([0.5 16.5]);
xlabel(sprintf('Finestra Temporale Selezionata (%%) [Soglia Accuratezza: %d%% del Max]', round(soglia_percentuale*100)), 'FontSize', 11);
title('Muscle Activation Timing (Rilevamento Picchi e Soglia Clinica del 25%)', 'FontSize', 12);
grid on; hold off;

%% =========================================================================
%% 2. GRAFICO CO-CONTRACTION INDEX (CCI) CON DEVIAZIONE STANDARD (SD)
%% =========================================================================
coppie = [1,9; 2,10; 3,11; 4,12; 5,13; 6,14; 7,15; 8,16];
coppie_names = {'Tib Ant R-L', 'Gastro Lat R-L', 'Soleus R-L', 'Gastro Med R-L', ...
                'Rectus R-L', 'Vastus Lat R-L', 'Vastus Med R-L', 'Semitend R-L'};
            
cci_coppie = nan(8, 1);
cci_sd     = nan(8, 1); % Vettore per salvare le deviazioni standard

for c = 1:8
    ch_A = coppie(c, 1); ch_B = coppie(c, 2);
    if outlier_channels(ch_A) || outlier_channels(ch_B), continue; end
    
    env_A = env_tagliato_all(:, ch_A); env_B = env_tagliato_all(:, ch_B);
    valid_rows = ~isnan(env_A) & ~isnan(env_B);
    if sum(valid_rows) < 10, continue; end
    
    nA = env_A(valid_rows); nB = env_B(valid_rows);
    emg_low = min(nA, nB); emg_high = max(nA, nB);
    
    % Calcolo del CCI istante per istante
    cci_istantaneo = (emg_low ./ (emg_high + eps)) .* (nA + nB);
    
    % Calcolo della Media e della Deviazione Standard sulla finestra
    cci_coppie(c) = mean(cci_istantaneo);
    cci_sd(c)     = std(cci_istantaneo); 
end

% --- PLOT CCI A BARRE CON BAFFI DI ERRORE (SD) ---
figure('Name', 'Co-contraction Index con Deviazione Standard', 'Units', 'normalized', 'Position', [0.1 0.5 0.7 0.4]);
hold on;

% 1. Disegna le barre principali
hBar = bar(1:8, cci_coppie, 'FaceColor', [0.4 0.65 0.4], 'EdgeColor', [0.2 0.4 0.2]);

% 2. Aggiunge i baffi della Deviazione Standard (errorbars)
% 'k' = colore nero, 'linestyle', 'none' evita di unire i punti, 'LineWidth' dà spessore
errorbar(1:8, cci_coppie, cci_sd, 'k', 'linestyle', 'none', 'LineWidth', 1.2, 'CapSize', 6);

xticks(1:8); xticklabels(coppie_names); xtickangle(30);
ylabel('CCI Medio \pm SD (mV)', 'FontSize', 11);
title('Co-contraction Index (CCI) di Rudolph con Deviazione Standard (\pm SD)', 'FontSize', 12);
grid on; box on;

% 3. Aggiunge le etichette di testo con i valori numerici sopra i baffi
for c = 1:8
    if isnan(cci_coppie(c))
        text(c, 0.01, 'N.D.', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'Color', 'r', 'FontWeight', 'bold');
    else
        % Posiziona il testo leggermente sopra la barra + la sua deviazione standard
        pos_y = cci_coppie(c) + cci_sd(c) + (max(cci_coppie)*0.02);
        text(c, pos_y, sprintf('%.3f \\pm %.3f', cci_coppie(c), cci_sd(c)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8, 'FontWeight', 'bold');
    end
end

hold off;