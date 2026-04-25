%% --- ANALISI ANCA (HIP) ---
figure('Name', 'Analisi Cinematica: ANCA');

% Left Flessione/Estensione
subplot(3,2,1); hold on; grid on;
plot(angles.aLHPFEM, 'b', 'LineWidth', 1.5, 'DisplayName', 'Paziente');
plot(normAngles.FlessestAncaSxM, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Norma');
title('Left: Fless/Est'); ylabel('Gradi (°)'); legend;

% Right Flessione/Estensione
subplot(3,2,2); hold on; grid on;
plot(angles.aRHPFEM, 'b', 'LineWidth', 1.5);
plot(normAngles.FlessestAncaDxM, 'r--','LineWidth', 1.5);
title('Right: Fless/Est');

% Left Intra/Extra
subplot(3,2,3); hold on; grid on;
plot(angles.aLHPIEM, 'g', 'LineWidth', 1.5); % Nota: verifica se il nome è aLHPIES
plot(normAngles.IntrextrAncaSxM, 'k--', 'LineWidth', 1.5);
title('Left: Intra/Extra Rot'); ylabel('Gradi (°)');

% Right Intra/Extra
subplot(3,2,4); hold on; grid on;
plot(angles.aRHPIEM, 'g', 'LineWidth', 1.5);
plot(normAngles.IntrextrAncaDxM, 'k--', 'LineWidth', 1.5);
title('Right: Intra/Extra Rot');

% Left hip add-abduction
subplot(3,2,5); hold on; grid on;
plot(angles.aLHPAAM, 'g', 'LineWidth', 1.5); % Nota: verifica se il nome è aLHPIES
plot(normAngles.AbdaddAncaSxM, 'k--', 'LineWidth', 1.5);
title('Left: hip add-abduction'); ylabel('Gradi (°)');

% Right hip add-abduction
subplot(3,2,6); hold on; grid on;
plot(angles.aRHPAAM, 'g', 'LineWidth', 1.5);
plot(normAngles.AbdaddAncaDxM, 'k--', 'LineWidth', 1.5);
title('Right: hip add-abduction');

%% --- FIGURA: BACINO (PELVIS) ---
figure('Name', 'Confronto Cinematica: BACINO');

% TILT (Sagittale)
subplot(3,2,1); hold on; grid on;
plot(angles.aRPTILTM, 'b', 'LineWidth', 1.5);
plot(normAngles.TiltPelvicoDxM, 'r--', 'LineWidth', 1.5);
title('Right Pelvis Tilt'); ylabel('Gradi (°)');

subplot(3,2,2); hold on; grid on;
plot(angles.aLPTILTM, 'b', 'LineWidth', 1.5);
plot(normAngles.TiltPelvicoSxM, 'r--', 'LineWidth', 1.5);
title('Left Pelvis Tilt');

% OBLIQUITY (Frontale)
subplot(3,2,3); hold on; grid on;
plot(angles.aRPOBLIM, 'g', 'LineWidth', 1.5);
plot(normAngles.ObliquitaPelvicaDxM, 'k--', 'LineWidth', 1.5);
title('Right Pelvis Obliquity'); ylabel('Gradi (°)');

subplot(3,2,4); hold on; grid on;
plot(angles.aLPOBLIM, 'g', 'LineWidth', 1.5);
plot(normAngles.ObliquitaPelvicaSxM, 'k--', 'LineWidth', 1.5);
title('Left Pelvis Obliquity');

% ROTATION (Orizzontale)
subplot(3,2,5); hold on; grid on;
plot(angles.aRPROTM, 'm', 'LineWidth', 1.5);
plot(normAngles.RotazionePelvicaDxM, 'r--', 'LineWidth', 1.5);
title('Right Pelvis Rotation'); xlabel('% Ciclo');

subplot(3,2,6); hold on; grid on;
plot(angles.aLPROTM, 'm', 'LineWidth', 1.5);
plot(normAngles.RotazionePelvicaSxM, 'r--', 'LineWidth', 1.5);
title('Left Pelvis Rotation'); xlabel('% Ciclo');


%% --- FIGURA: TRONCO (TRUNK) ---
figure('Name', 'Confronto Cinematica: TRONCO');

% Flessione/Estensione
subplot(3,2,1); hold on; grid on;
plot(angles.MediaFlexextDxM, 'b', 'LineWidth', 1.5);
% Se non hai TiltSpallaDxM, verifica il nome esatto nella norma
plot(normAngles.TiltSpallaDxM, 'r--', 'LineWidth', 1.5); 
title('Right Trunk Flex/Ext');

subplot(3,2,2); hold on; grid on;
plot(angles.MediaFlexextSxM, 'b', 'LineWidth', 1.5);
plot(normAngles.TiltSpallaSxM, 'r--', 'LineWidth', 1.5);
title('Left Trunk Flex/Ext');

% Obliquità
subplot(3,2,3); hold on; grid on;
plot(angles.MediaObliquitaDxM, 'g', 'LineWidth', 1.5);
plot(normAngles.ObliquitaSpallaDxM, 'k--', 'LineWidth', 1.5);
title('Right Trunk Obliquity');

subplot(3,2,4); hold on; grid on;
plot(angles.MediaObliquitaSxM, 'g', 'LineWidth', 1.5);
plot(normAngles.ObliquitaSpallaSxM, 'k--', 'LineWidth', 1.5);
title('Left Trunk Obliquity');

% Rotazione
subplot(3,2,5); hold on; grid on;
plot(angles.MediaIntraextraDxM, 'm', 'LineWidth', 1.5);
plot(normAngles.RotazioneSpallaDxM, 'r--', 'LineWidth', 1.5);
title('Right Trunk Rotation');

subplot(3,2,6); hold on; grid on;
plot(angles.MediaIntraextraSxM, 'm', 'LineWidth', 1.5);
plot(normAngles.RotazioneSpallaSxM, 'r--', 'LineWidth', 1.5);
title('Left Trunk Rotation');


%% --- ANALISI GINOCCHIO (KNEE) ---
figure('Name', 'Analisi Cinematica: GINOCCHIO');

% Left Flessione/Estensione
subplot(3,2,1); hold on; grid on;
plot(angles.aLKFEM, 'b', 'LineWidth', 1.5);
plot(normAngles.FlessestGinocchioSxM, 'r--', 'LineWidth', 1.5);
title('Left: Fless/Est'); ylabel('Gradi (°)');

% Right Flessione/Estensione
subplot(3,2,2); hold on; grid on;
plot(angles.aRKFEM, 'b', 'LineWidth', 1.5);
plot(normAngles.FlessestGinocchioDxM, 'r--', 'LineWidth', 1.5);
title('Right: Fless/Est');

% Left Intra/Extra
subplot(3,2,3); hold on; grid on;
plot(angles.aLKIEM, 'g', 'LineWidth', 1.5);
plot(normAngles.IntrextrGinocchioSxM, 'k--', 'LineWidth', 1.5);
title('Left: Intra/Extra Rot'); ylabel('Gradi (°)');

% Right Intra/Extra
subplot(3,2,4); hold on; grid on;
plot(angles.aRKIEM, 'g', 'LineWidth', 1.5);
plot(normAngles.IntrextrGinocchioDxM, 'k--', 'LineWidth', 1.5);
title('Right: Intra/Extra Rot');

% Left knee add-abduction
subplot(3,2,5); hold on; grid on;
plot(angles.aLKAAM, 'g', 'LineWidth', 1.5);
plot(normAngles.VarvalgGinocchioSxM, 'k--', 'LineWidth', 1.5);
title('Left: add-abduction'); ylabel('Gradi (°)');

% Right knee add-abduction
subplot(3,2,6); hold on; grid on;
plot(angles.aRKAAM, 'g', 'LineWidth', 1.5);
plot(normAngles.VarvalgGinocchioDxM, 'k--', 'LineWidth', 1.5);
title('Right: add-abduction');


%% --- ANALISI CAVIGLIA (ANKLE) ---
figure('Name', 'Analisi Cinematica: CAVIGLIA');

% Left Dorsi/Planti
subplot(2,2,1); hold on; grid on;
plot(angles.aLAFEM, 'b', 'LineWidth', 1.5);
plot(normAngles.DorsplantCavigliaSxM, 'r--', 'LineWidth', 1.5);
title('Left: Dorsi/Planti'); ylabel('Gradi (°)');

% Right Dorsi/Planti
subplot(2,2,2); hold on; grid on;
plot(angles.aRAFEM, 'b', 'LineWidth', 1.5);
plot(normAngles.DorsplantCavigliaDxM, 'r--', 'LineWidth', 1.5);
title('Right: Dorsi/Planti');

% Left internal external rotation
subplot(2,2,3); hold on; grid on;
plot(angles.aLAIEM, 'g', 'LineWidth', 1.5);
plot(normAngles.ProgressionePiedeSxM, 'k--', 'LineWidth', 1.5);
title('Left: internal external rotation'); ylabel('Gradi (°)');

% Right internal external rotation
subplot(2,2,4); hold on; grid on;
plot(angles.aRAIEM, 'g', 'LineWidth', 1.5);
plot(normAngles.ProgressionePiedeDxM, 'k--', 'LineWidth', 1.5);
title('Right: internal external rotation');