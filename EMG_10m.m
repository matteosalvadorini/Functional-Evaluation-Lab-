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





%% --- ANALISI COMPLETA GAIT (SENZA TRIGGER FISICO-sfruttando tibiale anteriore) ---

% 1. CREAZIONE TRIGGER VIRTUALE (Basato su Tibialis Ant R - Canale 1)
% Usiamo il Tibiale perché ha burst molto chiari all'inizio del passo
ta_ref = abs(data_f(:, 1)); 
[b_trig, a_trig] = butter(4, 3/(fs_channels/2), 'low'); % Filtro molto dolce
ta_smooth = filtfilt(b_trig, a_trig, ta_ref);

% Trova i picchi (Heel Strikes stimati)
% Regola 'MinPeakHeight' se non trova nulla (es. 0.01 o 0.05)
[~, virtual_heel_strikes] = findpeaks(ta_smooth, 'MinPeakHeight', 0.004, 'MinPeakDistance', fs_channels*0.5);

fprintf('Passi individuati tramite Tibiale: %d\n', length(virtual_heel_strikes));

% 2. CALCOLO AREA MEDIA (iEMG) SU TUTTI I PASSI
n_passi = length(virtual_heel_strikes) - 1;
aree_passi = zeros(n_passi, 16);

for p = 1:n_passi
    idx_in = virtual_heel_strikes(p);
    idx_fi = virtual_heel_strikes(p+1);
    
    for ch = 1:16
        seg_rect = abs(data_f(idx_in:idx_fi, ch));
        % Area normalizzata per la durata del passo
        aree_passi(p, ch) = trapz(seg_rect) / length(seg_rect);
    end
end

area_finale_gait = mean(aree_passi, 1);

% 3. PLOT MULTI-CANALE (Visualizziamo il secondo passo individuato)
n_p = 2; 
idx_in_p = virtual_heel_strikes(n_p);
idx_fi_p = virtual_heel_strikes(n_p+1);
t_p = (0:(idx_fi_p - idx_in_p)) / fs_channels;

figure('Name', 'Analisi Muscolare Gait (Trigger Virtuale TA)', 'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);

for i = 1:16
    subplot(4, 4, i);
    segmento_raw = data_f(idx_in_p:idx_fi_p, i);
    segmento_env = envelope(abs(segmento_raw), 150, 'peak');
    
    plot(t_p, segmento_raw, 'Color', [0.7 0.7 0.7]); hold on;
    plot(t_p, segmento_env, 'r', 'LineWidth', 1.2);
    
    title(channels{i}); grid on; axis tight;
    if mod(i, 4) ~= 1, yticks([]); end
    if i < 13, xticks([]); end
end
sgtitle(['Gait Cycle - Passo ' num2str(n_p) ' (Distanza tra picchi TA)']);

% 4. VISUALIZZAZIONE TABELLA RISULTATI
tabella_gait = table(channels(1:16)', area_finale_gait', ...
    'VariableNames', {'Muscolo', 'Area_Media_iEMG'});

disp('--- TABELLA AREE MEDIE (GAIT) ---');
disp(tabella_gait);