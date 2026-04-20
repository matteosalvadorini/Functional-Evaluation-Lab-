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



%convert struct to array: easier to work on
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








%% --- CRANK ANGLE CALCULATION & SEGMENTATION ---
%% --- RESET E SINCRONIZZAZIONE TOTALE ---

% 1. Definiamo la lunghezza basandoci sull'EMG filtrato (quello che vuoi analizzare)
N = size(data_f, 1); 
fs_new = 2000; % La frequenza che hai scelto

% 2. FORZIAMO il trigger ad avere la stessa lunghezza dell'EMG
% Prendi il canale 17 dal data_array originale ma taglialo a N
trigger_sync = data_array(1:N, 17); 

% 3. Trova i picchi DIRETTAMENTE su questo trigger tagliato
[~, stops] = findpeaks(trigger_sync, 'MinPeakHeight', 0.2, 'MinPeakDistance', fs_new*0.8);

% 4. Ricostruisci il CrankAngle partendo dai picchi APPENA TROVATI
CrankAngle = nan(N, 1);
for i = 1:length(stops)-1
    start_idx = stops(i);
    end_idx = stops(i+1);
    n_points = end_idx - start_idx;
    
    % L'angolo DEVE partire da 0 esattamente dove c'è il picco stops(i)
    CrankAngle(start_idx:end_idx-1) = linspace(0, 360, n_points);
end

% 5. Crea l'asse del tempo UNICO per entrambi
t_unico = (0:N-1)' / fs_new;




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
% I picchi trovati sul trigger (stops o locs_angle) sono gli indici dei campioni
[pks_angle, locs_angle] = findpeaks(trigger_chan, 'MinPeakHeight', 0.2, 'MinPeakDistance', fs_channels*1);

% Poiché abbiamo resampato tutto a 2000Hz, l'indice sul trigger è uguale all'indice sull'EMG
locs_emg = locs_angle; 

figure('Name', 'Check Sincronizzazione Cicli');
ax1 = subplot(211);
plot(t, CrankAngle), ylabel('Crank Angle [°]'), xlabel('Time [s]'), title('Angolo Pedivella');
hold on;
plot(t(locs_angle), CrankAngle(locs_angle), 'ro', 'MarkerFaceColor', 'r');

ax2 = subplot(212);
% Usiamo t (che deve essere lungo quanto data_f) per l'asse X
plot(t, data_f(:,7)), ylabel('EMG - Rectus Femoralis'), xlabel('Time [s]'), title('Identificazione Cicli su EMG');
hold on;
plot(t(locs_emg), data_f(locs_emg, 7), 'ro', 'MarkerFaceColor', 'r');

linkaxes([ax1, ax2], 'x');
grid on;



%% 


figure('Name', 'Check Sincronizzazione Cicli');
ax1 = subplot(211);
plot(t, CrankAngle), ylabel('Crank Angle [°]'), xlabel('Time [s]'), title('Angolo Pedivella');
hold on;
plot(t(locs_angle), CrankAngle(locs_angle), 'ro', 'MarkerFaceColor', 'r');

ax2 = subplot(212);
% Usiamo t (che deve essere lungo quanto data_f) per l'asse X
plot(t, data_f(:,1)), ylabel('EMG - Rectus Femoralis'), xlabel('Time [s]'), title('Identificazione Cicli su EMG');
hold on;
plot(t(locs_emg), data_f(locs_emg, 7), 'ro', 'MarkerFaceColor', 'r');

linkaxes([ax1, ax2], 'x');
grid on;

%% 7 - Time normalization of all pedaling cycles

AngBase=linspace(0,359,360);

for n=1:17 %number of EMG channels
    EMG_mat{n}.values=zeros(360,size(locs_emg,1)-1);
    EMG_matOK{n}.values=zeros(360,30);
    EMG_matOK_norm{n}.values=zeros(360,30);
end


for i = 1: size(locs_emg)-1
    
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

time_CYCLE=CrankAngle_time(locs_angle);
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
