%% --- ANALISI CINEMATICA CAPTIKS (10m Walk) ---

% 1. Recupera la tabella dal workspace
% (Sostituisci 'cpk_anatomical_angles_...' con il nome esatto della variabile nel tuo Workspace)
data_angles = cpk_anatomical_angles_2025_07_07_14_51_17; 
Remove_first_sample_Offset  = 1;
% Frequenza di campionamento (di solito 100Hz per Captiks)
T_sample = mean(diff(data_angles.TIMESTAMPRELATIVE)); 


%%

%% --- ADATTAMENTO DATASET DEFINITIVO (NUMERIC BRIDGE) ---
% Troviamo la lunghezza minima
minLen = min([height(x1G), height(x2G), height(x3G), height(x4G), ...
              height(x1B), height(x2B), height(x3B), height(x4B)]);

%% --- NUOVA FUNZIONE GETDATA ANTI-CELL ---
% Questa funzione controlla se il dato è una cella; se lo è, lo converte 
% in stringa e poi in numero. Se è già numerico, lo converte e basta.
getData = @(tab, col) cellfun(@(x) str2double(string(x)), table2cell(tab(1:minLen, col)));

% Se cellfun ti dovesse dare problemi con le dimensioni, usa questa versione più grezza ma sicura:
% getData = @(tab, col) str2double(string(tab{1:minLen, col}));

% --- SINISTRA (GREEN) ---
gravity_left_table = struct();
gravity_left_table.Var2 = getData(x1G, 2); gravity_left_table.Var3 = getData(x1G, 3); gravity_left_table.Var4 = getData(x1G, 4); 
gravity_left_table.Var5 = getData(x2G, 2); gravity_left_table.Var6 = getData(x2G, 3); gravity_left_table.Var7 = getData(x2G, 4);
gravity_left_table.Var8 = getData(x3G, 2); gravity_left_table.Var9 = getData(x3G, 3); gravity_left_table.Var10 = getData(x3G, 4);
gravity_left_table.Var11 = getData(x4G, 2); gravity_left_table.Var12 = getData(x4G, 3); gravity_left_table.Var13 = getData(x4G, 4);

gyro_left_table = struct();
gyro_left_table.Var5 = getData(x2G, 5); gyro_left_table.Var6 = getData(x2G, 6); gyro_left_table.Var7 = getData(x2G, 7);
gyro_left_table.Var8 = getData(x3G, 5); gyro_left_table.Var9 = getData(x3G, 6); gyro_left_table.Var10 = getData(x3G, 7);
gyro_left_table.Var11 = getData(x4G, 5); gyro_left_table.Var12 = getData(x4G, 6); gyro_left_table.Var13 = getData(x4G, 7);

% --- DESTRA (BLUE) ---
gravity_right_table = struct();
gravity_right_table.Var2 = getData(x1B, 2); gravity_right_table.Var3 = getData(x1B, 3); gravity_right_table.Var4 = getData(x1B, 4);
gravity_right_table.Var5 = getData(x2B, 2); gravity_right_table.Var6 = getData(x2B, 3); gravity_right_table.Var7 = getData(x2B, 4);
gravity_right_table.Var8 = getData(x3B, 2); gravity_right_table.Var9 = getData(x3B, 3); gravity_right_table.Var10 = getData(x3B, 4);
gravity_right_table.Var11 = getData(x4B, 2); gravity_right_table.Var12 = getData(x4B, 3); gravity_right_table.Var13 = getData(x4B, 4);

gyro_right_table = struct();
gyro_right_table.Var5 = getData(x2B, 5); gyro_right_table.Var6 = getData(x2B, 6); gyro_right_table.Var7 = getData(x2B, 7);
gyro_right_table.Var8 = getData(x3B, 5); gyro_right_table.Var9 = getData(x3B, 6); gyro_right_table.Var10 = getData(x3B, 7);
gyro_right_table.Var11 = getData(x4B, 5); gyro_right_table.Var12 = getData(x4B, 6); gyro_right_table.Var13 = getData(x4B, 7);


%% --- LEFT LEG ADAPTED ---



% 2. Thigh IMU Rotation
theta_thigh_init          = IMU_Configuration.IMU_B*pi/180; 
R_thigh_init              = [cos(theta_thigh_init), 0, sin(theta_thigh_init); 0,1,0; -sin(theta_thigh_init), 0, cos(theta_thigh_init)]';
left_G_thigh_cartesian    = -[gravity_left_table.Var5, gravity_left_table.Var6, gravity_left_table.Var7] * R_thigh_init;
% FIX: Qui avevi Var5 Var5 Var7, corretto in Var5 Var6 Var7
left_Gyro_thigh           = -[gyro_left_table.Var5, gyro_left_table.Var6, gyro_left_table.Var7] * R_thigh_init;

% 3. Shank IMU Rotation
theta_shank_init          = IMU_Configuration.IMU_C*pi/180; 
R_shank_init              = [cos(theta_shank_init), 0, sin(theta_shank_init); 0,1,0; -sin(theta_shank_init), 0, cos(theta_shank_init)]';
left_G_shank_cartesian    = -[gravity_left_table.Var8, gravity_left_table.Var9, gravity_left_table.Var10] * R_shank_init;
left_Gyro_shank           = -[gyro_left_table.Var8, gyro_left_table.Var9, gyro_left_table.Var10] * R_shank_init;

% 4. Foot IMU Rotation
theta_foot_init            = IMU_Configuration.IMU_D*pi/180; 
R_foot_init                = [cos(theta_foot_init), 0, sin(theta_foot_init); 0,1,0; -sin(theta_foot_init), 0, cos(theta_foot_init)]';
left_G_foot_cartesian      = -[gravity_left_table.Var11, gravity_left_table.Var12, gravity_left_table.Var13] * R_foot_init;
left_Gyro_foot             = -[gyro_left_table.Var11, gyro_left_table.Var12, gyro_left_table.Var13] * R_foot_init;

%% --- 1. PELVIS (BACINO) IMU ROTATION ---
% Ripristiniamo la rotazione iniziale del bacino
theta_pelvis_init         = IMU_Configuration.IMU_A*pi/180; 
R_pelvis_init             = [cos(theta_pelvis_init), 0, sin(theta_pelvis_init); 0,1,0; -sin(theta_pelvis_init), 0, cos(theta_pelvis_init)]';

% Calcolo coordinate cartesiane del Bacino
% Ora gravity_left_table.Var2-4 esistono perché le abbiamo messe nel Bridge
left_G_pelvis_cartesian   = -[gravity_left_table.Var2, gravity_left_table.Var3, gravity_left_table.Var4] * R_pelvis_init;


%% --- 2. THIGH (COSCIA) IMU ROTATION ---
theta_thigh_init          = IMU_Configuration.IMU_B*pi/180; 
R_thigh_init              = [cos(theta_thigh_init), 0, sin(theta_thigh_init); 0,1,0; -sin(theta_thigh_init), 0, cos(theta_thigh_init)]';
left_G_thigh_cartesian    = -[gravity_left_table.Var5, gravity_left_table.Var6, gravity_left_table.Var7] * R_thigh_init;
left_Gyro_thigh           = -[gyro_left_table.Var5, gyro_left_table.Var6, gyro_left_table.Var7] * R_thigh_init;


%% --- 3. SHANK (TIBIA) IMU ROTATION ---
theta_shank_init          = IMU_Configuration.IMU_C*pi/180; 
R_shank_init              = [cos(theta_shank_init), 0, sin(theta_shank_init); 0,1,0; -sin(theta_shank_init), 0, cos(theta_shank_init)]';
left_G_shank_cartesian    = -[gravity_left_table.Var8, gravity_left_table.Var9, gravity_left_table.Var10] * R_shank_init;
left_Gyro_shank           = -[gyro_left_table.Var8, gyro_left_table.Var9, gyro_left_table.Var10] * R_shank_init;


%% --- 4. FOOT (PIEDE) IMU ROTATION ---
theta_foot_init            = IMU_Configuration.IMU_D*pi/180; 
R_foot_init                = [cos(theta_foot_init), 0, sin(theta_foot_init); 0,1,0; -sin(theta_foot_init), 0, cos(theta_foot_init)]';
left_G_foot_cartesian      = -[gravity_left_table.Var11, gravity_left_table.Var12, gravity_left_table.Var13] * R_foot_init;
left_Gyro_foot             = -[gyro_left_table.Var11, gyro_left_table.Var12, gyro_left_table.Var13] * R_foot_init;


%% --- COMPUTE ABSOLUTE AND JOINT ANGLES ---

% Pelvis, Thigh, Shank, Foot Link Angles
left_G_pelvis_phi_x = atan2(left_G_pelvis_cartesian(:,3), left_G_pelvis_cartesian(:,2))*180/pi;
left_G_thigh_phi_x  = atan2(left_G_thigh_cartesian(:,3), left_G_thigh_cartesian(:,2))*180/pi;
left_G_shank_phi_x  = atan2(left_G_shank_cartesian(:,3), left_G_shank_cartesian(:,2))*180/pi;
left_G_foot_phi_x   = atan2(left_G_foot_cartesian(:,3), left_G_foot_cartesian(:,2))*180/pi;

% Reset Offset (se richiesto)
if Remove_first_sample_Offset
    left_G_pelvis_phi_x = left_G_pelvis_phi_x - left_G_pelvis_phi_x(1);
    left_G_thigh_phi_x  = left_G_thigh_phi_x  - left_G_thigh_phi_x(1);
    left_G_shank_phi_x  = left_G_shank_phi_x  - left_G_shank_phi_x(1);
    left_G_foot_phi_x   = left_G_foot_phi_x   - left_G_foot_phi_x(1);
end

% Joint Angles
left_Hip_angle_phi_x   = - (left_G_pelvis_phi_x - left_G_thigh_phi_x);
left_Knee_angle_phi_x  = - (left_G_thigh_phi_x  - left_G_shank_phi_x);
left_Ankle_angle_phi_x = - (left_G_shank_phi_x  - left_G_foot_phi_x);


%% LEFT LEG
%Rotate the coordinates system of the pelvis IMU
%theta_pelvis_init         = IMU_Configuration.IMU_A*pi/180; %rad
%R_pelvis_init             = [cos(theta_pelvis_init), 0, sin(theta_pelvis_init); 0,1,0; -sin(theta_pelvis_init), 0, cos(theta_pelvis_init)]';
% Pelvis
left_G_pelvis_cartesian   = -[gravity_left_table.Var2, gravity_left_table.Var3, gravity_left_table.Var4]*R_pelvis_init;

%Rotate the coordinates system of the thigh IMU
theta_thigh_init          = IMU_Configuration.IMU_B*pi/180; %rad
R_thigh_init              = [cos(theta_thigh_init), 0, sin(theta_thigh_init); 0,1,0; -sin(theta_thigh_init), 0, cos(theta_thigh_init)]';
% Thigh
left_G_thigh_cartesian    = -[gravity_left_table.Var5, gravity_left_table.Var6, gravity_left_table.Var7]*R_thigh_init;
left_Gyro_thigh           = -[gyro_left_table.Var5, gyro_left_table.Var5, gyro_left_table.Var7]*R_thigh_init;

%Rotate the coordinates system of the shank IMU
theta_shank_init          = IMU_Configuration.IMU_C*pi/180; %rad
R_shank_init              = [cos(theta_shank_init), 0, sin(theta_shank_init); 0,1,0; -sin(theta_shank_init), 0, cos(theta_shank_init)]';
% Shank
left_G_shank_cartesian    = -[gravity_left_table.Var8, gravity_left_table.Var9, gravity_left_table.Var10]*R_shank_init;
left_Gyro_shank           = -[gyro_left_table.Var8, gyro_left_table.Var9, gyro_left_table.Var10]*R_shank_init;

%Rotate the coordinates system of the foot IMU
theta_foot_init            = IMU_Configuration.IMU_D*pi/180; %-pi*Frontal_configuration;
R_foot_init                = [cos(theta_foot_init), 0, sin(theta_foot_init); 0,1,0; -sin(theta_foot_init), 0, cos(theta_foot_init)]';
% Foot
left_G_foot_cartesian      = -[gravity_left_table.Var11, gravity_left_table.Var12, gravity_left_table.Var13]*R_foot_init;
left_Gyro_foot             = -[gyro_left_table.Var11, gyro_left_table.Var12, gyro_left_table.Var13]*R_foot_init;

%Compute the absolute link angles of interest in the Sagittal Plane
% Pelvis
left_G_pelvis_phi_x        = atan2(left_G_pelvis_cartesian(:,3), left_G_pelvis_cartesian(:,2))*180/pi;
left_G_pelvis_phi_x        = left_G_pelvis_phi_x - left_G_pelvis_phi_x(1)*Remove_first_sample_Offset;

% Thigh
left_G_thigh_phi_x         = atan2(left_G_thigh_cartesian(:,3), left_G_thigh_cartesian(:,2))*180/pi;
left_G_thigh_phi_x         = left_G_thigh_phi_x - left_G_thigh_phi_x(1)*Remove_first_sample_Offset;

% Shank
left_G_shank_phi_x         = atan2(left_G_shank_cartesian(:,3), left_G_shank_cartesian(:,2))*180/pi;
left_G_shank_phi_x         = left_G_shank_phi_x - left_G_shank_phi_x(1)*Remove_first_sample_Offset;

% Foot
left_G_foot_phi_x          = atan2(left_G_foot_cartesian(:,3), left_G_foot_cartesian(:,2))*180/pi;
left_G_foot_phi_x          = left_G_foot_phi_x - left_G_foot_phi_x(1)*Remove_first_sample_Offset;

%Computing the joint angles of interess 
% Hip phi angle
left_Hip_angle_phi_x       = - (left_G_pelvis_phi_x   - left_G_thigh_phi_x);
% Knee phi angle
left_Knee_angle_phi_x      = - (left_G_thigh_phi_x    - left_G_shank_phi_x);
% Ankle phi angle
left_Ankle_angle_phi_x     = - (left_G_shank_phi_x    - left_G_foot_phi_x);

%% RIGHT LEG
%Rotate the coordinates system of the pelvis IMU
theta_pelvis_init          = IMU_Configuration.IMU_1*pi/180; %-pi/2*(1-Frontal_configuration) -pi*Frontal_configuration;
R_pelvis_init              = [cos(theta_pelvis_init), 0, sin(theta_pelvis_init); 0,1,0; -sin(theta_pelvis_init), 0, cos(theta_pelvis_init)]';
% Pelvis
right_G_pelvis_cartesian   = -[gravity_right_table.Var2, gravity_right_table.Var3, gravity_right_table.Var4]*R_pelvis_init;

% Thigh
theta_thigh_init           = IMU_Configuration.IMU_2*pi/180; 
R_thigh_init               = [cos(theta_thigh_init), 0, sin(theta_thigh_init); 0,1,0; -sin(theta_thigh_init), 0, cos(theta_thigh_init)]';
right_G_thigh_cartesian    = -[gravity_right_table.Var5, gravity_right_table.Var6, gravity_right_table.Var7]*R_thigh_init;
right_Gyro_thigh           = -[gyro_right_table.Var5, gyro_right_table.Var6, gyro_right_table.Var7]*R_thigh_init;

%Rotate the coordinates system of the shank IMU
theta_shank_init           = IMU_Configuration.IMU_3*pi/180; %-pi*Frontal_configuration;
R_shank_init               = [cos(theta_shank_init), 0, sin(theta_shank_init); 0,1,0; -sin(theta_shank_init), 0, cos(theta_shank_init)]';
% Shank
right_G_shank_cartesian    = -[gravity_right_table.Var8, gravity_right_table.Var9, gravity_right_table.Var10]*R_shank_init;
right_Gyro_shank           = -[gyro_right_table.Var8, gyro_right_table.Var9, gyro_right_table.Var10]*R_shank_init;

%Rotate the coordinates system of the foot IMU
theta_foot_init            = IMU_Configuration.IMU_4*pi/180; %-pi*Frontal_configuration;
R_foot_init                = [cos(theta_foot_init), 0, sin(theta_foot_init); 0,1,0; -sin(theta_foot_init), 0, cos(theta_foot_init)]';
% Foot
right_G_foot_cartesian     = -[gravity_right_table.Var11, gravity_right_table.Var12, gravity_right_table.Var13]*R_foot_init;
right_Gyro_foot            = -[gyro_right_table.Var11, gyro_right_table.Var12, gyro_right_table.Var13]*R_foot_init;

%Compute the absolute link angles of interest in the Sagittal Plane
% Pelvis
right_G_pelvis_phi_x       = atan2(right_G_pelvis_cartesian(:,3), right_G_pelvis_cartesian(:,2))*180/pi;
right_G_pelvis_phi_x       = right_G_pelvis_phi_x - right_G_pelvis_phi_x(1)*Remove_first_sample_Offset;

% Thigh
right_G_thigh_phi_x        = atan2(right_G_thigh_cartesian(:,3), right_G_thigh_cartesian(:,2))*180/pi;
right_G_thigh_phi_x        = right_G_thigh_phi_x - right_G_thigh_phi_x(1)*Remove_first_sample_Offset;

% Shank
right_G_shank_phi_x        = atan2(right_G_shank_cartesian(:,3), right_G_shank_cartesian(:,2))*180/pi;
right_G_shank_phi_x        = right_G_shank_phi_x - right_G_shank_phi_x(1)*Remove_first_sample_Offset;

% Foot
right_G_foot_phi_x         = atan2(right_G_foot_cartesian(:,3), right_G_foot_cartesian(:,2))*180/pi;
right_G_foot_phi_x         = right_G_foot_phi_x - right_G_foot_phi_x(1)*Remove_first_sample_Offset;

%Computing the joint angles of interess 
% Hip phi angle
right_Hip_angle_phi_x      = - (right_G_pelvis_phi_x   - right_G_thigh_phi_x);
% Knee phi angle
right_Knee_angle_phi_x     = - (right_G_thigh_phi_x    - right_G_shank_phi_x);
% Ankle phi angle
right_Ankle_angle_phi_x    = - (right_G_shank_phi_x    - right_G_foot_phi_x);



%% 1. Mapping Variabili Sinistra (LEFT LEG)
% Estraiamo i dati dalla tabella Captiks mappandoli sui nomi del tuo vecchio script

% Angoli calcolati direttamente dal software Captiks
left_Ankle_angle_phi_x = data_angles.ANKLEDORSIFLEXION_PLANTARFLEXIONLEFT;
left_Knee_angle_phi_x  = data_angles.KNEEFLEXION_EXTENSIONLEFT;
left_Hip_angle_phi_x   = data_angles.HIPFLEXION_EXTENSIONLEFT;

% Simuliamo i giroscopi (necessari per la FSM) calcolando la derivata degli angoli
% poichè nel tuo file CSV non hai la velocità angolare pura del sensore
left_Gyro_foot = -[0; diff(left_Ankle_angle_phi_x) / T_sample];

%% 2. Mapping Variabili Destra (RIGHT LEG)
right_Ankle_angle_phi_x = data_angles.ANKLEDORSIFLEXION_PLANTARFLEXIONRIGHT;
right_Knee_angle_phi_x  = data_angles.KNEEFLEXION_EXTENSIONRIGHT;
right_Hip_angle_phi_x   = data_angles.HIPFLEXION_EXTENSIONRIGHT;

right_Gyro_foot = -[0; diff(right_Ankle_angle_phi_x) / T_sample];

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









%%



%% --- PRE-ELABORAZIONE DATASET (PULIZIA PROFESSIONALE) ---

% 1. Filtro Mediano: è fondamentale per il tuo segnale. 
% Rimuove quegli spike (spilli) ad alta frequenza senza distorcere l'onda.
window_med = 15; 
left_Gyro_foot(:,1) = medfilt1(left_Gyro_foot(:,1), window_med);
right_Gyro_foot(:,1) = medfilt1(right_Gyro_foot(:,1), window_med);

% 2. Filtro Passa-Basso (Butterworth): 
% Elimina il rumore residuo e rende le curve "lisce" come nel dataset che funziona.
fs = 100; % Frequenza di campionamento (cambiala se non è 100Hz)
fc = 6;   % Frequenza di taglio (6Hz è lo standard per la camminata)
[b, a] = butter(4, fc/(fs/2), 'low');

left_Gyro_foot(:,1) = filtfilt(b, a, left_Gyro_foot(:,1));
right_Gyro_foot(:,1) = filtfilt(b, a, right_Gyro_foot(:,1));

% 3. Pulizia dell'Angolo e del segnale filtrato aggiuntivo
% Applichiamo lo stesso filtro per coerenza temporale (evita sfasamenti)
left_Ankle_angle_phi_x = filtfilt(b, a, left_Ankle_angle_phi_x);
right_Ankle_angle_phi_x = filtfilt(b, a, right_Ankle_angle_phi_x);

left_G_foot_phi_x_filtered = filtfilt(b, a, left_G_foot_phi_x_filtered);
right_G_foot_phi_x_filtered = filtfilt(b, a, right_G_foot_phi_x_filtered);

%% --- ORA PUOI FAR GIRARE IL TUO CODICE ESATTO ---
% (Inserisci qui il tuo ciclo for con la FSM originale)

%% --- SINCRONIZZAZIONE LUNGHEZZE PRIMA DELLA FSM ---
% Trova la lunghezza minima tra i vettori che usi nella condizione della riga 381
N = min([length(left_Gyro_foot), length(left_G_foot_phi_x), length(left_G_foot_phi_x_filtered)]);

% Taglia tutto a N
left_Gyro_foot = left_Gyro_foot(1:N, :);
left_G_foot_phi_x = left_G_foot_phi_x(1:N);
left_G_foot_phi_x_filtered = left_G_foot_phi_x_filtered(1:N);
left_Ankle_angle_phi_x = left_Ankle_angle_phi_x(1:N); % Se lo usi


%% --- SINCRONIZZAZIONE DEFINITIVA LUNGHEZZE ---
% Trova il minimo comune denominatore di tutte le variabili usate nella FSM
N_final = min([length(left_Gyro_foot), length(left_G_foot_phi_x), ...
               length(left_G_foot_phi_x_filtered), length(left_Ankle_angle_phi_x)]);

% Applica il taglio a tutto (Sinistra)
left_Gyro_foot = left_Gyro_foot(1:N_final, :);
left_G_foot_phi_x = left_G_foot_phi_x(1:N_final);
left_G_foot_phi_x_filtered = left_G_foot_phi_x_filtered(1:N_final);
left_Ankle_angle_phi_x = left_Ankle_angle_phi_x(1:N_final);
State_left = zeros(N_final, 1);

% Applica il taglio a tutto (Destra - calcola N separato se necessario)
N_final_R = min([length(right_Gyro_foot), length(right_G_foot_phi_x), ...
                 length(right_G_foot_phi_x_filtered), length(right_Ankle_angle_phi_x)]);
right_Gyro_foot = right_Gyro_foot(1:N_final_R, :);
right_G_foot_phi_x = right_G_foot_phi_x(1:N_final_R);
right_G_foot_phi_x_filtered = right_G_foot_phi_x_filtered(1:N_final_R);
right_Ankle_angle_phi_x = right_Ankle_angle_phi_x(1:N_final_R);
State_right = zeros(N_final_R, 1);

%% FSM left (ADAPTED FOR CAPTIKS)
CurrentPhase_left = -1;
ThresholdFootSpeed_left = 0;
AdditionalSpeed_left = 10;
% SINISTRA (Left)
AngleLimit_left = -5;      
SpeedLimitMax_left = 25;    % Aumenta la tolleranza per lo swing
SpeedLimitMin_left = -25;   % Aumenta la tolleranza per l'inizio stance
SpeedLimitMin2_left = -10;
State_left = zeros(size(left_Ankle_angle_phi_x));

% Partiamo da 3 per permettere il controllo ii-2 senza errori


for ii = 3 : size(left_Gyro_foot, 1)

    if sign (left_Gyro_foot(ii, 1) * left_Gyro_foot(ii-1, 1)) <= 0 && sign(left_Gyro_foot(ii, 1)) <0 && left_G_foot_phi_x(ii) > AngleLimit_left 
        CurrentPhase_left = 0;
    end
    
    switch CurrentPhase_left
        case 0 %EARLY STANCE
            if sign(left_G_foot_phi_x_filtered(ii) * left_G_foot_phi_x_filtered(ii-1)) <= 0 %FOOT FLAT
                CurrentPhase_left = 1;
            else
                CurrentPhase_left = 0;
            end
        case 1 %MID STANCE 
            if left_Gyro_foot(ii - 2, 1) >= left_Gyro_foot(ii - 1, 1) && left_Gyro_foot(ii - 1, 1) >= left_Gyro_foot(ii, 1) && ...
                    left_Gyro_foot(ii - 1, 1) <= SpeedLimitMin_left %HEEL OFF
                CurrentPhase_left = 2;
            else
                CurrentPhase_left = 1;
            end
        case 2 %LATE STANCE
            if left_Gyro_foot(ii - 2, 1) <= left_Gyro_foot(ii - 1, 1) && left_Gyro_foot(ii - 1, 1) <= left_Gyro_foot(ii, 1) && ...
                    left_Gyro_foot(ii - 1, 1) >= SpeedLimitMin2_left %TOE OFF
                CurrentPhase_left = 3;
            else
                CurrentPhase_left = 2;
            end
        case 3 %INITIAL SWING
            if sign(left_G_foot_phi_x_filtered(ii) * left_G_foot_phi_x_filtered(ii-1)) <= 0 && left_Gyro_foot(ii, 1) > SpeedLimitMax_left %FEET ADJACENT
                CurrentPhase_left = 4;
            else
                CurrentPhase_left = 3;
            end
        case 4 %MID/LATE SWING
            if sign (left_Gyro_foot(ii, 1) * left_Gyro_foot(ii-1, 1)) <= 0 && sign(left_Gyro_foot(ii, 1)) <0 && left_G_foot_phi_x(ii) > AngleLimit_left  %HEEL STRIKE
                CurrentPhase_left = 0;
            else
                CurrentPhase_left = 4;
            end
    end

    State_left(ii) = CurrentPhase_left;
end



%%
%% --- SINCRONIZZAZIONE LUNGHEZZE PRIMA DELLA FSM ---
% Trova la lunghezza minima tra i vettori che usi nella condizione della riga 381
N = min([length(right_Gyro_foot), length(right_G_foot_phi_x), length(right_G_foot_phi_x_filtered)]);

% Taglia tutto a N
right_Gyro_foot = right_Gyro_foot(1:N, :);
right_G_foot_phi_x = right_G_foot_phi_x(1:N);
right_G_foot_phi_x_filtered = right_G_foot_phi_x_filtered(1:N);
right_Ankle_angle_phi_x = right_Ankle_angle_phi_x(1:N); % Se lo usi







%% FSM right (ADAPTED FOR CAPTIKS)
CurrentPhase_right = -1;
ThresholdFootSpeed_right = 0;
AdditionalSpeed_right = 10;
% DESTRA (Right) - Qui avevi dei valori troppo piccoli (0.05)!
AngleLimit_right = -5; 
SpeedLimitMax_right = 25;
SpeedLimitMin_right = -25;
SpeedLimitMin2_right = -10;


% Usiamo la lunghezza del vettore caviglia destra creato dai dati Captiks
State_right = zeros(size(right_Ankle_angle_phi_x));

% Partiamo da 3 per permettere il controllo ii-2 (finestra di 3 campioni)

for ii = 3 : size(right_Gyro_foot, 1)

    if sign (right_Gyro_foot(ii, 1) * right_Gyro_foot(ii-1, 1)) <= 0 && sign(right_Gyro_foot(ii, 1)) <0 && right_G_foot_phi_x(ii) > AngleLimit_right 
        CurrentPhase_right = 0;
    end
    
    switch CurrentPhase_right
        case 0 %EARLY STANCE
            if sign(right_G_foot_phi_x_filtered(ii) * right_G_foot_phi_x_filtered(ii-1)) <= 0 %FOOT FLAT
                CurrentPhase_right = 1;
            else
                CurrentPhase_right = 0;
            end
        case 1 %MID STANCE 
            if right_Gyro_foot(ii - 2, 1) >= right_Gyro_foot(ii - 1, 1) && right_Gyro_foot(ii - 1, 1) >= right_Gyro_foot(ii, 1) && ...
                    right_Gyro_foot(ii - 1, 1) <= SpeedLimitMin_right %HEEL OFF
                CurrentPhase_right = 2;
            else
                CurrentPhase_right = 1;
            end
        case 2 %LATE STANCE
            if right_Gyro_foot(ii - 2, 1) <= right_Gyro_foot(ii - 1, 1) && right_Gyro_foot(ii - 1, 1) <= right_Gyro_foot(ii, 1) && ...
                    right_Gyro_foot(ii - 1, 1) >= SpeedLimitMin2_right %TOE OFF
                CurrentPhase_right = 3;
            else
                CurrentPhase_right = 2;
            end
        case 3 %INITIAL SWING
            if sign(right_G_foot_phi_x_filtered(ii) * right_G_foot_phi_x_filtered(ii-1)) <= 0 && right_Gyro_foot(ii, 1) > SpeedLimitMax_right %FEET ADJACENT
                CurrentPhase_right = 4;
            else
                CurrentPhase_right = 3;
            end
        case 4 %MID/LATE SWING
            if sign (right_Gyro_foot(ii, 1) * right_Gyro_foot(ii-1, 1)) <= 0 && sign(right_Gyro_foot(ii, 1)) <0 && right_G_foot_phi_x(ii) > AngleLimit_right  %HEEL STRIKE
                CurrentPhase_right = 0;
            else
                CurrentPhase_right = 4;
            end
    end

    State_right(ii) = CurrentPhase_right;
end




%% --- PLOT FINALE DI VERIFICA FSM ---
% --- SINCRONIZZAZIONE TEMPO PER IL PLOT ---

% Prendiamo il tempo relativo
t = seconds(data_angles.TIMESTAMPRELATIVE - data_angles.TIMESTAMPRELATIVE(1));

% Troviamo la lunghezza effettiva dei dati calcolati
% (Usiamo left_Ankle_angle_phi_x come riferimento)
N_plot = length(left_Ankle_angle_phi_x);

% Tagliamo il tempo alla stessa lunghezza dei dati
if length(t) > N_plot
    t = t(1:N_plot);
elseif length(t) < N_plot
    % Caso raro: se i dati sono più lunghi del tempo, tagliamo i dati
    left_Ankle_angle_phi_x = left_Ankle_angle_phi_x(1:length(t));
    % Fai lo stesso per le altre variabili che vuoi plottare (es. State_left)
    State_left = State_left(1:length(t));
end
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





