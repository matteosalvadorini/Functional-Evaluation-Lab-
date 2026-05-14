function Fatigue = analyze_fatigue_effects(Results, CycleInfo, GoodCycleInfo, assessment_labels, do_plots)

%% --- FATIGUE EFFECT ANALYSIS ---
% This function checks whether the main EMG indicators change within each
% assessment from early to middle to late cycles.
%
% The aim is not to prove fatigue, but to verify whether changes across the
% test could act as a possible confounding factor.
%
% Each assessment is divided into three equal blocks:
% early, middle and late.

if nargin < 5
    do_plots = true;
end

block_names = {'Early','Middle','Late'};
n_blocks = 3;

Fatigue = cell(1,3);


%% --- COMPUTE EARLY / MIDDLE / LATE METRICS ---

for a = 1:3

    label = assessment_labels{a};

    iEMG = Results{a}.Activation.iEMG;
    SI_global_iEMG = Results{a}.Activation.SI_global_iEMG;
    CCI_env = Results{a}.CCI.CCI_env;
    peak_angle = Results{a}.Timing.peak_angle;

    good_cycles = GoodCycleInfo{a}.good_cycles;
    cadence_good = CycleInfo{a}.cadence(good_cycles);

    n_valid = size(iEMG,1);

    block_idx = { ...
        1:floor(n_valid/3), ...
        floor(n_valid/3)+1:floor(2*n_valid/3), ...
        floor(2*n_valid/3)+1:n_valid};

    total_iEMG_mean = NaN(1,n_blocks);
    global_SI_abs_mean = NaN(1,n_blocks);
    CCI_mean_all = NaN(1,n_blocks);
    peak_circular_SD_mean = NaN(1,n_blocks);
    cadence_mean = NaN(1,n_blocks);
    cadence_std = NaN(1,n_blocks);

    for b = 1:n_blocks

        idx = block_idx{b};

        current_iEMG = iEMG(idx,:);
        current_CCI = CCI_env(idx,:);
        current_peak_angle = peak_angle(idx,:);
        current_cadence = cadence_good(idx);

        right_total = sum(current_iEMG(:,1:8), 2);
        left_total  = sum(current_iEMG(:,9:16), 2);
        total_iEMG  = right_total + left_total;

        total_iEMG_mean(b) = mean(total_iEMG, 'omitnan');
        global_SI_abs_mean(b) = mean(abs(SI_global_iEMG(idx)), 'omitnan');
        CCI_mean_all(b) = mean(current_CCI, 'all', 'omitnan');

        peak_SD_muscle = NaN(1,size(current_peak_angle,2));

        for m = 1:size(current_peak_angle,2)

            angles = current_peak_angle(:,m);
            angles = angles(~isnan(angles));

            if ~isempty(angles)

                angles_rad = deg2rad(angles);
                mean_vector = mean(exp(1i * angles_rad));

                mean_resultant_length = abs(mean_vector);
                mean_resultant_length = min(max(mean_resultant_length, eps), 1);

                peak_SD_muscle(m) = rad2deg(sqrt(-2 * log(mean_resultant_length)));

            end

        end

        peak_circular_SD_mean(b) = mean(peak_SD_muscle, 'omitnan');

        cadence_mean(b) = mean(current_cadence, 'omitnan');
        cadence_std(b)  = std(current_cadence, 0, 'omitnan');

    end


    %% --- OUTPUT ---

    Fatigue{a}.label = label;
    Fatigue{a}.block_names = block_names;

    Fatigue{a}.total_iEMG_mean = total_iEMG_mean;
    Fatigue{a}.global_SI_abs_mean = global_SI_abs_mean;
    Fatigue{a}.CCI_mean_all = CCI_mean_all;
    Fatigue{a}.peak_circular_SD_mean = peak_circular_SD_mean;
    Fatigue{a}.cadence_mean = cadence_mean;
    Fatigue{a}.cadence_std = cadence_std;

    Fatigue{a}.T_fatigue = table(block_names', ...
        total_iEMG_mean', ...
        global_SI_abs_mean', ...
        CCI_mean_all', ...
        peak_circular_SD_mean', ...
        cadence_mean', ...
        cadence_std', ...
        'VariableNames', {'Block', ...
        'Total_iEMG_mean', ...
        'Global_SI_abs_mean', ...
        'Mean_CCI', ...
        'Mean_PeakTimingCircularSD', ...
        'Cadence_mean', ...
        'Cadence_SD'});

    fprintf('\n--- FATIGUE ANALYSIS: %s ---\n', label);
    disp(Fatigue{a}.T_fatigue);

end


%% --- PLOTS ---

if do_plots

    colors = [ ...
        0.0000 0.4470 0.7410; ...
        0.8500 0.3250 0.0980; ...
        0.4660 0.6740 0.1880];

    x = 1:3;

    figure('Name','Fatigue - Total iEMG', ...
           'Units','normalized','Position',[0.1 0.1 0.75 0.5]);
    hold on
    for a = 1:3
        plot(x, Fatigue{a}.total_iEMG_mean, '-o', ...
            'LineWidth', 2, 'Color', colors(a,:), ...
            'DisplayName', assessment_labels{a});
    end
    xticks(x);
    xticklabels(block_names);
    ylabel('Total iEMG');
    title('Early-middle-late total iEMG');
    legend('Location','best');
    grid on;


    figure('Name','Fatigue - Global SI iEMG', ...
           'Units','normalized','Position',[0.1 0.1 0.75 0.5]);
    hold on
    for a = 1:3
        plot(x, Fatigue{a}.global_SI_abs_mean, '-o', ...
            'LineWidth', 2, 'Color', colors(a,:), ...
            'DisplayName', assessment_labels{a});
    end
    xticks(x);
    xticklabels(block_names);
    ylabel('Global absolute SI iEMG [%]');
    title('Early-middle-late EMG symmetry');
    legend('Location','best');
    grid on;


    figure('Name','Fatigue - Mean CCI', ...
           'Units','normalized','Position',[0.1 0.1 0.75 0.5]);
    hold on
    for a = 1:3
        plot(x, Fatigue{a}.CCI_mean_all, '-o', ...
            'LineWidth', 2, 'Color', colors(a,:), ...
            'DisplayName', assessment_labels{a});
    end
    xticks(x);
    xticklabels(block_names);
    ylabel('Mean CCI');
    title('Early-middle-late co-contraction');
    legend('Location','best');
    grid on;


    figure('Name','Fatigue - Peak Timing Circular SD', ...
           'Units','normalized','Position',[0.1 0.1 0.75 0.5]);
    hold on
    for a = 1:3
        plot(x, Fatigue{a}.peak_circular_SD_mean, '-o', ...
            'LineWidth', 2, 'Color', colors(a,:), ...
            'DisplayName', assessment_labels{a});
    end
    xticks(x);
    xticklabels(block_names);
    ylabel('Mean peak timing circular SD [deg]');
    title('Early-middle-late peak timing variability');
    legend('Location','best');
    grid on;


    figure('Name','Fatigue - Cadence', ...
           'Units','normalized','Position',[0.1 0.1 0.75 0.5]);
    hold on
    for a = 1:3
        errorbar(x, Fatigue{a}.cadence_mean, Fatigue{a}.cadence_std, '-o', ...
            'LineWidth', 2, 'Color', colors(a,:), ...
            'DisplayName', assessment_labels{a});
    end
    xticks(x);
    xticklabels(block_names);
    ylabel('Cadence [RPM]');
    title('Early-middle-late cadence stability');
    legend('Location','best');
    grid on;

end

end