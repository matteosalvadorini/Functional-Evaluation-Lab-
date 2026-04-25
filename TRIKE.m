%% --POWER AND SIMMETRY--

% 1. Estrazione dei dati dalla struttura 'data'
pL = datatrike.powerLeft;   % Potenza gamba sinistra (Watt)
pR = datatrike.powerRight;  % Potenza gamba destra (Watt)

% 2. Calcolo della potenza media totale della sessione
meanPowerLeft = mean(pL);
meanPowerRight = mean(pR);

% 3. Calcolo di un indice di simmetria (Symmetry Index - SI)
% Un valore vicino a 0 indica perfetta simmetria.
% Un valore positivo o negativo indica la dominanza di una gamba.
symmetryIndex = ((meanPowerRight - meanPowerLeft) / (meanPowerRight + meanPowerLeft)) * 100;

% 4. Visualizzazione risultati
fprintf('Potenza Media Sinistra: %.2f W\n', meanPowerLeft);
fprintf('Potenza Media Destra: %.2f W\n', meanPowerRight);
fprintf('Indice di Simmetria: %.2f%%\n', symmetryIndex);

% 5. Plot per vedere l'andamento durante la prova
figure;
plot(pL, 'LineWidth', 1.5); hold on;
plot(pR, 'LineWidth', 1.5);
title('Potenza prodotta durante il test');
xlabel('Cicli di pedalata');
ylabel('Potenza (W)');
legend('Gamba Sinistra', 'Gamba Destra');
grid on;


%% -- Identification of the first 30 pedaling cycles at target cadence +/- 4RPM

% Parametri noti
fs_trike = 100; % Frequenza campionamento Trike 

% Estrazione segnali dallo screenshot
angle_signal = datatrike.angle;

% Creazione vettore tempo (stessa lunghezza dei dati)
t_trike = (0:length(angle_signal)-1) / fs_trike;

% 2. Identificazione dei cicli (punto in cui l'angolo torna a 0)
% Il segnale va da 0 a 360, quindi diff(angle) sarà molto negativo al reset
locs_angle = find(diff(angle_signal) < -300); 

% 3. Calcolo cadenza reale dai cicli
time_CYCLE = t_trike(locs_angle); % Tempi di inizio di ogni giro
mean_cadence = 60 ./ diff(time_CYCLE); % RPM calcolati

% 4. Selezione dei 30 cicli stabili a target +/- 4 RPM
target_cadence = 35; % o 50, a seconda della cartella
good_cycle_idx = find(mean_cadence >= (target_cadence - 4) & ...
                      mean_cadence <= (target_cadence + 4), 35);

%% 1. Grafico della Cadenza e Selezione Cicli
figure('Name', 'Analisi Cadenza', 'Color', 'w');
subplot(2,1,1);
plot(time_CYCLE(1:end-1), mean_cadence, '--*k', 'DisplayName', 'Cadenza calcolata'); 
hold on;
% Evidenziamo in rosso i 30 cicli che hai scelto come "buoni"
plot(time_CYCLE(good_cycle_idx), mean_cadence(good_cycle_idx), 'ro', 'MarkerSize', 8, 'LineWidth', 2, 'DisplayName', 'Cicli selezionati');

yline(target_cadence + 4, 'r--'); % Limite superiore
yline(target_cadence - 4, 'r--'); % Limite inferiore

title(['Validazione Cadenza (Target: ', num2str(target_cadence), ' RPM)']);
xlabel('Tempo [s]');
ylabel('Cadenza [RPM]');
legend('Location', 'best');
grid on;

% 2. Grafico della Potenza nei cicli selezionati
% Estraiamo i valori di potenza solo per i 30 cicli buoni
pL_good = pL(locs_angle(good_cycle_idx));
pR_good = pR(locs_angle(good_cycle_idx));

subplot(2,1,2);
bar([pL_good, pR_good]); % Grafico a barre per confrontare le gambe ciclo per ciclo
title('Confronto Potenza Gamba Sinistra vs Destra (30 cicli)');
xlabel('Numero Ciclo Selezionato');
ylabel('Potenza Media [W]');
legend('Sinistra (L)', 'Destra (R)');
grid on;

% Stampiamo l'indice di simmetria finale per questi 30 cicli
SI = ((mean(pR_good) - mean(pL_good)) / (mean(pR_good) + mean(pL_good))) * 100;
fprintf('L''Indice di Simmetria per i 30 cicli selezionati è: %.2f%%\n', SI);

%% 1. Calcolo Distanza Totale della Sessione
% Estraiamo i dati
dist_vector = datatrike.totalDistance;

% Calcolo della distanza netta percorsa 
distanza_percorsa = dist_vector(end) - dist_vector(1);

% Stampa del risultato in console
fprintf('Distanza totale percorsa nella sessione: %.2f metri\n', distanza_percorsa);

% 2. Plot dell'andamento della Distanza
figure('Name', 'Analisi Distanza', 'Color', 'w');

% Plot della distanza accumulata nel tempo
plot(t_trike, dist_vector, 'Color', [0 0.5 0], 'LineWidth', 2); 
hold on;

% Evidenziamo il punto finale
plot(t_trike(end), dist_vector(end), 'ro', 'MarkerFaceColor', 'r');

% Aggiungiamo una freccia o una linea che indica la differenza calcolata
line([t_trike(end) t_trike(end)], [dist_vector(1) dist_vector(end)], ...
    'Color', 'k', 'LineStyle', '--', 'LineWidth', 1);

title('Distanza Accumulata durante la sessione');
xlabel('Tempo [s]');
ylabel('Distanza [m]');
text(t_trike(end)*0.6, dist_vector(end)*0.5, ...
    ['Dist. Netta: ', num2str(round(distanza_percorsa,2)), ' m'], 'FontSize', 12, 'FontWeight', 'bold');

grid on;








