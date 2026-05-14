function plot_EMG_trike_sync_quality(Synced, assessment_labels)

%% --- PLOT EMG-TRIKE SYNCHRONIZATION QUALITY ---
% This function checks the alignment between EMG and trike signals.
%
% The EMG trigger and the trike crank angle are normalized only for plotting.
% Red markers show EMG trigger peaks.
% Blue markers show trike crank-angle resets.
%
% This is only a synchronization check. Final cycle segmentation is based on
% trike crank-angle resets.

for a = 1:3

    S = Synced{a};

    t_emg = S.t_emg_sync;
    t_trike = S.t_trike_sync;

    trigger = S.trig_sync;
    angle = S.trike.angle;

    trigger_norm = (trigger - min(trigger)) / (max(trigger) - min(trigger));
    angle_norm = angle / 360;

    locs_emg = S.locs_emg_sync;
    locs_trike = S.locs_trike_sync;

    figure('Name',['Synchronization check - ' assessment_labels{a}], ...
           'Units','normalized','Position',[0.08 0.08 0.85 0.75]);

    for p = 1:2

        subplot(2,1,p)
        hold on

        plot(t_trike, angle_norm, 'b', 'LineWidth', 1.2);
        plot(t_emg, trigger_norm, 'r', 'LineWidth', 1);

        plot(t_emg(locs_emg), trigger_norm(locs_emg), 'ro', ...
            'MarkerFaceColor','r', ...
            'MarkerSize', 4);

        plot(t_trike(locs_trike), angle_norm(locs_trike), 'bo', ...
            'MarkerFaceColor','b', ...
            'MarkerSize', 4);

        xlabel('Time [s]');
        ylabel('Normalized amplitude');
        grid on

        if p == 1
            title([assessment_labels{a} ' - full synchronization check']);
            legend({'Trike angle / 360', ...
                    'EMG trigger', ...
                    'EMG trigger peaks', ...
                    'Trike angle resets'}, ...
                    'Location','best');
        else
            title([assessment_labels{a} ' - first 10 seconds']);
            xlim([0 10]);
        end

    end

    n_emg_cycles = length(locs_emg) - 1;
    n_trike_cycles = length(locs_trike) - 1;

    fprintf('\n--- SYNC CHECK: %s ---\n', assessment_labels{a});
    fprintf('EMG trigger cycles: %d\n', n_emg_cycles);
    fprintf('TRIKE cycles:       %d\n', n_trike_cycles);
    fprintf('Difference:         %d\n', n_emg_cycles - n_trike_cycles);

end

end