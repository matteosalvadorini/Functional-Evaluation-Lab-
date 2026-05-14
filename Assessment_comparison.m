clearvars
close all
clc

%% --- MAIN SCRIPT: EMG-TRIKE T0-T1-T2 COMPARISON ---
% Pipeline:
% 1) import EMG and trike data
% 2) preprocess EMG
% 3) synchronize EMG and trike
% 4) segment cycles using trike crank angle
% 5) select good cycles based on target cadence
% 6) compute EMG, trike and integrated EMG-trike metrics
% 7) plot selected results


%% --- 0. SETTINGS ---

assessment_labels = {'T1','T2','T3'};

cadence_opt = 1;                 % 1 = optimized common cadence, 0 = fixed cadence
fixed_target_cadence = 35;       % Used only if cadence_opt = 0

cadence_tolerance = 4;
possible_target_cadences = 20:0.5:60;
max_good_cycles = Inf;

fs_trike = 100;
min_total_power = 1;

AngBase = linspace(0,359,360);

% Plot flags
plot_sync_quality               = true;
plot_good_cycles                = true;
plot_trike_power_cycles         = true;

plot_emg_results                = true;
plot_trike_results              = true;
plot_integrated_results         = true;
plot_final_scatter              = true;
plot_fatigue_results            = true;

plot_raw_emg_exploration        = false;
plot_filtered_emg_exploration   = false;
plot_rectified_emg_exploration  = false;
plot_envelope_emg_exploration   = false;
plot_normalized_emg_exploration = false;
plot_norm_profiles_exploration  = false;
plot_norm_mean_overlay          = false;
plot_example_cycle_exploration  = false;
plot_directional_symmetry       = true;


%% --- 1. CHANNELS AND MUSCLE PAIRS ---

channels = {'Trigger', ...
    'Tibialis Ant R', 'Gastro Lat R', 'Soleus R', 'Gastro Med R', ...
    'Rectus R', 'Vastus Med R', 'Vastus Lat R', 'Semitendinous R', ...
    'Tibialis Ant L', 'Gastro Lat L', 'Soleus L', 'Gastro Med L', ...
    'Rectus L', 'Vastus Med L', 'Vastus Lat L', 'Semitendinous L'};

muscle_names = channels(2:17);

pair_names_short = {'TA','Gastro Lat','Soleus','Gastro Med', ...
                    'Rectus','Vastus Med','Vastus Lat','Semitendinous'};

cci_pairs = [ ...
    1 2;
    1 3;
    5 8;
    9 10;
    9 11;
    13 16];

cci_pair_names = { ...
    'TA_R vs GastroLat_R', ...
    'TA_R vs Soleus_R', ...
    'Rectus_R vs Semitend_R', ...
    'TA_L vs GastroLat_L', ...
    'TA_L vs Soleus_L', ...
    'Rectus_L vs Semitend_L'};


%% --- 2. STORAGE ---

RawData = cell(1,3);
Fs = cell(1,3);
Filename = cell(1,3);

TrikeData = cell(1,3);
TrikeFilename = cell(1,3);

Preprocessed = cell(1,3);
CycleInfo = cell(1,3);
Synced = cell(1,3);
TrikeCycleInfo = cell(1,3);
GoodCycleInfo = cell(1,3);
NormalizedCycles = cell(1,3);

Activation = cell(1,3);
CCI = cell(1,3);
Timing = cell(1,3);
TemporalSymmetry = cell(1,3);
TrikeMetrics = cell(1,3);

Results = cell(1,3);


%% --- 3. IMPORT EMG AND TRIKE FILES ---

for a = 1:3

    fprintf('\nSelect EMG CSV file for %s\n', assessment_labels{a});
    [RawData{a}, Fs{a}, Filename{a}] = import_EMG_data_function();

    fprintf('\nSelect TRIKE CSV file for %s\n', assessment_labels{a});
    [TrikeData{a}, TrikeFilename{a}] = import_trike_data_function();

end


%% --- 4. PREPROCESS EMG AND DETECT EMG TRIGGERS ---
% EMG signals are filtered, rectified and converted into envelopes.
% Trigger peaks are detected only to synchronize EMG with trike data;
% final cycle segmentation will be based on trike crank angle.

for a = 1:3

    fprintf('\nPreprocessing EMG for %s\n', assessment_labels{a});

    Preprocessed{a} = preprocess_EMG_assessment( ...
        RawData{a}, ...
        Fs{a}, ...
        assessment_labels{a});

    fprintf('\nDetecting EMG trigger events for %s\n', assessment_labels{a});

    CycleInfo{a} = detect_cycles_and_cadence(Preprocessed{a});

end


%% --- 5. SYNCHRONIZE EMG AND TRIKE ---
% The first EMG trigger and the first trike crank-angle reset are used to
% align the two recordings in time. After this step, EMG and trike signals
% share a common synchronized time reference.

for a = 1:3

    fprintf('\nSynchronizing EMG and TRIKE for %s\n', assessment_labels{a});

    Synced{a} = synchronize_EMG_trike( ...
        Preprocessed{a}, ...
        CycleInfo{a}, ...
        TrikeData{a}, ...
        fs_trike, ...
        assessment_labels{a});

end

if plot_sync_quality
    plot_EMG_trike_sync_quality(Synced, assessment_labels);
end


%% --- 6. BUILD TRIKE-BASED CYCLE INFO ---
% Crank-angle resets are converted into EMG sample indices.
% From this point on, pedaling cycles are defined mechanically from the trike,
% not from the EMG trigger.

for a = 1:3

    fprintf('\nBuilding trike-based cycle info for %s\n', assessment_labels{a});

    TrikeCycleInfo{a} = build_trike_based_cycle_info(Synced{a});

end


%% --- 7. SELECT TARGET CADENCE ---
% The analysis can use either:
% - an optimized common cadence, selected to maximize comparable good cycles
%   across T0, T1 and T2;
% - a fixed protocol cadence, manually defined in the settings.
%
% In both cases, the same target cadence is then used for all assessments.

if cadence_opt == 1

    [common_target_cadence, cadence_selection] = select_common_target_cadence( ...
        TrikeCycleInfo, ...
        possible_target_cadences, ...
        cadence_tolerance);

    fprintf('\nSelected optimized common target cadence: %.2f RPM\n', common_target_cadence);
    fprintf('Cadence tolerance: ± %.2f RPM\n', cadence_tolerance);
    disp('Good cycle counts for selected cadence:');
    disp(cadence_selection.best_counts);

else

    common_target_cadence = fixed_target_cadence;

    fprintf('\nForced target cadence: %.2f RPM\n', common_target_cadence);
    fprintf('Cadence tolerance: ± %.2f RPM\n', cadence_tolerance);

    for a = 1:3

        cadence = TrikeCycleInfo{a}.cadence;

        n_good_tmp = sum(cadence >= common_target_cadence - cadence_tolerance & ...
                         cadence <= common_target_cadence + cadence_tolerance);

        fprintf('%s - good cycles at %.2f RPM: %d\n', ...
            assessment_labels{a}, common_target_cadence, n_good_tmp);

    end

end


%% --- 8. SELECT GOOD CYCLES ---
% Cycles are selected if their trike-based cadence is within the target
% cadence range. These same good cycles will be used for both EMG and trike
% metrics, so the two analyses remain cycle-matched.

for a = 1:3

    fprintf('\nSelecting good cycles for %s\n', assessment_labels{a});

    GoodCycleInfo{a} = select_good_cycles( ...
        TrikeCycleInfo{a}, ...
        common_target_cadence, ...
        cadence_tolerance, ...
        max_good_cycles, ...
        assessment_labels{a});

end

if plot_good_cycles
    plot_good_cycles_vs_total_cycles( ...
        TrikeCycleInfo, ...
        GoodCycleInfo, ...
        assessment_labels, ...
        common_target_cadence, ...
        cadence_tolerance);
end


%% --- 9. EXTRACT TRIKE CYCLE METRICS ---
% Trike signals are summarized cycle by cycle using the same good cycles
% selected for the EMG analysis. This gives mechanical metrics matched to
% the EMG cycles, such as power, cadence, velocity and distance per cycle.

for a = 1:3

    fprintf('\nExtracting trike cycle metrics for %s\n', assessment_labels{a});

    TrikeMetrics{a} = extract_trike_cycle_metrics( ...
        Synced{a}, ...
        TrikeCycleInfo{a}, ...
        GoodCycleInfo{a});

end

if plot_trike_power_cycles

    for a = 1:3

        fprintf('\nPlotting trike power across cycles for %s\n', assessment_labels{a});

        plot_trike_cycle_power( ...
            Synced{a}, ...
            TrikeCycleInfo{a}, ...
            GoodCycleInfo{a});

    end

end


%% --- 10. NORMALIZE EMG CYCLES ---
% EMG rectified signals and envelopes are segmented using the trike-based
% cycle boundaries. Only good cycles are kept and resampled to the same
% 0-359° angular reference.

for a = 1:3

    fprintf('\nNormalizing EMG cycles for %s\n', assessment_labels{a});

    NormalizedCycles{a} = normalize_EMG_cycles( ...
        Preprocessed{a}, ...
        TrikeCycleInfo{a}, ...
        GoodCycleInfo{a}, ...
        AngBase);

end


%% --- 11. COMPUTE EMG INDICATORS ---
% EMG indicators are computed from the normalized good cycles.
% Rectified EMG is used to quantify total activation and symmetry.
% EMG envelope is used to quantify co-contraction and timing parameters.

for a = 1:3

    fprintf('\nComputing EMG indicators for %s\n', assessment_labels{a});

    Activation{a} = compute_activation_symmetry( ...
        NormalizedCycles{a}, ...
        muscle_names, ...
        pair_names_short, ...
        assessment_labels{a});

    CCI{a} = compute_CCI( ...
        NormalizedCycles{a}, ...
        cci_pairs, ...
        cci_pair_names, ...
        assessment_labels{a});

    Timing{a} = compute_timing_analysis( ...
        NormalizedCycles{a}, ...
        muscle_names, ...
        assessment_labels{a});

    TemporalSymmetry{a} = compute_temporal_symmetry( ...
        Timing{a}, ...
        pair_names_short, ...
        assessment_labels{a});

end


%% --- 12. COLLECT RESULTS ---
% All EMG, trike and metadata outputs are stored in one Results structure
% for each assessment. This makes the following comparison and plotting
% functions easier to call.

for a = 1:3

    Results{a}.label = assessment_labels{a};

    Results{a}.emg_filename = Filename{a};
    Results{a}.trike_filename = TrikeFilename{a};

    Results{a}.target_cadence = common_target_cadence;
    Results{a}.cadence_tolerance = cadence_tolerance;
    Results{a}.n_good_cycles = GoodCycleInfo{a}.n_valid;

    Results{a}.muscle_names = muscle_names;
    Results{a}.pair_names_short = pair_names_short;
    Results{a}.cci_pair_names = cci_pair_names;

    Results{a}.Activation = Activation{a};
    Results{a}.CCI = CCI{a};
    Results{a}.Timing = Timing{a};
    Results{a}.TemporalSymmetry = TemporalSymmetry{a};
    Results{a}.TrikeMetrics = TrikeMetrics{a};

end


%% --- 13. COMPUTE EMG-TRIKE RELATIONSHIP ---
% EMG and trike metrics are combined cycle by cycle.
% This allows us to compare muscle activation with mechanical output,
% especially right-side power contribution and global EMG cost.

EMGTrikeRelationship = compute_EMG_trike_relationship( ...
    Results, ...
    assessment_labels, ...
    min_total_power);

for a = 1:3
    Results{a}.EMGTrikeRelationship = EMGTrikeRelationship{a};
end


%% --- 14. PLOTS ---
% Plot order follows the analysis pipeline:
% 1) exploratory signal quality
% 2) cycle selection and normalized EMG profiles
% 3) EMG-only results
% 4) trike-only results
% 5) integrated EMG-trike results
% 6) fatigue check


%% --- 14A. EXPLORATORY EMG SIGNAL QUALITY PLOTS ---

% Plots raw EMG signals before preprocessing.
% Each page shows 3 muscles, with rows representing muscles and columns representing T0, T1 and T2.
% This is used only to visually inspect the original imported EMG quality.
if plot_raw_emg_exploration

    plot_EMG_signal_comparison_pages( ...
        RawData, ...
        Preprocessed, ...
        assessment_labels, ...
        muscle_names, ...
        'raw');

end


% Plots band-pass filtered EMG signals.
% Each page shows 3 muscles, with rows representing muscles and columns representing T0, T1 and T2.
% This is used to visually check the effect of the 20-400 Hz EMG filtering step.
if plot_filtered_emg_exploration

    plot_EMG_signal_comparison_pages( ...
        RawData, ...
        Preprocessed, ...
        assessment_labels, ...
        muscle_names, ...
        'filtered');

end


% Plots rectified EMG signals.
% Each page shows 3 muscles, with rows representing muscles and columns representing T0, T1 and T2.
% This is used to inspect the signal after full-wave rectification, before envelope extraction.
if plot_rectified_emg_exploration

    plot_EMG_signal_comparison_pages( ...
        RawData, ...
        Preprocessed, ...
        assessment_labels, ...
        muscle_names, ...
        'rectified');

end


% Plots EMG linear envelopes.
% Each page shows 3 muscles, with rows representing muscles and columns representing T0, T1 and T2.
% This is used to inspect the smoothed activation profiles before cycle normalization.
if plot_envelope_emg_exploration

    plot_EMG_signal_comparison_pages( ...
        RawData, ...
        Preprocessed, ...
        assessment_labels, ...
        muscle_names, ...
        'envelope');

end


%% --- 14B. CYCLE SELECTION AND NORMALIZED EMG PROFILE PLOTS ---

% Plots normalized EMG envelope profiles for the selected good cycles.
% Each page shows 3 muscles, with rows representing muscles and columns representing T0, T1 and T2.
% Individual good cycles are shown in gray, while the mean profile and mean ± SD are plotted on top.
% This is used to inspect cycle-to-cycle variability and profile consistency.
if plot_normalized_emg_exploration

    plot_normalized_EMG_profiles_comparison( ...
        NormalizedCycles, ...
        assessment_labels, ...
        muscle_names, ...
        'envelope');

end


% Plots the mean normalized EMG envelope profiles of T0, T1 and T2 overlaid on the same axes.
% Each subplot corresponds to one muscle.
% Only the mean profile is plotted, without individual cycles or SD, to make direct comparison between assessments easier.
if plot_norm_mean_overlay

    plot_normalized_EMG_mean_overlay( ...
        NormalizedCycles, ...
        assessment_labels, ...
        muscle_names, ...
        'envelope');

end


% Plots one representative good cycle for each assessment.
% For each muscle, the middle good cycle is selected.
% Rows represent muscles and columns represent T0, T1 and T2.
% Rectified EMG and EMG envelope are shown together to visually inspect the signal used for analysis.
if plot_example_cycle_exploration

    plot_example_EMG_cycle_comparison( ...
        Preprocessed, ...
        TrikeCycleInfo, ...
        GoodCycleInfo, ...
        assessment_labels, ...
        muscle_names);

end


%% --- 14C. EMG-ONLY RESULT PLOTS ---

% Plots the main EMG-only indicators across T0, T1 and T2:
% 1) mean iEMG for each muscle
% 2) absolute right-left iEMG symmetry index for each homologous muscle pair
% 3) global absolute iEMG symmetry index
% 4) mean co-contraction index for the selected antagonist pairs
% 5) peak timing symmetry error between right and left homologous muscles
% 6) peak timing circular variability for each muscle
if plot_emg_results

    plot_EMG_comparison_results( ...
        Results, ...
        assessment_labels, ...
        muscle_names, ...
        pair_names_short, ...
        cci_pair_names);

end


% Plots the signed iEMG symmetry index for each homologous muscle pair.
% Positive values indicate greater right-side activation.
% Negative values indicate greater left-side activation.
% This complements the absolute symmetry index by showing the direction of the asymmetry.
if plot_directional_symmetry

    plot_directional_EMG_symmetry( ...
        Results, ...
        assessment_labels, ...
        pair_names_short);

end


%% --- 14D. TRIKE-ONLY RESULT PLOTS ---

% Plots the main trike-only mechanical indicators across T0, T1 and T2:
% 1) mean right, left and total power during good cycles
% 2) right and left contribution to total power
% 3) fraction of non-zero right, left and total power samples
% 4) absolute power symmetry index
% 5) cadence, velocity and distance per cycle as contextual mechanical variables
if plot_trike_results

    plot_trike_comparison_results( ...
        Results, ...
        assessment_labels);

end


%% --- 14E. INTEGRATED EMG-TRIKE RESULT PLOTS ---

% Plots integrated EMG-trike summary indicators across T0, T1 and T2:
% 1) right/left mechanical involvement, using power contribution and power non-zero fraction
% 2) global EMG asymmetry and mean CCI on the same figure
% 3) total mechanical power, total iEMG and global EMG cost
if plot_integrated_results

    plot_EMG_trike_integrated_summary( ...
        EMGTrikeRelationship, ...
        assessment_labels);

end


% Plots cycle-by-cycle EMG-trike relationships:
% 1) right iEMG versus right power
% 2) left iEMG versus left power
% 3) total iEMG versus total power
% 4) right/left power contribution versus global EMG asymmetry
% 5) right/left power distributions
% 6) side-specific mechanical involvement summaries
%
% Scatter plots include one point per good cycle and the centroid of each assessment.
if plot_final_scatter

    plot_EMG_trike_final_relationships( ...
        EMGTrikeRelationship, ...
        assessment_labels);

end


%% --- 14F. FATIGUE CHECK PLOTS ---

% Plots early-middle-late trends within each assessment to check possible fatigue effects:
% 1) total iEMG across the test
% 2) global EMG symmetry across the test
% 3) mean CCI across the test
% 4) peak timing circular variability across the test
% 5) cadence stability across the test
if plot_fatigue_results

    Fatigue = analyze_fatigue_effects( ...
        Results, ...
        TrikeCycleInfo, ...
        GoodCycleInfo, ...
        assessment_labels, ...
        true);

end


fprintf('\nEMG-TRIKE T0-T1-T2 analysis completed.\n');