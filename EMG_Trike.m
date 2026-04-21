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







%% 4 - Power spectral density estimate & extraction of spectral parameters


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



%% 6 - Identification of the pedaling cycles


% 1. Trova gli indici dei picchi nel canale trigger (Colonna 17)
% Usiamo la frequenza originale (es. 2222.22) se non hai ancora resampato
[pks_trig, locs_trig] = findpeaks(data_f(:,17), 'MinPeakHeight', 0.5, 'MinPeakDistance', fs_channels*0.8);

% 2. Crea l'asse del tempo basato sulla lunghezza di data_array
t_array = (0:size(data_f, 1)-1)' / fs_channels;

% 3. Grafico di confronto
figure('Name', 'Sincronizzazione Canale 17 e Canale 7');

% Subplot 1: Canale Trigger (17)
ax1 = subplot(2,1,1);
plot(t_array, data_f(:,17), 'Color', [0.4 0.4 0.4]); % Grigio
hold on;
plot(t_array(locs_trig), data_f(locs_trig, 17), 'ro', 'MarkerFaceColor', 'r'); % Picchi rossi
ylabel('Trigger [mV]');
title('Canale 17 - Picchi identificati');
grid on;

% Subplot 2: Canale 7 (EMG Rectus Femoralis)
ax2 = subplot(2,1,2);
plot(t_array, data_f(:,6), 'b'); % Blu
hold on;
% USIAMO GLI STESSI IDENTICI INDICI (locs_trig)
plot(t_array(locs_trig), data_f(locs_trig, 6), 'ro', 'MarkerFaceColor', 'r');
ylabel('EMG - Canale 7 [mV]');
xlabel('Tempo [s]');
title('Canale 7 - Punti di sincronizzazione');
grid on;

% Collega gli assi per lo zoom
linkaxes([ax1, ax2], 'x');


%% 7 - Time normalization of all pedaling cycles

AngBase=linspace(0,359,360);

for n=1:17 %number of EMG channels
    EMG_mat{n}.values=zeros(360,size(locs_trig,1)-1);
    EMG_matOK{n}.values=zeros(360,30);
    EMG_matOK_norm{n}.values=zeros(360,30);
end
locs_emg=locs_trig;

for i = 1: size(locs_trig)-1
    
    t_orig = linspace(locs_emg(i)+1,locs_emg(i+1),locs_emg(i+1)-locs_emg(i));
    t_N = linspace(locs_emg(i)+1,locs_emg(i+1),360);
    
    for n=1:12
        EMG_mat{n}.values(:,i) = interp1(t_orig,data_f(locs_emg(i)+1:locs_emg(i+1),n), t_N, 'spline');
    end
    
end

c = [0 0.4470 0.7410];




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
    plot(AngBase,EMG_mat{i}.values,'Color',c), ylabel('EMG - GlMax'), xlim([0  360]), xlabel('Crank angle [°]');

    title(channels{i}, 'Interpreter', 'none');
end

%% 8 - Identification of the first 30 pedaling cycles at target cadence +/- 4RPM
locs_angle=locs_trig;
time_CYCLE=t(locs_angle);
mean_cadence=60./diff(time_CYCLE); %mean cadence in RPM

target_cadence=35;
good_cycle=find(and(mean_cadence<=target_cadence+4, mean_cadence>=target_cadence-4),30);


figure
plot(time_CYCLE(1:end-1),mean_cadence,'--*'), xlabel ('#cycles'),ylabel('cadence [rpm]')
hold on
plot(time_CYCLE(good_cycle),mean_cadence(good_cycle),'--r*'), xlabel ('#cycles'),ylabel('cadence [rpm]')


%% 9 - Amplitude normalization to median peak & 10 - Calculation of mean activation profile 

EMG_mean=zeros(9,360);

figure(30)
for n=1:17
   
EMG_matOK{n}.values(:, 1:length(good_cycle)) = EMG_mat{n}.values(:, good_cycle);
    
    norm_value(n)=median(max(EMG_matOK{n}.values));
    EMG_matOK_norm{n}.values(:,:)=EMG_matOK{n}.values(:,:)./norm_value(n);
    
    EMG_mean(n,:)= mean(EMG_matOK_norm{n}.values');
    EMG_std(n,:)= std(EMG_matOK_norm{n}.values');
    
    
    if (n<10)
        subplot(5,2,n)
        hold on
        plot(AngBase,EMG_matOK{n}.values,'r')
    end
end

figure
sgtitle('Right leg','FontSize',14, 'FontWeight','b')
for n=1:9
    subplot(5,2,n);
    plot(AngBase,EMG_matOK_norm{n}.values,'Color',c),  xlim([0  360]), xlabel('Crank angle [°]');
    hold on
    plot(AngBase,EMG_mean(n,:),'Color','k','LineWidth',2)
    plot(AngBase,EMG_mean(n,:)-EMG_std(n,:),'--k','LineWidth',2)
    plot(AngBase,EMG_mean(n,:)+EMG_std(n,:),'--k','LineWidth',2)
    
    switch n
        case 1
            ylabel('EMG norm - GlMax')
        case 2
            ylabel('EMG norm - BFlong')
        case 3
            ylabel('EMG norm - BFshort')
        case 4
            ylabel('EMG norm - GL')
        case 5
            ylabel('EMG norm - So')
        case 6
            ylabel('EMG norm - TFL')
        case 7
            ylabel('EMG norm - RF')
        case 8
            ylabel('EMG - VL')
        case 9
            ylabel('EMG - TA')
    end
end



%%



% --- ESTRATTO DAL PUNTO A ---
n_cicli = length(locs_trig) - 1;
muscolo_id = 5; % Esempio: Rectus Femoralis
matrice_cicli = zeros(n_cicli, 360);

for i = 1:n_cicli
    % Estrai il segmento
    segmento = data_f(locs_trig(i):locs_trig(i+1), muscolo_id);
    
    % Normalizzazione temporale a 360 punti (Interpolazione)
    x_orig = 1:length(segmento);
    x_new = linspace(1, length(segmento), 360);
    matrice_cicli(i, :) = interp1(x_orig, segmento, x_new);
end

% Calcolo Media e Deviazione Standard
emg_medio = mean(matrice_cicli, 1);
emg_std = std(matrice_cicli, 0, 1);

% Plot
figure;
fill([0:359, 359:-1:0], [emg_medio+emg_std, fliplr(emg_medio-emg_std)], 'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
hold on; plot(0:359, emg_medio, 'b', 'LineWidth', 2);
title(['Profilo Medio Muscolo ', num2str(muscolo_id)]);
xlabel('Ciclo di Pedalata [gradi]'); ylabel('Ampiezza [mV]');



%%

%% --- PLOT DINAMICA MUSCOLARE TRIKE (SINGOLO CICLO) ---

% 1. Parametri e controllo (usiamo i locs_trig del Trike)
n_ciclo = 5; % Scegliamo un ciclo a metà prova (es. il quinto)
if length(locs_trig) < n_ciclo + 1
    error('Cicli insufficienti. Controlla il rilevamento dei trigger del Trike.');
end

% 2. Definizione indici
idx_inizio_t = locs_trig(n_ciclo);
idx_fine_t = locs_trig(n_ciclo + 1);

% 3. Creazione Figura
figure('Name', 'Analisi Muscolare Ciclo Trike', ...
       'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);

for i = 1:16
    subplot(4, 4, i);
    
    % Estrazione segnale (dal file filtrato del trike)
    segmento_raw = data_f(idx_inizio_t:idx_fine_t, i); 
    
    % Creiamo l'asse X in gradi (0-360) per questo segmento
    gradi_ciclo = linspace(0, 360, length(segmento_raw));
    
    % Calcolo inviluppo per evidenziare il timing
    segmento_env = envelope(abs(segmento_raw), 150, 'peak'); 
    
    % Plot
    plot(gradi_ciclo, segmento_raw, 'Color', [0.7 0.7 0.7]); % Grigio
    hold on;
    plot(gradi_ciclo, segmento_env, 'b', 'LineWidth', 1.5);    % Blu per il Trike
    
    % Titolo canali
    title(channels{i}, 'FontSize', 10);
    
    % Estetica specifica per il Trike
    grid on;
    xlim([0 360]);
    xticks([0 90 180 270 360]);
    axis tight;
    
    if mod(i, 4) ~= 1, yticks([]); end 
    if i < 13, xticks([]); end
end

sgtitle(['Analisi Pedalata FES-Trike - Ciclo n. ' num2str(n_ciclo) ' (0-360°)']);



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