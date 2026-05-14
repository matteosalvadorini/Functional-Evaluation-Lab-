function plot_example_EMG_cycle_comparison(Preprocessed, TrikeCycleInfo, GoodCycleInfo, assessment_labels, muscle_names)

%% --- PLOT EXAMPLE EMG CYCLE COMPARISON ---
% This function plots one representative good cycle for each assessment.
%
% For each assessment, the middle good cycle is selected.
% Rows = muscles.
% Columns = assessments.
%
% Rectified EMG and EMG envelope are shown together.

muscles_per_page = 4;
n_muscles = length(muscle_names);
n_pages = ceil(n_muscles / muscles_per_page);

for page = 1:n_pages

    first_muscle = (page - 1) * muscles_per_page + 1;
    last_muscle = min(page * muscles_per_page, n_muscles);

    figure('Name',['Example EMG cycle comparison - page ' num2str(page)], ...
           'Units','normalized','Position',[0.05 0.05 0.9 0.85]);

    tl = tiledlayout(muscles_per_page, 3, 'TileSpacing','compact');

    title(tl, ['Example good cycle comparison - page ' num2str(page)]);

    for m = first_muscle:last_muscle

        row = m - first_muscle + 1;

        for a = 1:3

            P = Preprocessed{a};
            C = TrikeCycleInfo{a};
            G = GoodCycleInfo{a};

            mid_good = G.good_cycles(round(G.n_valid / 2));

            idx_start = C.locs_trig(mid_good);
            idx_end   = C.locs_trig(mid_good + 1) - 1;

            rect_seg = P.emg_rect(idx_start:idx_end, m);
            env_seg  = P.emg_env(idx_start:idx_end, m);

            angle = linspace(0, 360, length(rect_seg));

            nexttile((row - 1) * 3 + a)
            hold on

            plot(angle, rect_seg, ...
                'Color', [0.75 0.75 0.75], ...
                'LineWidth', 0.8);

            plot(angle, env_seg, ...
                'k', ...
                'LineWidth', 1.5);

            title([assessment_labels{a} ' - ' muscle_names{m}], ...
                'Interpreter','none');

            xlabel('Crank angle [deg]');
            ylabel('Amplitude');

            xlim([0 360]);
            xticks([0 90 180 270 360]);

            grid on

        end
    end
end

end