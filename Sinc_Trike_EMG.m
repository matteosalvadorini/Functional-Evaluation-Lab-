%Before run this code you must import TRIKE ad EMG for the TRIKE and run
%the codes EMG_TRIKE and TRIKE

% Trova il primo reset dell'angolo nel Trike
idx_trike_start = find(diff(datatrike.angle) < -300, 1) + 1;
time_trike_start = t_trike(idx_trike_start); % Tempo zero per la bici


% Supponendo che 'emg_data' sia la tua matrice EMG importata
% Il Canale 17 è il trigger 
trigger_signal = data(:, 17);



n_sample = size(trigger_signal);
t_emg = (0:n_sample-1) / 2222.22;
t_emg=t_emg';



% Trasforma la tabella in una matrice di soli numeri
emg_matrix = table2array(data); 

% Ora selezioni il Canale 17 (il trigger)
trigger_signal = emg_matrix(:, 17);

% Adesso la funzione 'find' funzionerà correttamente
idx_emg_start = find(trigger_signal > 1500, 1);



% Se hai il vettore tempo dell'EMG (t_emg):
time_emg_start = t_emg(idx_emg_start); % Tempo zero per l'EMG


% Tagliamo i dati del Trike dall'inizio della prima pedalata in poi
trike_synced = datatrike.angle(idx_trike_start:end);

% Tagliamo i dati EMG dal primo trigger in poi
emg_synced = data(idx_emg_start:end, :);




%% 1. Preparazione dei dati sincronizzati
% Frequenze di campionamento (controlla i valori esatti nel tuo dataset)
fs_trike = 100;
fs_emg = 2148.1481; % Valore tipico indicato nelle tue istruzioni

% Creiamo i vettori tempo partendo da 0 (il momento del primo trigger)
t_trike_sync = (0:length(datatrike.angle(idx_trike_start:end))-1) / fs_trike;
t_emg_sync = (0:length(trigger_signal(idx_emg_start:end))-1) / fs_emg;

%% 2. Plot di Verifica
figure('Name', 'Verifica Sincronizzazione Trike-EMG', 'Color', 'w');

% Plot Angolo Trike (normalizzato tra 0 e 1 per sovrapporlo)
subplot(2,1,1);
plot(t_trike_sync, datatrike.angle(idx_trike_start:end)/360, 'LineWidth', 1.5);
hold on;
% Plot Trigger EMG (normalizzato tra 0 e 1)
% Dividiamo per 3000 perché il trigger è solitamente 0-3000mV
plot(t_emg_sync, trigger_signal(idx_emg_start:end)/max(trigger_signal), 'r', 'LineWidth', 1);

title('Verifica Allineamento: Angolo (Blu) vs Trigger (Rosso)');
xlabel('Tempo [s]');
ylabel('Ampiezza Normalizzata');
legend('Angolo Pedale (0-360°)', 'Trigger EMG');
xlim([0 10]); % Guardiamo i primi 10 secondi per precisione
grid on;

% Subplot di zoom su un singolo ciclo
subplot(2,1,2);
plot(t_trike_sync, datatrike.angle(idx_trike_start:end)/360, 'LineWidth', 1.5);
hold on;
plot(t_emg_sync, trigger_signal(idx_emg_start:end)/max(trigger_signal), 'r', 'LineWidth', 1);
title('Zoom: Il picco rosso deve coincidere con l''inizio della rampa blu');
xlabel('Tempo [s]');
xlim([2 4]); % Zoom su un paio di pedalate
grid on;