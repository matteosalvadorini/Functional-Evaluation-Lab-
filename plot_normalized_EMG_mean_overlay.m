function plot_normalized_EMG_mean_overlay(NormalizedCycles, assessment_labels, muscle_names, signal_type)

%% --- PLOT NORMALIZED EMG MEAN OVERLAY ---
% This function overlays the mean normalized EMG profiles of T0, T1 and T2.
%
% Each subplot shows one muscle.
% Only mean profiles are plotted, without individual cycles or SD, to keep
% the comparison readable.
%
% signal_type can be:
% - 'rectified'
% - 'envelope'

colors = [ ...
    0.0000 0.4470 0.7410; ...
    0.8500 0.3250 0.0980; ...
    0.4660 0.6740 0.1880];

muscles_per_page = 6;
n_muscles = length(muscle_names);
n_pages = ceil(n_muscles / muscles_per_page);

for page = 1:n_pages

    first_muscle = (page - 1) * muscles_per_page + 1;
    last_muscle = min(page * muscles_per_page, n_muscles);

    figure('Name',['Mean overlay - normalized ' signal_type ' EMG - page ' num2str(page)], ...
           'Units','normalized','Position',[0.08 0.08 0.85 0.8]);

    tl = tiledlayout(3, 2, 'TileSpacing','compact');

    title(tl, ['Mean overlay - normalized ' signal_type ' EMG - page ' num2str(page)]);

    for m = first_muscle:last_muscle

        nexttile
        hold on

        for a = 1:3

            N = NormalizedCycles{a};
            AngBase = N.AngBase;

            if strcmpi(signal_type, 'rectified')
                cycles = N.EMG_rect_good_norm;
            else
                cycles = N.EMG_env_good_norm;
            end

            temp_mat = zeros(length(AngBase), N.n_valid);

            for c = 1:N.n_valid
                temp_mat(:,c) = cycles{c}(:,m);
            end

            mean_profile = mean(temp_mat, 2, 'omitnan');

            plot(AngBase, mean_profile, ...
                'Color', colors(a,:), ...
                'LineWidth', 2, ...
                'DisplayName', assessment_labels{a});

        end

        title(muscle_names{m}, 'Interpreter','none');

        xlabel('Crank angle [deg]');
        ylabel('Normalized amplitude');

        xlim([0 360]);
        xticks([0 90 180 270 360]);

        legend('Location','best');
        grid on

    end
end

end