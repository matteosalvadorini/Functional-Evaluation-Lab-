function T = compute_timing_analysis(N, muscle_names, assessment_label)

%% --- TIMING ANALYSIS FROM EMG ENVELOPE ---
% This function extracts timing information from the normalized EMG envelope.
%
% To keep the analysis robust and simple, timing is described only through
% peak timing and peak amplitude.
%
% Onset, offset and burst duration are not computed here because they depend
% strongly on threshold selection, especially in post-stroke EMG profiles.
%
% Peak timing is an angular variable on a 0-359° cycle, so circular mean and
% circular standard deviation are used.

EMG_env_good_norm = N.EMG_env_good_norm;
AngBase = N.AngBase;
n_valid = N.n_valid;

n_muscles = length(muscle_names);

peak_angle = NaN(n_valid,n_muscles);
peak_amplitude = NaN(n_valid,n_muscles);


%% --- EXTRACT PEAK TIMING AND AMPLITUDE ---

for c = 1:n_valid

    cycle_env = EMG_env_good_norm{c};

    for m = 1:n_muscles

        [peak_amplitude(c,m), idx_peak] = max(cycle_env(:,m));
        peak_angle(c,m) = AngBase(idx_peak);

    end

end


%% --- CIRCULAR MEAN AND CIRCULAR SD FOR PEAK TIMING ---

peak_mean = NaN(1,n_muscles);
peak_std  = NaN(1,n_muscles);

for m = 1:n_muscles

    angles = peak_angle(:,m);
    angles = angles(~isnan(angles));

    if ~isempty(angles)

        angles_rad = deg2rad(angles);
        mean_vector = mean(exp(1i * angles_rad));

        peak_mean(m) = mod(rad2deg(angle(mean_vector)), 360);

        mean_resultant_length = abs(mean_vector);
        mean_resultant_length = min(max(mean_resultant_length, eps), 1);

        peak_std(m) = rad2deg(sqrt(-2 * log(mean_resultant_length)));

    end

end


%% --- LINEAR MEAN AND SD FOR PEAK AMPLITUDE ---

peak_amp_mean = mean(peak_amplitude, 1, 'omitnan');
peak_amp_std  = std(peak_amplitude, 0, 1, 'omitnan');


%% --- SUMMARY TABLE ---

TimingSummary = table(muscle_names', ...
    peak_mean', peak_std', ...
    peak_amp_mean', peak_amp_std', ...
    'VariableNames', {'Muscle', ...
    'PeakTimingMean_deg', ...
    'PeakTimingCircularSD_deg', ...
    'PeakAmpMean', ...
    'PeakAmpSD'});


%% --- OUTPUT ---

T.label = assessment_label;

T.peak_angle = peak_angle;
T.peak_amplitude = peak_amplitude;

T.peak_mean = peak_mean;
T.peak_std = peak_std;

T.peak_amp_mean = peak_amp_mean;
T.peak_amp_std = peak_amp_std;

T.TimingSummary = TimingSummary;


%% --- DISPLAY ---

fprintf('\n--- TIMING ANALYSIS RESULTS: %s ---\n', assessment_label);
disp(TimingSummary);

end