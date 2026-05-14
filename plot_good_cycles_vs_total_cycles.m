function plot_good_cycles_vs_total_cycles(TrikeCycleInfo, GoodCycleInfo, assessment_labels, common_target_cadence, cadence_tolerance)

%% --- PLOT GOOD CYCLES VS TOTAL CYCLES ---
% This function plots the cadence of all trike-based cycles and highlights
% the selected good cycles.
%
% The target cadence and tolerance band are shown to verify where the good
% cycles are located within each assessment.

figure('Name','Good cycles vs total cycles', ...
       'Units','normalized','Position',[0.08 0.08 0.85 0.8]);

for a = 1:3

    cadence = TrikeCycleInfo{a}.cadence;
    good_cycles = GoodCycleInfo{a}.good_cycles;

    n_cycles = length(cadence);
    cycle_idx = 1:n_cycles;

    subplot(3,1,a)
    hold on

    plot(cycle_idx, cadence, '-o', ...
        'Color', [0.65 0.65 0.65], ...
        'MarkerFaceColor', [0.75 0.75 0.75], ...
        'MarkerSize', 4, ...
        'LineWidth', 1);

    plot(good_cycles, cadence(good_cycles), 'ro', ...
        'MarkerFaceColor', 'r', ...
        'MarkerSize', 5);

    yline(common_target_cadence, 'k--', 'LineWidth', 1.2);
    yline(common_target_cadence + cadence_tolerance, 'r:', 'LineWidth', 1);
    yline(common_target_cadence - cadence_tolerance, 'r:', 'LineWidth', 1);

    xline(n_cycles/3, 'b--', 'LineWidth', 1);
    xline(2*n_cycles/3, 'b--', 'LineWidth', 1);

    xlabel('Cycle number');
    ylabel('Cadence [RPM]');
    title([assessment_labels{a} ...
        ' - good cycles: ' num2str(length(good_cycles)) ...
        '/' num2str(n_cycles)]);

    grid on
    xlim([1 n_cycles]);

end

end