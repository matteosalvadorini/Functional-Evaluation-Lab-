%% --ANGLES--


% --- ANALISI ANCA (HIP) ---
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

% --- FIGURA: BACINO (PELVIS) ---
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


% --- FIGURA: TRONCO (TRUNK) ---
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


% --- ANALISI GINOCCHIO (KNEE) ---
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


% --- ANALISI CAVIGLIA (ANKLE) ---
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






%% --POWERS--

figure('Name', 'Confronto POTENZE: Paziente vs Norma');

% --- POTENZA ANCA SX ---
subplot(3,2,1); hold on; grid on;
plot(powers.pLHPFEM, 'b', 'LineWidth', 2); % Paziente
plot(normPowers.PotenzaAncaSxM, 'r--', 'LineWidth', 2); % Norma
title('Potenza Anca Sx'); ylabel('W/kg');

% --- POTENZA ANCA DX ---
subplot(3,2,2); hold on; grid on;
plot(powers.pRHPFEM, 'b', 'LineWidth', 2); % Paziente
plot(normPowers.PotenzaAncaDxM, 'r--', 'LineWidth', 2); % Norma
title('Potenza Anca Dx'); ylabel('W/kg');


% --- POTENZA GINOCCHIO SX ---
subplot(3,2,3); hold on; grid on;
plot(powers.pLKFEM, 'b', 'LineWidth', 2);
plot(normPowers.PotenzaGinocchioSxM, 'r--', 'LineWidth', 2);
title('Potenza Ginocchio SX'); ylabel('W/kg');

% --- POTENZA GINOCCHIO DX ---
subplot(3,2,4); hold on; grid on;
plot(powers.pRKFEM, 'b', 'LineWidth', 2);
plot(normPowers.PotenzaGinocchioDxM, 'r--', 'LineWidth', 2);
title('Potenza Ginocchio DX'); ylabel('W/kg');


% --- POTENZA CAVIGLIA SX ---
subplot(3,2,5); hold on; grid on;
plot(powers.pLAFEM, 'b', 'LineWidth', 2);
plot(normPowers.PotenzaCavigliaSxM, 'r--', 'LineWidth', 2);
title('Potenza Caviglia SX'); xlabel('% Ciclo'); ylabel('W/kg');

% --- POTENZA CAVIGLIA DX ---
subplot(3,2,6); hold on; grid on;
plot(powers.pRAFEM, 'b', 'LineWidth', 2);
plot(normPowers.PotenzaCavigliaDxM, 'r--', 'LineWidth', 2);
title('Potenza Caviglia DX'); xlabel('% Ciclo'); ylabel('W/kg');








%% --MOMENTS--


% --- ANALISI ANCA (HIP) ---
figure('Name', 'Analisi Cinematica: ANCA');

% --- ANCA SX (Flessione/Estensione) ---
subplot(3,2,1); hold on; grid on;
plot(moments.tLHPFEM, 'b', 'LineWidth', 2);
plot(normMoments.MomentoFlessestAncaSxM, 'r--', 'LineWidth', 2);
title('Momento Anca SX (Fless/Est)');

% --- ANCA DESTRA (Flessione/Estensione) ---
subplot(3,2,2); hold on; grid on;
plot(moments.tRHPFEM, 'b', 'LineWidth', 2);
plot(normMoments.MomentoFlessestAncaDxM, 'r--', 'LineWidth', 2);
title('Momento Anca DX (Fless/Est)');

% Left Intra/Extra
subplot(3,2,3); hold on; grid on;
plot(moments.tRHPIEM, 'g', 'LineWidth', 1.5); % Nota: verifica se il nome è aLHPIES
plot(normMoments.MomentoIntrextrAncaSxM, 'k--', 'LineWidth', 1.5);
title('Left: Intra/Extra Rot'); ylabel('Gradi (°)');

% Right Intra/Extra
subplot(3,2,4); hold on; grid on;
plot(moments.tLHPIEM, 'g', 'LineWidth', 1.5);
plot(normMoments.MomentoIntrextrAncaDxM, 'k--', 'LineWidth', 1.5);
title('Right: Intra/Extra Rot');

% --- ANCA SX (Abduzione/Adduzione) ---
subplot(3,2,5); hold on; grid on;
plot(moments.tLHPAAM, 'g', 'LineWidth', 2);
plot(normMoments.MomentoAbdaddAncaSxM, 'k--', 'LineWidth', 2);
title('Momento Anca SX (Abd/Add)');

% --- ANCA DESTRA (Abduzione/Adduzione) ---
subplot(3,2,6); hold on; grid on;
plot(moments.tRHPAAM, 'g', 'LineWidth', 2);
plot(normMoments.MomentoAbdaddAncaDxM, 'k--', 'LineWidth', 2);
title('Momento Anca DX (Abd/Add)');




% --- ANALISI GINOCCHIO (KNEE) ---
figure('Name', 'Analisi Cinematica: GINOCCHIO');

% --- GINOCCHIO SX (Flessione/Estensione) ---
subplot(3,2,1); hold on; grid on;
% Usiamo la colonna del paziente (assicurati che il nome sia tRKFE_M o tRKFE_M)
plot(moments.tLKFEM, 'b', 'LineWidth', 2); 
plot(normMoments.MomentoFlessestGinocchioSxM, 'r--', 'LineWidth', 2);
title('Momento Ginocchio SX (Fless/Est)');
ylabel('Nm/kg');

% --- GINOCCHIO DESTRO (Flessione/Estensione) ---
subplot(3,2,2); hold on; grid on;
% Usiamo la colonna del paziente (assicurati che il nome sia tRKFE_M o tRKFE_M)
plot(moments.tRKFEM, 'b', 'LineWidth', 2); 
plot(normMoments.MomentoFlessestGinocchioDxM, 'r--', 'LineWidth', 2);
title('Momento Ginocchio DX (Fless/Est)');
ylabel('Nm/kg');

% Left Intra/Extra
subplot(3,2,3); hold on; grid on;
plot(moments.tLKIEM, 'g', 'LineWidth', 1.5);
plot(normMoments.MomentoIntrextrGinocchioSxM, 'k--', 'LineWidth', 1.5);
title('Left: Intra/Extra Rot'); ylabel('Gradi (°)');

% Right Intra/Extra
subplot(3,2,4); hold on; grid on;
plot(moments.tRKIEM, 'g', 'LineWidth', 1.5);
plot(normMoments.MomentoIntrextrGinocchioDxM, 'k--', 'LineWidth', 1.5);
title('Right: Intra/Extra Rot');

% --- GINOCCHIO SX (Varo/Valgo - Add/Abd) ---
subplot(3,2,5); hold on; grid on;
plot(moments.tLKAAM, 'g', 'LineWidth', 2);
plot(normMoments.MomentoVarvalgGinocchioSxM, 'k--', 'LineWidth', 2);
title('Momento Ginocchio SX (Var/Valg)');
ylabel('Nm/kg');

% --- GINOCCHIO DESTRO (Varo/Valgo - Add/Abd) ---
subplot(3,2,6); hold on; grid on;
plot(moments.tRKAAM, 'g', 'LineWidth', 2);
plot(normMoments.MomentoVarvalgGinocchioDxM, 'k--', 'LineWidth', 2);
title('Momento Ginocchio DX (Var/Valg)');
ylabel('Nm/kg');



% --- ANALISI CAVIGLIA (ANKLE) ---
figure('Name', 'Analisi Cinematica: CAVIGLIA');

% Left Dorsi/Planti
subplot(2,2,1); hold on; grid on;
plot(moments.tLAFEM, 'b', 'LineWidth', 1.5);
plot(normMoments.MomentoDorsplantCavigliaSxM, 'r--', 'LineWidth', 1.5);
title('Left: Dorsi/Planti'); ylabel('Gradi (°)');

% Right Dorsi/Planti
subplot(2,2,2); hold on; grid on;
plot(moments.tRAFEM, 'b', 'LineWidth', 1.5);
plot(normMoments.MomentoDorsplantCavigliaDxM, 'r--', 'LineWidth', 1.5);
title('Right: Dorsi/Planti');





%% --FORCES--

figure('Name', 'Analisi delle Forze di Reazione al Suolo (GRF)');

% --- FORZA VERTICALE (Il classico grafico a "M") ---
subplot(3,2,1); hold on; grid on;
plot(forces.fRGRVEM, 'b', 'LineWidth', 2);
title('Vertical GRF - RIGHT'); ylabel('% Weight');

subplot(3,2,2); hold on; grid on;
plot(forces.fLGRVEM, 'b', 'LineWidth', 2);
title('Vertical GRF - LEFT');

% --- FORZA ANTERO-POSTERIORE (Frenata e Spinta) ---
subplot(3,2,3); hold on; grid on;
plot(forces.fRGRAPM, 'g', 'LineWidth', 2);
title('Antero-Posterior GRF - RIGHT'); ylabel('% Weight');

subplot(3,2,4); hold on; grid on;
plot(forces.fLGRAPM, 'g', 'LineWidth', 2);
title('Antero-Posterior GRF - LEFT');

% --- FORZA MEDIO-LATERALE (Stabilità laterale) ---
subplot(3,2,5); hold on; grid on;
plot(forces.fRGRMLM, 'm', 'LineWidth', 2);
title('Medio-Lateral GRF - RIGHT'); xlabel('% Ciclo'); ylabel('% Weight');

subplot(3,2,6); hold on; grid on;
plot(forces.fLGRMLM, 'm', 'LineWidth', 2);
title('Medio-Lateral GRF - LEFT'); xlabel('% Ciclo');







