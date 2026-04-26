%Before run this code you must import TRIKE ad EMG for the TRIKE and run
%the codes EMG_TRIKE and TRIKE

% Trova il primo reset dell'angolo nel Trike
idx_trike_start = find(diff(datatrike.angle) < -300, 1) + 1;
time_trike_start = t_trike(idx_trike_start); % Tempo zero per la bici


% Supponendo che 'emg_data' sia la tua matrice EMG importata
% Il Canale 17 è il trigger 
trigger_signal = data_f(:, 1);



n_sample = size(trigger_signal);
t_emg = (0:n_sample-1) / target;
t_emg=t_emg';



% Ora selezioni (il trigger)
trigger_signal = data_f(:, 1);

% Adesso la funzione 'find' funzionerà correttamente
idx_emg_start = find(trigger_signal > 1.5, 1);



% Se hai il vettore tempo dell'EMG (t_emg):
time_emg_start = t_emg(idx_emg_start); % Tempo zero per l'EMG


% Tagliamo i dati del Trike dall'inizio della prima pedalata in poi
trike_synced = datatrike.angle(idx_trike_start:end);

% Tagliamo i dati EMG dal primo trigger in poi
emg_synced = data(idx_emg_start:end, :);




%% 1. Preparazione dei dati sincronizzati
% Frequenze di campionamento (controlla i valori esatti nel tuo dataset)
fs_trike = 100;
fs_emg = target;

% --- TAGLIO E SINCRONIZZAZIONE ---
emg_synced = data_f(idx_emg_start:end, :);
t_emg_sync = (0:size(emg_synced, 1)-1) / target;

% Prepariamo il trigger per il plot (normalizzato 0-1)
trigger_plot = trigger_signal(idx_emg_start:end);
trigger_plot = (trigger_plot - min(trigger_plot)) / (max(trigger_plot) - min(trigger_plot));

%% --- PLOT DI VERIFICA FINALE ---
figure('Name', 'Sincronizzazione Raggiunta', 'Color', 'w');

subplot(2,1,1);
plot(t_trike_sync, trike_synced/360, 'b', 'LineWidth', 1.5); hold on;
plot(t_emg_sync, trigger_plot, 'r', 'LineWidth', 1);
title('Sincronizzazione: Angolo (Blu) e Trigger Filtrato (Rosso)');
xlim([0 10]); grid on;

subplot(2,1,2);
plot(t_trike_sync, trike_synced/360, 'b', 'LineWidth', 1.5); hold on;
plot(t_emg_sync, trigger_plot, 'r', 'LineWidth', 1);
title('ZOOM: Il picco rosso deve allinearsi alla caduta della rampa blu');
xlabel('Tempo [s]');
xlim([2 5]); % Zoom su qualche pedalata
grid on;





%%


%% --- 1. DEFINIZIONE CANALI E PARAMETRI ---

n_canali = length(channels);
AngBase = linspace(0, 359, 360);

% Identificazione di tutti i cicli tramite il trigger (Colonna 1)
% Usiamo findpeaks sul valore assoluto per sicurezza visto che è filtrato
trigger_vettore = emg_synced(:, 1);
[~, locs_emg_sync] = findpeaks(trigger_vettore, 'MinPeakHeight', 1.5, 'MinPeakDistance', target*0.8);

%% --- 2. ELABORAZIONE E NORMALIZZAZIONE TEMPORALE ---
EMG_mat = cell(n_canali, 1);

for m = 2:n_canali % Partiamo da 2 per saltare il trigger
    
    % Estrazione segnale numerico
    raw_signal = emg_synced(:, m);
    
    % --- PRE-PROCESSING (Rettifica e Inviluppo) ---
    % Se i tuoi dati data_f non sono ancora stati rettificati, lo facciamo qui:
    rectified = abs(raw_signal); 
    % Low-pass a 6Hz per creare l'inviluppo (inv)
    [b, a] = butter(4, 6/(target/2), 'low');
    envelope = filtfilt(b, a, rectified);
    
    num_pedalate = length(locs_emg_sync) - 1;
    EMG_mat{m} = zeros(360, num_pedalate);
    
    for i = 1:num_pedalate
        inizio = locs_emg_sync(i);
        fine = locs_emg_sync(i+1);
        
        % Taglio della "fetta" di inviluppo
        fetta = envelope(inizio:fine);
        
        % Interpolazione a 360 punti
        t_orig = linspace(0, 1, length(fetta));
        t_norm = linspace(0, 1, 360);
        EMG_mat{m}(:, i) = interp1(t_orig, fetta, t_norm, 'spline');
    end
end

%% --- 3. PLOT A PAGINE (6 muscoli per pagina) ---
page = 6;
% Partiamo da m=2 per escludere il trigger dai grafici dei muscoli
for m = 2:n_canali
    if mod(m-2, page) == 0
        figure('Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
        ti = tiledlayout(3, 2, 'TileSpacing', 'compact');
        on_page = ceil((m-1) / page);
        title(ti, ['Profili Muscolari Medi - Pagina ', num2str(on_page)]);
    end
    
    nexttile;
    % Plot di tutti i cicli (grigio) e della media (nero)
    plot(AngBase, EMG_mat{m}, 'Color', [0.8 0.8 0.8]); hold on;
    plot(AngBase, mean(EMG_mat{m}, 2), 'k', 'LineWidth', 2.5);
    
    title(channels{m});
    xlim([0 360]);
    xlabel('Angolo [°]');
    ylabel('Ampiezza [uV]');
    grid on;
end




%%

%% --- 1. ELABORAZIONE DATI TRIKE (POTENZA) ---
% Sincronizziamo la potenza usando gli stessi reset dell'angolo usati per l'EMG
powR_raw = datatrike.powerRight(idx_trike_start:end);
powL_raw = datatrike.powerLeft(idx_trike_start:end);
locs_trike = find(diff(trike_synced) < -300); 

num_ped_trike = length(locs_trike) - 1;
PowerR_mat = zeros(360, num_ped_trike);
PowerL_mat = zeros(360, num_ped_trike);

for i = 1:num_ped_trike
    % Estrazione e normalizzazione potenza Destra
    fettaR = powR_raw(locs_trike(i):locs_trike(i+1));
    PowerR_mat(:, i) = interp1(linspace(0,1,length(fettaR)), fettaR, linspace(0,1,360), 'linear');
    
    % Estrazione e normalizzazione potenza Sinistra
    fettaL = powL_raw(locs_trike(i):locs_trike(i+1));
    PowerL_mat(:, i) = interp1(linspace(0,1,length(fettaL)), fettaL, linspace(0,1,360), 'linear');
end

% Calcolo medie potenza
meanPowR = mean(PowerR_mat, 2);
meanPowL = mean(PowerL_mat, 2);

%% --- 2. PLOT INTEGRATO (EMG + POTENZA) ---
% Useremo una figura per muscolo o raggruppate. 
% Qui te ne metto 4 per pagina (EMG e Potenza occupano spazio)
muscoli_per_pagina = 4;

for m = 2:n_canali
    if mod(m-2, muscoli_per_pagina) == 0
        figure('Units', 'normalized', 'Position', [0.05 0.05 0.9 0.9]);
        t = tiledlayout(muscoli_per_pagina, 1, 'TileSpacing', 'compact');
        title(t, ['Analisi Sincronizzata EMG vs Potenza - Pagina ', num2str(ceil((m-1)/muscoli_per_pagina))]);
    end
    
    % Creiamo un "sub-layout" per ogni riga (EMG sopra, Potenza sotto)
    nexttile;
    hold on;
    
    % Selezioniamo la potenza corretta in base al nome del canale
    if contains(channels{m}, ' R')
        current_power = meanPowR;
        p_color = [0.85 0.33 0.1]; % Arancione/Rosso per Destra
    else
        current_power = meanPowL;
        p_color = [0.47 0.67 0.19]; % Verde per Sinistra
    end
    
    % Plot EMG (Asse sinistro)
    yyaxis left
    plot(AngBase, mean(EMG_mat{m}, 2), 'k', 'LineWidth', 2);
    ylabel('EMG [uV]');
    ylim([0 max(mean(EMG_mat{m}, 2))*1.2]); % Autoscale pulito
    
    % Plot POTENZA (Asse destro)
    yyaxis right
    plot(AngBase, current_power, 'Color', p_color, 'LineWidth', 1.5, 'LineStyle', '--');
    ylabel('Potenza [W]');
    
    title(['Canale: ', channels{m}]);
    grid on;
    xlim([0 360]);
    if m == n_canali || mod(m-1, muscoli_per_pagina) == 0, xlabel('Angolo Pedale [°]'); end
end




