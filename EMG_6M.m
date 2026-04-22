% Nella verifica 6M ci serve valutare la resistenza a fatica quindi fatigue
% analysis

%%


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


 

data = table2array(data);

%% PLOT RAW DATA


fs_channels= 2222.22;
%calculate time for one channel, will be the same length for the others
n_sample = size(data, 1);
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
    plot(data(:,i));
    title(channels{i}, 'Interpreter', 'none');
end


%% BAND-PASS FILTERING

% Band-pass filter 5th order
% cut off frequency = [20-400] Hz 
W= [20; 400];
Wn = W/(fs_channels/2); %normalized frequency
[b,a ]= butter(5,Wn,"bandpass");



%cancel NaN values: every NaN values = 0 with:
data_isnan=fillmissing(data, 'constant', 0);
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








%% --- ANALISI FATICA 6MWT (ADATTATA) ---

% 1. Parametri iniziali
Fs_EMG = fs_channels; % Usa la tua frequenza di campionamento
[N_samples, n_channels] = size(data_f); % Assicurati che data_f sia [Campioni x 16]

% 2. Definizione segmenti (60 secondi l'uno)
Ns = 60 * Fs_EMG;                % campioni per ogni minuto
nSeg = floor(N_samples / Ns);    % numero di segmenti completi da 60s

% Inizializzazione matrice per i risultati (Righe: minuti, Colonne: muscoli)
meanISC = zeros(nSeg, 16);

% 3. Calcolo dello Spectral Centroid per ogni minuto e ogni muscolo
fprintf('Calcolo fatica in corso per %d minuti...\n', nSeg);

for i = 1:nSeg
    % Usiamo round() per assicurarci che gli indici siano interi
    start_idx = round((i-1)*Ns + 1);
    end_idx = round(i*Ns);
    
    % Controllo per non eccedere la lunghezza della matrice
    if end_idx > N_samples
        end_idx = N_samples;
    end
    
    for j = 1:16
        segmento_attuale = data_f(start_idx:end_idx, j);
        
        % Calcolo dello Spectral Centroid
        % Se non hai l'Audio Toolbox, questa riga darà errore. 
        % In quel caso la sostituiremo con medfreq.
        sc_val = spectralCentroid(segmento_attuale, Fs_EMG);
        meanISC(i,j) = mean(sc_val);
    end
end

%% 4. Plot dei risultati (Gamba Destra e Gamba Sinistra separatamente)

% Grafico Gamba DESTRA (1-8)
figure('Name', 'Trend Fatica (ISC) - Gamba Destra', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
for j = 1:8
    subplot(2, 4, j);
    plot(1:nSeg, meanISC(:, j), 'b-o', 'LineWidth', 1.5);
    title(channels{j});
    xlabel('Minuti'); ylabel('ISC [Hz]');
    grid on;
    % Imposta un range Y coerente per vedere il calo
    ylim([min(meanISC(:))*0.9, max(meanISC(:))*1.1]);
end
sgtitle('Evoluzione Centroide Spettrale (Fatica) - Gamba Destra');

% Grafico Gamba SINISTRA (9-16)
figure('Name', 'Trend Fatica (ISC) - Gamba Sinistra', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
for j = 9:16
    subplot(2, 4, j-8);
    plot(1:nSeg, meanISC(:, j), 'r-s', 'LineWidth', 1.5);
    title(channels{j});
    xlabel('Minuti'); ylabel('ISC [Hz]');
    grid on;
    ylim([min(meanISC(:))*0.9, max(meanISC(:))*1.1]);
end
sgtitle('Evoluzione Centroide Spettrale (Fatica) - Gamba Sinistra');

%% 5. Calcolo Pendenza (Slope)
% Una pendenza negativa indica che la fatica sta aumentando
fprintf('\n--- ANALISI PENDENZA FATICA (Slope) ---\n');
for j = 1:16
    p = polyfit(1:nSeg, meanISC(:,j)', 1);
    fprintf('%s: Slope = %.4f Hz/min\n', channels{j}, p(1));
end


%%
%area e simmetria nel primo minuto e nel minuto 6(ultimo) così da vedere
%variazioni


%% --- ANALISI COMPLETA 6 MINUTI WALK TEST (6MWT) ---

% 1. Parametri Iniziali
Fs_EMG = fs_channels; 
[N_samples, n_channels] = size(data_f); 

% Definiamo i segmenti (60 secondi l'uno)
Ns = 60 * Fs_EMG;                
nSeg = floor(N_samples / Ns);    

% Inizializzazione matrici (Righe: minuti, Colonne: muscoli)
meanISC = zeros(nSeg, 16);
areaMinuto = zeros(nSeg, 16);

% 2. Loop di Analisi (Fatica + Area)
fprintf('Analisi 6MWT in corso per %d minuti...\n', nSeg);

for i = 1:nSeg
    start_idx = round((i-1)*Ns + 1);
    end_idx = round(i*Ns);
    
    for j = 1:16
        segmento = data_f(start_idx:end_idx, j);
        seg_rect = abs(segmento);
        
        % A. Calcolo Fatica (Spectral Centroid o Median Frequency)
        % Se spectralCentroid non funziona, usa: meanISC(i,j) = medfreq(segmento, Fs_EMG);
        sc_val = spectralCentroid(segmento, Fs_EMG);
        meanISC(i,j) = mean(sc_val);
        
        % B. Calcolo Area Media del minuto
        areaMinuto(i,j) = trapz(seg_rect) / length(seg_rect);
    end
end

% 3. Calcolo Simmetria (Inizio vs Fine)
% Gamba R (1:8), Gamba L (9:16)
SI_inizio = (mean(areaMinuto(1, 1:8)) / mean(areaMinuto(1, 9:16))) * 100;
SI_fine   = (mean(areaMinuto(end, 1:8)) / mean(areaMinuto(end, 9:16))) * 100;

% 4. Visualizzazione Risultati in Command Window
fprintf('\n--- RISULTATI EVOLUZIONE 6MWT ---\n');
fprintf('Simmetria Minuto 1: %.2f%%\n', SI_inizio);
fprintf('Simmetria Minuto %d: %.2f%%\n', nSeg, SI_fine);

% Tabella riassuntiva della fatica (Slope)
fprintf('\n--- PENDENZA FATICA (Slope ISC) ---\n');
slopes = zeros(16,1);
for j = 1:16
    p = polyfit(1:nSeg, meanISC(:,j)', 1);
    slopes(j) = p(1);
    fprintf('%s: %.4f Hz/min\n', channels{j}, slopes(j));
end

% 5. Grafico riassuntivo AREA (Gamba Paretica vs Sana)
% Supponiamo che la paretica sia la Sinistra (L: 9-16)
figure('Name', 'Evoluzione Carico Muscolare (6MWT)');
subplot(1,2,1)
plot(1:nSeg, mean(areaMinuto(:, 1:8), 2), '-o', 'LineWidth', 2); hold on;
plot(1:nSeg, mean(areaMinuto(:, 9:16), 2), '-s', 'LineWidth', 2);
title('Area Media R vs L'); xlabel('Minuti'); ylabel('iEMG Normalizzato');
legend('Gamba Destra', 'Gamba Sinistra'); grid on;

subplot(1,2,2)
plot(1:nSeg, meanISC(:, 1:8), 'LineWidth', 0.5); % Tutte le linee sottili
hold on;
plot(1:nSeg, mean(meanISC, 2), 'k', 'LineWidth', 3); % Media totale in nero
title('Trend Fatica (ISC)'); xlabel('Minuti'); ylabel('Hz');
grid on;