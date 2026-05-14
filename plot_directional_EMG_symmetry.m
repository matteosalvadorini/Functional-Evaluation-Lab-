function plot_directional_EMG_symmetry(Results, assessment_labels, pair_names_short)

%% --- PLOT DIRECTIONAL EMG SYMMETRY ---
% This function plots the signed iEMG symmetry index for each homologous
% muscle pair.
%
% Positive values indicate greater right-side activation.
% Negative values indicate greater left-side activation.
%
% This is complementary to the absolute symmetry index, because it shows the
% direction of the asymmetry, not only its magnitude.

colors = [ ...
    0.0000 0.4470 0.7410; ...
    0.8500 0.3250 0.0980; ...
    0.4660 0.6740 0.1880];

Y_directional_SI = [Results{1}.Activation.SI_iEMG_mean;
                    Results{2}.Activation.SI_iEMG_mean;
                    Results{3}.Activation.SI_iEMG_mean];

figure('Name','Directional EMG symmetry index T0-T1-T2', ...
       'Units','normalized','Position',[0.1 0.1 0.85 0.5]);

b = bar(Y_directional_SI');

for a = 1:3
    b(a).FaceColor = colors(a,:);
end

yline(0, 'k-', 'LineWidth', 1.3);

xticks(1:length(pair_names_short));
xticklabels(pair_names_short);
xtickangle(30);

ylabel('Signed SI iEMG [%]');
title('Directional iEMG symmetry index');

legend(assessment_labels, 'Location','best');
grid on;

end