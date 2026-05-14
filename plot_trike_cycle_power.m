function plot_trike_cycle_power(S, TrikeCycleInfo, GoodCycleInfo)

%% --- PLOT TRIKE POWER ACROSS CYCLES ---
% This function plots right, left and total trike power cycle by cycle.
%
% Mean power is computed for each trike-based cycle.
% All cycles are shown in gray, while good cycles are highlighted in red.

trike = S.trike;
locs_trike = TrikeCycleInfo.locs_trike;
good_cycles = GoodCycleInfo.good_cycles;

n_cycles_total = length(locs_trike) - 1;
cycle_idx = 1:n_cycles_total;

PowerR_mean = NaN(n_cycles_total,1);
PowerL_mean = NaN(n_cycles_total,1);
PowerTotal_mean = NaN(n_cycles_total,1);


%% --- COMPUTE MEAN POWER PER CYCLE ---

for c = 1:n_cycles_total

    idx_start = locs_trike(c);
    idx_end   = locs_trike(c+1) - 1;

    powerR = trike.powerRight(idx_start:idx_end);
    powerL = trike.powerLeft(idx_start:idx_end);

    PowerR_mean(c) = mean(powerR, 'omitnan');
    PowerL_mean(c) = mean(powerL, 'omitnan');
    PowerTotal_mean(c) = mean(powerR + powerL, 'omitnan');

end


%% --- PLOT POWER ACROSS CYCLES ---

figure('Name',['Trike power across cycles - ' S.label], ...
       'Units','normalized','Position',[0.08 0.08 0.85 0.75]);

power_data = {PowerR_mean, PowerL_mean, PowerTotal_mean};
plot_titles = {'Right power per cycle', ...
               'Left power per cycle', ...
               'Total power per cycle'};
y_labels = {'Power Right [W]', ...
            'Power Left [W]', ...
            'Total Power [W]'};

for p = 1:3

    subplot(3,1,p)
    hold on

    plot(cycle_idx, power_data{p}, '-o', ...
        'Color', [0.7 0.7 0.7], ...
        'MarkerFaceColor', [0.75 0.75 0.75], ...
        'LineWidth', 1);

    plot(good_cycles, power_data{p}(good_cycles), 'ro', ...
        'MarkerFaceColor','r', ...
        'LineWidth', 1);

    ylabel(y_labels{p});
    title([S.label ' - ' plot_titles{p}]);
    grid on

    if p == 3
        xlabel('Cycle number');
    end

end

end