function plot_normalized_EMG_profiles_comparison(NormalizedCycles, assessment_labels, muscle_names, signal_type)

%% --- PLOT NORMALIZED EMG PROFILES COMPARISON ---
% This function plots normalized EMG profiles across T0, T1 and T2.
%
% Each figure shows 3 muscles.
% Rows = muscles.
% Columns = assessments.
%
% Individual good cycles are shown in gray.
% Mean profile and mean ± SD are shown on top.
%
% signal_type can be:
% 'rectified'
% 'envelope'

muscles_per_page = 3;
n_muscles = length(muscle_names);
n_pages = ceil(n_muscles / muscles_per_page);

for page = 1:n_pages

    first_muscle = (page - 1) * muscles_per_page + 1;
    last_muscle = min(page * muscles_per_page, n_muscles);

    figure('Name',['Normalized ' signal_type ' profiles - page ' num2str(page)], ...
           'Units','normalized','Position',[0.05 0.05 0.9 0.85]);

    tl = tiledlayout(muscles_per_page, 3, 'TileSpacing','compact');

    title(tl, ['Normalized ' signal_type ' EMG profiles - page ' num2str(page)]);

    for m = first_muscle:last_muscle

        row = m - first_muscle + 1;

        for a = 1:3

            N = NormalizedCycles{a};
            AngBase = N.AngBase;

            switch lower(signal_type)

                case 'rectified'
                    cycles = N.EMG_rect_good_norm;

                case 'envelope'
                    cycles = N.EMG_env_good_norm;

            end

            temp_mat = zeros(length(AngBase), N.n_valid);

            for c = 1:N.n_valid
                temp_mat(:,c) = cycles{c}(:,m);
            end

            mean_profile = mean(temp_mat, 2, 'omitnan');
            std_profile  = std(temp_mat, 0, 2, 'omitnan');

            nexttile((row - 1) * 3 + a)
            hold on

            plot(AngBase, temp_mat, ...
                'Color', [0.75 0.75 0.75], ...
                'LineWidth', 0.5);

            plot(AngBase, mean_profile, ...
                'k', ...
                'LineWidth', 2);

            plot(AngBase, mean_profile + std_profile, ...
                'k--', ...
                'LineWidth', 1);

            plot(AngBase, mean_profile - std_profile, ...
                'k--', ...
                'LineWidth', 1);

            title([assessment_labels{a} ' - ' muscle_names{m}], ...
                'Interpreter','none');

            xlabel('Crank angle [deg]');
            ylabel('Normalized amplitude');

            xlim([0 360]);
            xticks([0 90 180 270 360]);

            grid on

        end
    end
end

end