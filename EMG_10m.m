%% INTRO

% Right Leg (1-9)
% 1. Tibialis anterior R 
% 2. Gastro lat R 
% 3. Soleus R 
% 4. Gastro med R 
% 5. Rectus R   
% 6. Vastus Lat R 
% 7. Vastus Med R 
% 8. Semitendinous R 
% 9. Tibialis anterior L 
% 10. Gastro lat L 
% 11. Soleus L 
% 12. Gastro med L 
% 13. Rectus L 
% 14. Vastus Lat L 
% 15. Vastus Med L 
% 16. Semitendinous L 

channels = {'Tibialis Ant R', 'Gastro Lat R', 'Soleus R', 'Gastro Med R', ...
           'Rectus R', 'Vastus Lat R', 'Vastus Med R', 'Semitendinous R', ...
           'Tibialis Ant L', 'Gastro Lat L', 'Soleus L', 'Gastro Med L', ...
           'Rectus L', 'Vastus Lat L', 'Vastus Med L', 'Semitendinous L', 'Trigger'};



%convert struct to array: easier to work on...
data_array1 = struct2array(data_resampled);

%different frequency, we have to resample at same frequency
fs_emg = 2148.15; %channels (1-16)
fs_trig = 2222.22; % channel (17)
fs_target = 2000;  % frequency target

emg_raw = data_array1(:, 2:17);
trig_raw = data_array1(:, 1);  

% Resampling channels 1-16 muscles
emg_resampled = resample(emg_raw, fs_target, round(fs_emg));

% Resampling channel 17 trigger
trig_resampled = resample(trig_raw, fs_target, round(fs_trig));

% find min length betweend the 2 signals resampled
min_len = min(size(emg_resampled, 1), length(trig_resampled));

% Taglia entrambi alla stessa lunghezza
emg_final = emg_resampled(1:min_len, :);
trig_final = trig_resampled(1:min_len);

% Ora puoi riunirli in un'unica matrice "pulita"
data_array = [emg_final, trig_final]; 
fs_channels = fs_target; % Da qui in poi userai sempre 2000 Hz


%% PLOT RAW DATA



%calculate time for one channel, will be the same length for the others
n_sample = size(data_array, 1);
t = (0:n_sample-1) / fs_channels;
t=t';

page=6;

for i = 1:17


    % --- PAGE BREAK LOGIC ---
    % Creates a new figure every 6 channels
    if mod(i-1, page) == 0
        figure('Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
        ti = tiledlayout(3, 2, 'TileSpacing', 'compact'); % Grid 3x2 per page
        on_page = ceil(i / page);
        title(ti, ['EMG raw data - Page ', num2str(on_page)]);
    end


    nexttile;
    plot(data_array(:,i));
    title(channels{i}, 'Interpreter', 'none');
end


%% BAND-PASS FILTERING

% Band-pass filter 5th order
% cut off frequency = [20-400] Hz 
W= [20; 400];
Wn = W/(fs_channels/2); %normalized frequency
[b,a ]= butter(5,Wn,"bandpass");



%cancel NaN values: every NaN values = 0 with:
data_isnan=fillmissing(data_array, 'constant', 0);
%filter for every channel
data_f= filtfilt(b,a,data_isnan);



%calculate AGAIN (gives problem with dimension) time for one channel, will be the same length for the others
n_sample = size(data_f, 1);
t_f = (0:n_sample-1) / fs_channels;
t_f=t_f';


page=6;

for i = 1:17

 
    % --- PAGE BREAK LOGIC ---
    % Creates a new figure every 6 channels

    if mod(i-1, page) == 0
        figure('Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
        ti = tiledlayout(3, 2, 'TileSpacing', 'compact'); % Griglia 3x2 per pagina
        on_page = ceil(i / page);
        title(ti, ['EMG_filtered - Page ', num2str(on_page)]);
    end


    nexttile;
    plot(data_f(:,i));
    title(channels{i}, 'Interpreter', 'none');
end




%%




trigger_gait = data_f(:, 17);

% Usiamo una soglia e una distanza minima (MinPeakDistance)
% Se fs è 2000Hz, 1 secondo = 2000 campioni. Un passo è circa 0.8-1.2s.
[~, heel_strikes] = findpeaks(abs(trigger_gait), 'MinPeakHeight', 0.05, 'MinPeakDistance', fs_channels*0.5);


% Esegui l'inviluppo (RMS o Rectify + Low Pass) sull'EMG prima di tagliare!
emg_rect = abs(data_f(:, 7)); 
[b, a] = butter(4, 6/(fs_channels/2), 'low'); % Filtro passa-basso a 6Hz per l'inviluppo
emg_env = filtfilt(b, a, emg_rect);

% Taglia e normalizza
for i = 1:length(heel_strikes)-1
    segmento = emg_env(heel_strikes(i):heel_strikes(i+1));
    % Normalizziamo a 101 punti (da 0% a 100% del passo)
    passi_matrice(i, :) = interp1(1:length(segmento), segmento, linspace(1, length(segmento), 101));
end


%% --- PLOT DINAMICA MUSCOLARE (SINGOLO PASSO) ---

% 1. Parametri e controllo
n_passo = 2; % Scegliamo il secondo passo
if length(heel_strikes) < n_passo + 1
    error('Passi insufficienti per il plot. Controlla il rilevamento degli heel strikes.');
end

% 2. Definizione indici temporali
idx_inizio = heel_strikes(n_passo);
idx_fine = heel_strikes(n_passo + 1);
t_passo = (0:(idx_fine - idx_inizio)) / fs_channels; 

% 3. Creazione Figura
figure('Name', 'Analisi Muscolare Passo Singolo (10m Walk)', ...
       'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);

for i = 1:16
    subplot(4, 4, i);
    
    % Estrazione segnale filtrato (inviluppo consigliato per vedere l'attivazione)
    segmento_raw = data_f(idx_inizio:idx_fine, i); 
    
    % Calcolo inviluppo al volo per pulizia visiva
    segmento_env = envelope(abs(segmento_raw), 150, 'peak'); 
    
    % Plot
    plot(t_passo, segmento_raw, 'Color', [0.7 0.7 0.7]); % EMG grezzo in grigio
    hold on;
    plot(t_passo, segmento_env, 'r', 'LineWidth', 1.5);    % Inviluppo in rosso
    
    % Titolo usando i tuoi nomi
    title(channels{i}, 'FontSize', 10);
    
    % Estetica
    grid on;
    axis tight;
    if mod(i, 4) ~= 1, yticks([]); end % Toglie etichette Y centrali
    if i < 13, xticks([]); end         % Toglie etichette X superiori
end

sgtitle(['Analisi Ciclo del Passo - Muscoli Gamba R e L (Passo ' num2str(n_passo) ')']);%% 4 - Power spectral density estimate & extraction of spectral parameters

%%


[P_EMG,F] = periodogram(data_array, rectwin(max(size(data_array))),512,fs_channels); 

% plot of the power spectral density estimate of the right RF
figure ()
subplot(2,1,1)
plot(F,10*log10(P_EMG(:,7)),'b')
title('Periodogram Power Spectral Density Estimate','b')
xlabel('Frequency (Hz)')
ylabel('Power/frequency (dB/Hz)')
grid on
ylim([ -120 0])
xlim([0 fs_channels/2])

%estimates the mean frequency & median frequency
for n=1:12
       Mean_freq(n,1)=meanfreq( data_array(:,n) , fs_channels );
       Mean_freq(n,2) = meanfreq( P_EMG(:,n) , F ); 

       Med_freq(n,1) = medfreq( data_array(:,n) , fs_channels );
       Med_freq(n,2) = medfreq( P_EMG(:,n) , F ); 
end

%% --- CALCOLO AREA MEDIA (iEMG) PER TUTTI I CANALI ---

% 1. Scegli quali trigger usare (cambia tra heel_strikes e locs_trig a seconda del test)
trig_attuali = locs_trig; % Metti locs_trig per il Trike, heel_strikes per il Cammino
n_cicli = length(trig_attuali) - 1;

% 2. Inizializza matrice per i risultati (Cicli x Canali)
aree_cicli = zeros(n_cicli, 16);

for c = 1:n_cicli
    idx_in = trig_attuali(c);
    idx_fi = trig_attuali(c+1);
    
    for ch = 1:16
        % Prendiamo il segnale rettificato (valore assoluto)
        seg_rect = abs(data_f(idx_in:idx_fi, ch));
        
        % Calcoliamo l'area con la regola dei trapezi e normalizziamo per la durata
        % Questo ci dà l'attivazione media del muscolo in quel ciclo
        aree_cicli(c, ch) = trapz(seg_rect) / length(seg_rect);
    end
end

% 3. Calcoliamo la media finale per ogni muscolo
area_finale = mean(aree_cicli, 1);

% 4. Creazione Tabella Risultati
tabella_risultati = table(channels(1:16)', area_finale', ...
    'VariableNames', {'Muscolo', 'Area_Media_iEMG'});

% Mostra la tabella nella Command Window
disp('--- RISULTATI AREA MEDIA PER MUSCOLO ---');
disp(tabella_risultati);
