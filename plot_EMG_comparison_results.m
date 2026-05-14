function plot_EMG_comparison_results(Results, assessment_labels, muscle_names, pair_names_short, cci_pair_names)

%% --- PLOT EMG COMPARISON RESULTS ---
% This function plots the main EMG-only indicators across T0, T1 and T2:
% total activation, activation symmetry, co-contraction, and peak timing.

colors = [ ...
    0.0000 0.4470 0.7410; ...
    0.8500 0.3250 0.0980; ...
    0.4660 0.6740 0.1880];


%% --- 2. MUSCLE-SPECIFIC iEMG SYMMETRY ---

Y_SI = [Results{1}.Activation.SI_iEMG_abs_mean;
        Results{2}.Activation.SI_iEMG_abs_mean;
        Results{3}.Activation.SI_iEMG_abs_mean];

figure('Name','Muscle-specific iEMG symmetry comparison T0-T1-T2', ...
       'Units','normalized','Position',[0.1 0.1 0.85 0.5]);

b = bar(Y_SI');

for a = 1:3
    b(a).FaceColor = colors(a,:);
end

xticks(1:length(pair_names_short));
xticklabels(pair_names_short);
xtickangle(30);
ylabel('Absolute SI iEMG [%]');
title('Muscle-specific iEMG symmetry');
legend(assessment_labels, 'Location','best');
grid on;


%% --- 3. GLOBAL iEMG SYMMETRY ---

Y_global_SI = [Results{1}.Activation.SI_global_iEMG_abs_mean;
               Results{2}.Activation.SI_global_iEMG_abs_mean;
               Results{3}.Activation.SI_global_iEMG_abs_mean];

figure('Name','Global iEMG symmetry comparison T0-T1-T2', ...
       'Units','normalized','Position',[0.1 0.1 0.55 0.45]);

b = bar(Y_global_SI);
b.FaceColor = 'flat';

for a = 1:3
    b.CData(a,:) = colors(a,:);
end

xticks(1:3);
xticklabels(assessment_labels);
ylabel('Global absolute SI iEMG [%]');
title('Global iEMG symmetry');
grid on;


%% --- 4. CO-CONTRACTION INDEX ---

Y_CCI = [Results{1}.CCI.CCI_env_mean;
         Results{2}.CCI.CCI_env_mean;
         Results{3}.CCI.CCI_env_mean];

figure('Name','CCI comparison T0-T1-T2', ...
       'Units','normalized','Position',[0.1 0.1 0.85 0.5]);

b = bar(Y_CCI');

for a = 1:3
    b(a).FaceColor = colors(a,:);
end

xticks(1:length(cci_pair_names));
xticklabels(cci_pair_names);
xtickangle(30);
ylabel('CCI');
title('Co-contraction index');
legend(assessment_labels, 'Location','best');
grid on;


%% --- 5. PEAK TIMING SYMMETRY ---

Y_PeakSym = [Results{1}.TemporalSymmetry.TimingSym_Peak_mean;
             Results{2}.TemporalSymmetry.TimingSym_Peak_mean;
             Results{3}.TemporalSymmetry.TimingSym_Peak_mean];

figure('Name','Peak timing symmetry comparison T0-T1-T2', ...
       'Units','normalized','Position',[0.1 0.1 0.85 0.5]);

b = bar(Y_PeakSym');

for a = 1:3
    b(a).FaceColor = colors(a,:);
end

xticks(1:length(pair_names_short));
xticklabels(pair_names_short);
xtickangle(30);
ylabel('Peak timing symmetry error [deg]');
title('Peak timing symmetry');
legend(assessment_labels, 'Location','best');
grid on;


%% --- 6. PEAK TIMING VARIABILITY ---

Y_peak_std = [Results{1}.Timing.peak_std;
              Results{2}.Timing.peak_std;
              Results{3}.Timing.peak_std];

figure('Name','Peak timing variability comparison T0-T1-T2', ...
       'Units','normalized','Position',[0.1 0.1 0.85 0.5]);

b = bar(Y_peak_std');

for a = 1:3
    b(a).FaceColor = colors(a,:);
end

xticks(1:length(muscle_names));
xticklabels(muscle_names);
xtickangle(45);
ylabel('Peak timing circular SD [deg]');
title('Peak timing variability');
legend(assessment_labels, 'Location','best');
grid on;

end