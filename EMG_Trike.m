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

channels = {'Trigger','Tibialis Ant R', 'Gastro Lat R', 'Soleus R', 'Gastro Med R', ...
           'Rectus R', 'Vastus Lat R', 'Vastus Med R', 'Semitendinous R', ...
           'Tibialis Ant L', 'Gastro Lat L', 'Soleus L', 'Gastro Med L', ...
           'Rectus L', 'Vastus Lat L', 'Vastus Med L', 'Semitendinous L'};



%convert struct to array: easier to work on...
data_array = struct2array(data_resampled);



%% PLOT RAW DATA



%calculate time for one channel, will be the same length for the others
n_sample = size(data_array, 1);
t = (0:n_sample-1) / target;
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
Wn = W/(target/2); %normalized frequency
[b,a ]= butter(5,Wn,"bandpass");



%cancel NaN values: every NaN values = 0 with:
data_isnan=fillmissing(data_array, 'constant', 0);
%filter for every channel
data_f= filtfilt(b,a,data_isnan);



%calculate AGAIN (gives problem with dimension) time for one channel, will be the same length for the others
n_sample = size(data_f, 1);
t_f = (0:n_sample-1) / target;
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


[P_EMG,F] = periodogram(data_f, rectwin(max(size(data_f))),512,fs_channels); 

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
for n=2:17
       Mean_freq(n,1)=meanfreq( data_f(:,n) , fs_channels );
       Mean_freq(n,2) = meanfreq( P_EMG(:,n) , F ); 

       Med_freq(n,1) = medfreq( data_f(:,n) , fs_channels );
       Med_freq(n,2) = medfreq( P_EMG(:,n) , F ); 
end



%% 6 - Identification of the pedaling cycles


% 1. Trova gli indici dei picchi nel canale trigger (Colonna 17)
% Usiamo la frequenza originale (es. 2222.22) se non hai ancora resampato
[pks_trig, locs_trig] = findpeaks(data_array(:,1), 'MinPeakHeight', 0.5, 'MinPeakDistance', fs_channels*0.8);

% 2. Crea l'asse del tempo basato sulla lunghezza di data_array
t_array = (0:size(data_array, 1)-1)' / target;

% 3. Grafico di confronto
figure('Name', 'Sincronizzazione Trigger e Canale 7');

% Subplot 1: Canale Trigger (1)
ax1 = subplot(2,1,1);
plot(t_array, data_array(:,1), 'Color', [0.4 0.4 0.4]); % Grigio
hold on;
plot(t_array(locs_trig), data_array(locs_trig, 1), 'ro', 'MarkerFaceColor', 'r'); % Picchi rossi
ylabel('Trigger [mV]');
title('Canale 17 - Picchi identificati');
grid on;

% Subplot 2: Canale 7 (EMG Rectus Femoralis)
ax2 = subplot(2,1,2);
plot(t_array, data_f(:,8), 'b'); % Blu
hold on;
% USIAMO GLI STESSI IDENTICI INDICI (locs_trig)
plot(t_array(locs_trig), data_f(locs_trig, 8), 'ro', 'MarkerFaceColor', 'r');
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



%% 8 - Identification good cycles at target cadence +/- 4RPM
locs_angle=locs_trig;
time_CYCLE=t(locs_angle);
mean_cadence=60./diff(time_CYCLE); %mean cadence in RPM

target_cadence=35;
good_cycle=find(and(mean_cadence<=target_cadence+4, mean_cadence>=target_cadence-4));


figure
plot(time_CYCLE(1:end-1),mean_cadence,'--*'), xlabel ('#cycles'),ylabel('cadence [rpm]')
hold on
plot(time_CYCLE(good_cycle),mean_cadence(good_cycle),'--r*'), xlabel ('#cycles'),ylabel('cadence [rpm]')


%% 9 - Amplitude normalization to median peak & 10 - Calculation of mean activation profile 

EMG_mean=zeros(9,360);

for n=1:17
   
EMG_matOK{n}.values(:, 1:length(good_cycle)) = EMG_mat{n}.values(:, good_cycle);
    
    norm_value(n)=median(max(EMG_matOK{n}.values));
    EMG_matOK_norm{n}.values(:,:)=EMG_matOK{n}.values(:,:)./norm_value(n);
    
    EMG_mean(n,:)= mean(EMG_matOK_norm{n}.values');
    EMG_std(n,:)= std(EMG_matOK_norm{n}.values');
    
    
   
end




% Parametri iniziali
page = 6; 
c_cycles = [0.7 0.7 0.7]; % Grigio chiaro per i singoli cicli
c_mean = [0 0.4470 0.7410]; % Blu per la media
AngBase = linspace(0, 359, 360);

% Inizializzazione matrici per i risultati
EMG_mean = zeros(17, 360);
EMG_std = zeros(17, 360);

for i = 1:17
% 9 - NORMALIZZAZIONE E CALCOLO PROFILI
    % Seleziona solo i cicli buoni (già estratti in precedenza in EMG_mat)
    EMG_matOK{i}.values = EMG_mat{i}.values(:, good_cycle);
    
    % Normalizzazione all'ampiezza mediana dei picchi
    norm_value(i) = median(max(EMG_matOK{i}.values));
    if norm_value(i) == 0, norm_value(i) = 1; end % Evita divisione per zero
    
    EMG_matOK_norm{i}.values = EMG_matOK{i}.values ./ norm_value(i);
    
    % Calcolo Media e Deviazione Standard (lungo i cicli, quindi riga per riga)
    EMG_mean(i, :) = mean(EMG_matOK_norm{i}.values, 2)';
    EMG_std(i, :) = std(EMG_matOK_norm{i}.values, 0, 2)';

   % 10 - LOGICA DI PLOTTING A PAGINE
    % Crea una nuova figura ogni 'page' canali (6)
    if mod(i-1, page) == 0
        figure('Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
        ti = tiledlayout(3, 2, 'TileSpacing', 'compact'); 
        on_page = ceil(i / page);
        title(ti, ['EMG Normalized Profiles - Page ', num2str(on_page)], 'FontSize', 14);
    end
   

    nexttile;
    hold on;
    
    % 1. Plotta i 30 cicli normalizzati in grigio (sullo sfondo)
    plot(AngBase, EMG_matOK_norm{i}.values, 'Color', c_cycles, 'LineWidth', 0.5);
    
    % 2. Plotta la Media (linea blu spessa)
    plot(AngBase, EMG_mean(i,:), 'Color', c_mean, 'LineWidth', 2);
    
    % 3. Plotta la Deviazione Standard (linee tratteggiate)
    plot(AngBase, EMG_mean(i,:) + EMG_std(i,:), '--', 'Color', c_mean, 'LineWidth', 1);
    plot(AngBase, EMG_mean(i,:) - EMG_std(i,:), '--', 'Color', c_mean, 'LineWidth', 1);
    
    % Formattazione grafico
    title(channels{i}, 'Interpreter', 'none');
    xlim([0 360]);
    xticks([0 90 180 270 360]);
    grid on;
    
    if mod(i-1, 2) == 0 % Solo sulla colonna di sinistra metti la label Y
        ylabel('Norm. Amplitude');
    end
    if i > (on_page-1)*page + 4 % Solo sulle ultime tile della pagina metti la label X
        xlabel('Crank angle [°]');
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

for i = 2:17
    subplot(4, 4, i-1);
    
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
trig_attuali = locs_trig; 
n_cicli = length(trig_attuali) - 1;

% Inizializza correttamente per 16 canali
aree_cicli = zeros(n_cicli, 16);

for c = 1:n_cicli
    idx_in = trig_attuali(c);
    idx_fi = trig_attuali(c+1);
    
    col_idx = 1; % Indice per la colonna della matrice aree_cicli
    for ch = 2:17
        seg_rect = abs(data_f(idx_in:idx_fi, ch));
        
        % Riempire dalla colonna 1 alla 16
        aree_cicli(c, col_idx) = trapz(seg_rect) / length(seg_rect);
        col_idx = col_idx + 1;
    end
end

% Calcolo della media (risultato: vettore 1x16)
area_finale = mean(aree_cicli, 1);

% Creazione Tabella (entrambi devono essere vettori colonna 16x1)
tabella_risultati = table(channels(2:17)', area_finale', ...
    'VariableNames', {'Muscolo', 'Area_Media_iEMG'});

disp('--- RISULTATI AREA MEDIA PER MUSCOLO ---');
disp(tabella_risultati);

%%

% --- CALCOLO SIMMETRIA MUSCOLARE ---




%% Amplitude normalization through median peak activation across valid cycles
% For each muscle, the peak envelope value is extracted from each valid cycle. 
% The median of these peak values is then used as a normalization factor, 
% and each cycle is divided by the corresponding muscle-specific median 
% peak value.

n_valid = min(30, length(good_cycles));

norm_value = zeros(1,16);

for m = 1:16
    peaks = zeros(n_valid,1);
    
    for i = 1:n_valid
        peaks(i) = max(EMG_cycles_norm{good_cycles(i)}(:,m));
    end
    
    norm_value(m) = median(peaks);
end

EMG_cycles_norm_amp = cell(n_valid,1);

for i = 1:n_valid
    EMG_cycles_norm_amp{i} = zeros(360,16);
    for m = 1:16
        EMG_cycles_norm_amp{i}(:,m) = EMG_cycles_norm{good_cycles(i)}(:,m) / norm_value(m);
    end
end


% Total activation level for each muscle
% For each normalized cycle and each muscle, the area under the curve (AUC)
% of the EMG envelope is computed. This represents the total activation 
% level of that muscle over the full pedaling cycle.

n_cicli = length(EMG_cycles_norm_amp);
n_muscoli = 16;

AUC = zeros(n_cicli, n_muscoli);
ang = linspace(0,360,360);

for i = 1:n_cicli
    for m = 1:n_muscoli
        AUC(i,m) = trapz(ang, EMG_cycles_norm_amp{i}(:,m));
    end
end

% Simmetry index computation for each muscle
% For each pair of homologous right–left muscles, a symmetry index (SI) is 
% calculated using the AUC values. This provides a quantitative estimate of
% how balanced the activation is between the two sides.

SI = zeros(n_cicli,8);

for k = 1:8
    R = AUC(:,k);
    L = AUC(:,k+8);

    SI(:,k) = ((R - L) ./ (0.5*(R + L))) * 100;
end

SI_abs = abs(SI);
SI_mean = mean(SI,1);
SI_abs_mean = mean(SI_abs,1);

% Results
% The mean SI and mean absolute SI are calculated across cycles for each 
% muscle pair and displayed in a summary table, providing an overview of 
% inter-limb symmetry during pedaling.

muscle_names = {'TA','GastroLat','Soleus','GastroMed','Rectus','VastusLat','VastusMed','Semitend'};
disp(table(muscle_names', SI_mean', SI_abs_mean', ...
    'VariableNames', {'Muscle','SI_mean','SI_abs_mean'}))

area_R = mean(area_finale(1:8));  % Media aree gamba destra
area_L = mean(area_finale(9:16)); % Media aree gamba sinistra

% Indice di Simmetria (Symmetry Index)
% Se > 100, la destra lavora più della sinistra
% Se < 100, la sinistra lavora più della destra
SI_muscolare = (area_R / area_L) * 100;

fprintf('\n--- SIMMETRIA ---\n');
fprintf('Area Media Destra (R): %.4f\n', area_R);
fprintf('Area Media Sinistra (L): %.4f\n', area_L);
fprintf('Indice di Simmetria Muscolare: %.2f%%\n', SI_muscolare);