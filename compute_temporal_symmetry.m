function TS = compute_temporal_symmetry(Timing, pair_names_short, assessment_label)

%% --- TEMPORAL SYMMETRY ANALYSIS ---
% This function computes right-left temporal symmetry from peak timing.
%
% During pedaling, left and right homologous muscles are expected to work
% approximately 180° out of phase. Therefore, left-side peak timing is shifted
% by 180° before being compared with right-side peak timing.
%
% Lower peak timing error means better temporal symmetry.

peak_angle = Timing.peak_angle;

n_valid = size(peak_angle,1);
n_pairs = length(pair_names_short);

TimingSym_Peak = NaN(n_valid,n_pairs);


%% --- PEAK TIMING SYMMETRY ERROR ---

for k = 1:n_pairs

    R_idx = k;
    L_idx = k + n_pairs;

    shifted_peak_L = mod(peak_angle(:,L_idx) + 180, 360);

    diff_peak = mod(peak_angle(:,R_idx) - shifted_peak_L + 180, 360) - 180;

    TimingSym_Peak(:,k) = abs(diff_peak);

end


%% --- SUMMARY ---

TimingSym_Peak_mean = mean(TimingSym_Peak, 1, 'omitnan');

T_TimingSym = table(pair_names_short', TimingSym_Peak_mean', ...
    'VariableNames', {'MusclePair','PeakTimingSymError_deg'});


%% --- OUTPUT ---

TS.label = assessment_label;

TS.TimingSym_Peak = TimingSym_Peak;
TS.TimingSym_Peak_mean = TimingSym_Peak_mean;

TS.TimingScore = TimingSym_Peak_mean;

TS.T_TimingSym = T_TimingSym;


%% --- DISPLAY ---

fprintf('\n--- TEMPORAL SYMMETRY RESULTS: %s ---\n', assessment_label);
disp(T_TimingSym);

end