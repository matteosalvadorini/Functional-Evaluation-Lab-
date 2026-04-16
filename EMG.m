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
% Assume 'data' is the matrix after resampling (Channels 1-16: EMG, Channel 17: Trigger)
% Trigger Signal: Pulse (0-3000 mV) at 360° -> 0° transition (TDC)
% --- CYCLE SEGMENTATION LOGIC (TRIGGER CHANNEL 17) ---
% Channel 17 records an analog trigger signal (0 to 3000 mV).
% A pulse is generated each time the crank passes the 360° to 0° transition.
% These peaks represent the "Zero Point" (Top Dead Center) of each pedaling cycle
% and are used to segment the continuous EMG data into individual revolutions.


fs = 2222.22;
trigger_chan = data_array(:, 17); 

% 1.  findpeaks
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

%% 4 - Power spectral density estimate & extraction of spectral parameters


[P_EMG,F] = periodogram(data_array, rectwin(max(size(data_array))),512,fs); 

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
       Mean_freq(n,1)=meanfreq( data_array(:,n) , fs );
       Mean_freq(n,2) = meanfreq( P_EMG(:,n) , F ); 

       Med_freq(n,1) = medfreq( data_array(:,n) , fs );
       Med_freq(n,2) = medfreq( P_EMG(:,n) , F ); 
end


%% 6 - Identification of the pedaling cycles
% Find the end of each pedaling cycling based on the CrankAngle
[pks_angle,locs_angle] = findpeaks(trigger_chan, 'MinPeakHeight', 0.2, 'MinPeakDistance', fs*1);


figure()
ax1=subplot(211);
plot(CrankAngle_time,CrankAngle), ylabel('Crank Angle'), xlabel('Time [s]'),title('Peaks Angle');
hold on, plot(CrankAngle_time(locs_angle),CrankAngle(locs_angle),'o')

% Locate the same peaks on the EMG data

locs_emg=zeros(size(locs_angle));

for j=1:length(locs_angle)
    [m,locs_emg(j)]=min(abs(t-CrankAngle_time(locs_angle(j))));
end

ax2=subplot(212);
plot(t,data_f(:,7)), ylabel('EMG-RF'), xlabel('Time [s]'),title('Cycles identification on EMG signals');
hold on, plot(t(locs_emg),data_f(locs_emg,7),'o')

linkaxes([ax1, ax2],'x')


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
    EMG_matOK{n}.values(:,1:30)=data_f{n}.values(:,good_cycle);
    
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
