function G = select_good_cycles(CycleInfo, target_cadence, cadence_tolerance, max_good_cycles, assessment_label)

%% --- SELECT GOOD CYCLES ---
% This function selects cycles whose trike-based cadence falls within the
% target cadence range.
%
% The selected cycle indices are later used for both EMG and trike metrics,
% so the two analyses remain based on the same cycles.

cadence = CycleInfo.cadence;

good_cycles = find(cadence >= target_cadence - cadence_tolerance & ...
                   cadence <= target_cadence + cadence_tolerance);

% Optional: keep only the central subset if a maximum number is imposed.
if ~isinf(max_good_cycles) && length(good_cycles) > max_good_cycles

    start_idx = floor((length(good_cycles) - max_good_cycles) / 2) + 1;
    good_cycles = good_cycles(start_idx : start_idx + max_good_cycles - 1);

end

G.label = assessment_label;
G.good_cycles = good_cycles;
G.n_valid = length(good_cycles);

G.target_cadence = target_cadence;
G.cadence_tolerance = cadence_tolerance;

fprintf('%s - good cycles selected: %d\n', assessment_label, G.n_valid);

end