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





%% PLOT RAW DATA

%convert struct to array: easier to plot
data_array = struct2array(data_resampled);

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
        t = tiledlayout(3, 2, 'TileSpacing', 'compact'); % Grid 3x2 per page
        on_page = ceil(i / page);
        title(t, ['EMG raw data - Page ', num2str(on_page)]);
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
        t = tiledlayout(3, 2, 'TileSpacing', 'compact'); % Griglia 3x2 per pagina
        on_page = ceil(i / page);
        title(t, ['EMG_filtered - Page ', num2str(on_page)]);
    end


    nexttile;
    plot(data_f(:,i));
    title(channels{i}, 'Interpreter', 'none');
end








%% --- CRANK ANGLE CALCULATION & SEGMENTATION ---
% Assume 'data' is the matrix after resampling (Channels 1-16: EMG, Channel 17: Trigger)
% Trigger Signal: Pulse (0-3000 mV) at 360° -> 0° transition (TDC)
% --- CYCLE SEGMENTATION LOGIC (TRIGGER CHANNEL 17) ---
% Channel 17 records an analog trigger signal (0 to 3000 mV).
% A pulse is generated each time the crank passes the 360° to 0° transition.
% These peaks represent the "Zero Point" (Top Dead Center) of each pedaling cycle
% and are used to segment the continuous EMG data into individual revolutions.


fs = 2222.22;
trigger_chan = data_array(:, 17); 

% 1. Trova i picchi. 
% Se il segnale è rumoroso, prova ad abbassare MinPeakHeight a 1 o 1.5
[~, stops] = findpeaks(trigger_chan, 'MinPeakHeight', 0.2, 'MinPeakDistance', fs*1);

% --- CONTROLLO DI SICUREZZA ---
if isempty(stops)
    error('ATTENZIONE: Nessun picco trovato nel canale trigger! Controlla la soglia MinPeakHeight.');
end

% 2. Inizializza il vettore CrankAngle
CrankAngle = zeros(size(trigger_chan)); 

% 3. Ciclo per riempire ogni rivoluzione tra 0 e 360
for i = 1:length(stops)-1
    start_idx = stops(i);
    end_idx = stops(i+1);
    
    n_points = end_idx - start_idx;
    CrankAngle(start_idx:end_idx-1) = linspace(0, 360, n_points);
end

% 4. Gestione dei bordi (solo se stops non è vuoto)
if stops(1) > 1
    CrankAngle(1:stops(1)-1) = NaN;
end
CrankAngle(stops(end):end) = NaN;

CrankAngle_time = (0:length(trigger_chan)-1)' / fs;
%% IDENTIFICATION OF VOLUNTARY PEDALING PHASE 

[ii,ang]=ginput(2);

[m,locsxi]=min(abs(CrankAngle_time-ii(1)));
[m,locsei]=min(abs(t-ii(1)));
[m,locsxf]=min(abs(CrankAngle_time-ii(2)));
[m,locsef]=min(abs(t-ii(2)));


figure()
subplot(10,1,1), plot(CrankAngle_time,CrankAngle),ylabel('Crank angle'), xlim([min(CrankAngle_time) max(CrankAngle_time)]),title('Right Leg');
subplot(10,1,2), plot(t,data_array(:,1)), ylabel('EMG-GlMax'), xlim([min(t) max(t)]);
subplot(10,1,3), plot(t,data_array(:,2)), ylabel('EMG-BFlong'), xlim([min(t) max(t)]);
subplot(10,1,4), plot(t,data_array(:,3)), ylabel('EMG-BFshort'), xlim([min(t) max(t)]);
subplot(10,1,5), plot(t,data_array(:,4)), ylabel('EMG-GL'), xlim([min(t) max(t)]);
subplot(10,1,6), plot(t,data_array(:,5)), ylabel('EMG-So'), xlim([min(t) max(t)]);
subplot(10,1,7), plot(t,data_array(:,6)), ylabel('EMG-TFL'), xlim([min(t) max(t)]);
subplot(10,1,8), plot(t,data_array(:,7)), ylabel('EMG-RF'), xlim([min(t) max(t)]);
subplot(10,1,9), plot(t,data_array(:,8)), ylabel('EMG-VL'), xlim([min(t) max(t)]);
subplot(10,1,10), plot(t,data_array(:,9)), ylabel('EMG-TA'), xlim([min(t) max(t)]);
subplot(10,1,11), plot(t,data_array(:,10)), ylabel('EMG-TA'), xlim([min(t) max(t)]);
subplot(10,1,12), plot(t,data_array(:,11)), ylabel('EMG-TA'), xlim([min(t) max(t)]);
subplot(10,1,13), plot(t,data_array(:,12)), ylabel('EMG-TA'), xlim([min(t) max(t)]);
subplot(10,1,14), plot(t,data_array(:,13)), ylabel('EMG-TA'), xlim([min(t) max(t)]);
subplot(10,1,15), plot(t,data_array(:,14)), ylabel('EMG-TA'), xlim([min(t) max(t)]);
subplot(10,1,16), plot(t,data_array(:,15)), ylabel('EMG-TA'), xlim([min(t) max(t)]);
subplot(10,1,17), plot(t,data_array(:,16)), ylabel('EMG-TA'), xlim([min(t) max(t)]);



%% 4 - Power spectral density estimate & extraction of spectral parameters


[P_EMG,F] = periodogram(data_f, rectwin(max(size(data_f))),512,fs); 

% plot of the power spectral density estimate of the right RF
figure ()
subplot(2,1,1)
plot(F,10*log10(P_EMG(:,7)),'b')
title('Periodogram Power Spectral Density Estimate','b')
xlabel('Frequency (Hz)')
ylabel('Power/frequency (dB/Hz)')
grid on
ylim([ -120 0])
xlim([0 fs/2])

%estimates the mean frequency & median frequency
for n=1:12
       Mean_freq(n,1)=meanfreq( data_f(:,n) , fs );
       Mean_freq(n,2) = meanfreq( P_EMG(:,n) , F ); 

       Med_freq(n,1) = medfreq( data_f(:,n) , fs );
       Med_freq(n,2) = medfreq( P_EMG(:,n) , F ); 
end

