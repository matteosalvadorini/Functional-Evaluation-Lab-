%% --- ANALISI CINEMATICA CAPTIKS (10m Walk) ---

% 1. Recupera la tabella dal workspace
% (Sostituisci 'cpk_anatomical_angles_...' con il nome esatto della variabile nel tuo Workspace)
data_angles = cpk_anatomical_angles_2025_07_07_14_51_17; 
Remove_first_sample_Offset  = 1;
% Frequenza di campionamento (di solito 100Hz per Captiks)
T_sample = mean(diff(data_angles.TIMESTAMPRELATIVE)); 






%% 1. Mapping Variabili Sinistra (LEFT LEG)
% Estraiamo i dati dalla tabella Captiks mappandoli sui nomi del tuo vecchio script

% Angoli calcolati direttamente dal software Captiks
left_Ankle_angle_phi_x = data_angles.ANKLEDORSIFLEXION_PLANTARFLEXIONLEFT;
left_Knee_angle_phi_x  = data_angles.KNEEFLEXION_EXTENSIONLEFT;
left_Hip_angle_phi_x   = data_angles.HIPFLEXION_EXTENSIONLEFT;

% Simuliamo i giroscopi (necessari per la FSM) calcolando la derivata degli angoli
% poichè nel tuo file CSV non hai la velocità angolare pura del sensore
left_Gyro_foot = [0; diff(left_Ankle_angle_phi_x) / T_sample];

%% 2. Mapping Variabili Destra (RIGHT LEG)
right_Ankle_angle_phi_x = data_angles.ANKLEDORSIFLEXION_PLANTARFLEXIONRIGHT;
right_Knee_angle_phi_x  = data_angles.KNEEFLEXION_EXTENSIONRIGHT;
right_Hip_angle_phi_x   = data_angles.HIPFLEXION_EXTENSIONRIGHT;

right_Gyro_foot = [0; diff(right_Ankle_angle_phi_x) / T_sample];

%% 3. Applicazione Offset Iniziale (come nel codice originale)
if Remove_first_sample_Offset
    left_Ankle_angle_phi_x = left_Ankle_angle_phi_x - left_Ankle_angle_phi_x(1);
    left_Knee_angle_phi_x  = left_Knee_angle_phi_x - left_Knee_angle_phi_x(1);
    left_Hip_angle_phi_x   = left_Hip_angle_phi_x - left_Hip_angle_phi_x(1);
    
    right_Ankle_angle_phi_x = right_Ankle_angle_phi_x - right_Ankle_angle_phi_x(1);
    right_Knee_angle_phi_x  = right_Knee_angle_phi_x - right_Knee_angle_phi_x(1);
    right_Hip_angle_phi_x   = right_Hip_angle_phi_x - right_Hip_angle_phi_x(1);
end

%%



%% FSM initialization LEFT - filter (ADAPTED FOR CAPTIKS)
omega_hp = 1.5; 
T_sample = 0.01; % Assumendo 100Hz dai dati Captiks
K_hp = 1;

% Inizializzazione dei vettori filtrati
left_G_foot_phi_x_filtered = zeros(size(left_Ankle_angle_phi_x));
left_G_shank_phi_x_filtered = zeros(size(left_Knee_angle_phi_x));
left_G_thigh_phi_x_filtered = zeros(size(left_Hip_angle_phi_x));

% Primo campione
left_G_foot_phi_x_filtered(1) = left_Ankle_angle_phi_x(1);
left_G_shank_phi_x_filtered(1) = left_Knee_angle_phi_x(1);
left_G_thigh_phi_x_filtered(1) = left_Hip_angle_phi_x(1);

% Loop di filtraggio High-Pass (esattamente come il tuo originale)
for ii = 2 : length(left_Gyro_foot)
    left_G_foot_phi_x_filtered(ii)  = (exp(-omega_hp*T_sample) * left_G_foot_phi_x_filtered(ii - 1) + K_hp*(left_Ankle_angle_phi_x(ii) - left_Ankle_angle_phi_x(ii-1))); 
    left_G_shank_phi_x_filtered(ii) = (exp(-omega_hp*T_sample) * left_G_shank_phi_x_filtered(ii - 1) + K_hp*(left_Knee_angle_phi_x(ii) - left_Knee_angle_phi_x(ii-1))); 
    left_G_thigh_phi_x_filtered(ii) = (exp(-omega_hp*T_sample) * left_G_thigh_phi_x_filtered(ii - 1) + K_hp*(left_Hip_angle_phi_x(ii) - left_Hip_angle_phi_x(ii-1)));
end

% Correzione offset finale (come da tuo script)
left_G_foot_phi_x_filtered  = left_G_foot_phi_x_filtered - 10;
left_G_shank_phi_x_filtered = left_G_shank_phi_x_filtered - 10;
left_G_thigh_phi_x_filtered = left_G_thigh_phi_x_filtered - 10;



%% FSM initialization RIGHT - filter (ADAPTED FOR CAPTIKS)
omega_hp = 1.5; 
T_sample = 0.01; % 100Hz
K_hp = 1;

% Inizializzazione vettori filtrati Destra
right_G_foot_phi_x_filtered = zeros(size(right_Ankle_angle_phi_x));
right_G_shank_phi_x_filtered = zeros(size(right_Knee_angle_phi_x));
right_G_thigh_phi_x_filtered = zeros(size(right_Hip_angle_phi_x));

% Primo campione
right_G_foot_phi_x_filtered(1) = right_Ankle_angle_phi_x(1);
right_G_shank_phi_x_filtered(1) = right_Knee_angle_phi_x(1);
right_G_thigh_phi_x_filtered(1) = right_Hip_angle_phi_x(1);

% Loop di filtraggio High-Pass Destra
for ii = 2 : length(right_Gyro_foot)
    right_G_foot_phi_x_filtered(ii)  = (exp(-omega_hp*T_sample) * right_G_foot_phi_x_filtered(ii - 1) + K_hp*(right_Ankle_angle_phi_x(ii) - right_Ankle_angle_phi_x(ii-1))); 
    right_G_shank_phi_x_filtered(ii) = (exp(-omega_hp*T_sample) * right_G_shank_phi_x_filtered(ii - 1) + K_hp*(right_Knee_angle_phi_x(ii) - right_Knee_angle_phi_x(ii-1))); 
    right_G_thigh_phi_x_filtered(ii) = (exp(-omega_hp*T_sample) * right_G_thigh_phi_x_filtered(ii - 1) + K_hp*(right_Hip_angle_phi_x(ii) - right_Hip_angle_phi_x(ii-1)));
end

% Correzione offset finale (come da tuo script originale)
right_G_foot_phi_x_filtered  = right_G_foot_phi_x_filtered - 10;
right_G_shank_phi_x_filtered = right_G_shank_phi_x_filtered - 10;
right_G_thigh_phi_x_filtered = right_G_thigh_phi_x_filtered - 10;





%% FSM left (ADAPTED FOR CAPTIKS)
CurrentPhase_left = -1;
ThresholdFootSpeed_left = 0;
AdditionalSpeed_left = 10;
AngleLimit_left = 10;
SpeedLimitMax_left = 100;
SpeedLimitMin_left = -105;
SpeedLimitMin2_left = -15;

% Usiamo la lunghezza del vettore caviglia che abbiamo creato prima
State_left = zeros(size(left_Ankle_angle_phi_x));

% Partiamo da 3 per permettere il controllo ii-2 senza errori
for ii = 3 : length(left_Gyro_foot)
    
    % Trigger per l'inizio del passo (Heel Strike)
    if sign(left_Gyro_foot(ii, 1) * left_Gyro_foot(ii-1, 1)) <= 0 && ...
       sign(left_Gyro_foot(ii, 1)) < 0 && ...
       left_Ankle_angle_phi_x(ii) > AngleLimit_left 
        
        CurrentPhase_left = 0;
    end
    
    switch CurrentPhase_left
        case 0 % EARLY STANCE
            if sign(left_G_foot_phi_x_filtered(ii) * left_G_foot_phi_x_filtered(ii-1)) <= 0 % FOOT FLAT
                CurrentPhase_left = 1;
            else
                CurrentPhase_left = 0;
            end
            
        case 1 % MID STANCE 
            if left_Gyro_foot(ii - 2, 1) >= left_Gyro_foot(ii - 1, 1) && ...
               left_Gyro_foot(ii - 1, 1) >= left_Gyro_foot(ii, 1) && ...
               left_Gyro_foot(ii - 1, 1) <= SpeedLimitMin_left % HEEL OFF
                CurrentPhase_left = 2;
            else
                CurrentPhase_left = 1;
            end
            
        case 2 % LATE STANCE
            if left_Gyro_foot(ii - 2, 1) <= left_Gyro_foot(ii - 1, 1) && ...
               left_Gyro_foot(ii - 1, 1) <= left_Gyro_foot(ii, 1) && ...
               left_Gyro_foot(ii - 1, 1) >= SpeedLimitMin2_left % TOE OFF
                CurrentPhase_left = 3;
            else
                CurrentPhase_left = 2;
            end
            
        case 3 % INITIAL SWING
            if sign(left_G_foot_phi_x_filtered(ii) * left_G_foot_phi_x_filtered(ii-1)) <= 0 && ...
               left_Gyro_foot(ii, 1) > SpeedLimitMax_left % FEET ADJACENT
                CurrentPhase_left = 4;
            else
                CurrentPhase_left = 3;
            end
            
        case 4 % MID/LATE SWING
            if sign(left_Gyro_foot(ii, 1) * left_Gyro_foot(ii-1, 1)) <= 0 && ...
               sign(left_Gyro_foot(ii, 1)) < 0 && ...
               left_Ankle_angle_phi_x(ii) > AngleLimit_left % HEEL STRIKE
                CurrentPhase_left = 0;
            else
                CurrentPhase_left = 4;
            end
    end
    State_left(ii) = CurrentPhase_left;
end





%% FSM right (ADAPTED FOR CAPTIKS)
CurrentPhase_right = -1;
ThresholdFootSpeed_right = 0;
AdditionalSpeed_right = 10;
AngleLimit_right = 10;
SpeedLimitMax_right = 100;
SpeedLimitMin_right = -105;
SpeedLimitMin2_right = -15;

% Usiamo la lunghezza del vettore caviglia destra creato dai dati Captiks
State_right = zeros(size(right_Ankle_angle_phi_x));

% Partiamo da 3 per permettere il controllo ii-2 (finestra di 3 campioni)
for ii = 3 : length(right_Gyro_foot)
    
    % Trigger per l'inizio del passo (Heel Strike)
    if sign(right_Gyro_foot(ii, 1) * right_Gyro_foot(ii-1, 1)) <= 0 && ...
       sign(right_Gyro_foot(ii, 1)) < 0 && ...
       right_Ankle_angle_phi_x(ii) > AngleLimit_right 
        
        CurrentPhase_right = 0;
    end
    
    switch CurrentPhase_right
        case 0 % EARLY STANCE
            if sign(right_G_foot_phi_x_filtered(ii) * right_G_foot_phi_x_filtered(ii-1)) <= 0 % FOOT FLAT
                CurrentPhase_right = 1;
            else
                CurrentPhase_right = 0;
            end
            
        case 1 % MID STANCE 
            if right_Gyro_foot(ii - 2, 1) >= right_Gyro_foot(ii - 1, 1) && ...
               right_Gyro_foot(ii - 1, 1) >= right_Gyro_foot(ii, 1) && ...
               right_Gyro_foot(ii - 1, 1) <= SpeedLimitMin_right % HEEL OFF
                CurrentPhase_right = 2;
            else
                CurrentPhase_right = 1;
            end
            
        case 2 % LATE STANCE
            if right_Gyro_foot(ii - 2, 1) <= right_Gyro_foot(ii - 1, 1) && ...
               right_Gyro_foot(ii - 1, 1) <= right_Gyro_foot(ii, 1) && ...
               right_Gyro_foot(ii - 1, 1) >= SpeedLimitMin2_right % TOE OFF
                CurrentPhase_right = 3;
            else
                CurrentPhase_right = 2;
            end
            
        case 3 % INITIAL SWING
            if sign(right_G_foot_phi_x_filtered(ii) * right_G_foot_phi_x_filtered(ii-1)) <= 0 && ...
               right_Gyro_foot(ii, 1) > SpeedLimitMax_right % FEET ADJACENT
                CurrentPhase_right = 4;
            else
                CurrentPhase_right = 3;
            end
            
        case 4 % MID/LATE SWING
            if sign(right_Gyro_foot(ii, 1) * right_Gyro_foot(ii-1, 1)) <= 0 && ...
               sign(right_Gyro_foot(ii, 1)) < 0 && ...
               right_Ankle_angle_phi_x(ii) > AngleLimit_right % HEEL STRIKE
                CurrentPhase_right = 0;
            else
                CurrentPhase_right = 4;
            end
    end
    State_right(ii) = CurrentPhase_right;
end



%% --- PLOT FINALE DI VERIFICA FSM ---
t = data_angles.TIMESTAMPRELATIVE;

figure('Name', 'Analisi FSM: Caviglia vs Fasi Cammino', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);

% --- GAMBA SINISTRA ---
subplot(2,1,1);
yyaxis left
plot(t, left_Ankle_angle_phi_x, 'r', 'LineWidth', 1.5);
ylabel('Angolo Caviglia (°)');
grid on; hold on;

yyaxis right
plot(t, State_left, 'k--', 'LineWidth', 1);
ylabel('Fase FSM (0-4)');
ylim([-1 5]);
yticks([0 1 2 3 4]);
yticklabels({'Early Stance', 'Mid Stance', 'Late Stance', 'Init Swing', 'Late Swing'});
title('Gamba SINISTRA: Angolo e Identificazione Fasi');

% --- GAMBA DESTRA ---
subplot(2,1,2);
yyaxis left
plot(t, right_Ankle_angle_phi_x, 'b', 'LineWidth', 1.5);
ylabel('Angolo Caviglia (°)');
grid on; hold on;

yyaxis right
plot(t, State_right, 'k--', 'LineWidth', 1);
ylabel('Fase FSM (0-4)');
ylim([-1 5]);
yticks([0 1 2 3 4]);
yticklabels({'Early Stance', 'Mid Stance', 'Late Stance', 'Init Swing', 'Late Swing'});
title('Gamba DESTRA: Angolo e Identificazione Fasi');
xlabel('Tempo (s)');

%% --- CALCOLO STATISTICHE CLINICHE ---
% Calcoliamo quanto tempo sta in appoggio (Stance = fasi 0,1,2)
stance_L = sum(State_left <= 2 & State_left >= 0) / length(State_left) * 100;
stance_R = sum(State_right <= 2 & State_right >= 0) / length(State_right) * 100;

fprintf('\n--- RISULTATI CLINICI ---\n');
fprintf('Percentuale Appoggio (Stance) Sinistra: %.2f%%\n', stance_L);
fprintf('Percentuale Appoggio (Stance) Destra: %.2f%%\n', stance_R);
fprintf('Asimmetria (L-R): %.2f%%\n', stance_L - stance_R);
