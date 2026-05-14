function plot_EMG_signal_comparison_pages(RawData, Preprocessed, assessment_labels, muscle_names, signal_type)

%% --- PLOT EMG SIGNAL COMPARISON PAGES ---
% This function plots intermediate EMG signals across T0, T1 and T2.
%
% Each figure shows 3 muscles.
% Rows = muscles.
% Columns = assessments: T0, T1, T2.
%
% Available signal types:
% 'raw'       -> raw EMG from imported data
% 'filtered'  -> band-pass filtered EMG
% 'rectified' -> rectified EMG
% 'envelope'  -> EMG linear envelope

muscles_per_page = 3;
n_muscles = length(muscle_names);
n_pages = ceil(n_muscles / muscles_per_page);

for page = 1:n_pages

    first_muscle = (page - 1) * muscles_per_page + 1;
    last_muscle = min(page * muscles_per_page, n_muscles);

    figure('Name',[upper(signal_type) ' EMG comparison - page ' num2str(page)], ...
           'Units','normalized','Position',[0.05 0.05 0.9 0.85]);

    tl = tiledlayout(muscles_per_page, 3, 'TileSpacing','compact');

    title(tl, [upper(signal_type) ' EMG comparison - page ' num2str(page)]);

    for m = first_muscle:last_muscle

        row = m - first_muscle + 1;

        for a = 1:3

            nexttile((row - 1) * 3 + a)

            switch lower(signal_type)

                case 'raw'
                    data_array = struct2array(RawData{a});
                    y = data_array(:, m + 1);
                    fs = Preprocessed{a}.fs_EMG;

                case 'filtered'
                    y = Preprocessed{a}.emg_filt(:, m);
                    fs = Preprocessed{a}.fs_EMG;

                case 'rectified'
                    y = Preprocessed{a}.emg_rect(:, m);
                    fs = Preprocessed{a}.fs_EMG;

                case 'envelope'
                    y = Preprocessed{a}.emg_env(:, m);
                    fs = Preprocessed{a}.fs_EMG;

            end

            t = (0:length(y)-1)' / fs;

            plot(t, y, 'LineWidth', 0.8);

            title([assessment_labels{a} ' - ' muscle_names{m}], ...
                'Interpreter','none');

            xlabel('Time [s]');
            ylabel('Amplitude');
            grid on

        end
    end
end

end