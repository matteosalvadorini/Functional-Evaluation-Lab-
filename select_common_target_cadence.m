function [common_target_cadence, cadence_selection] = select_common_target_cadence(CycleInfo, possible_target_cadences, cadence_tolerance)

%% --- SELECT COMMON TARGET CADENCE ---
% This function tests a range of possible target cadences and selects one
% common cadence for T0, T1 and T2.
%
% For each candidate cadence, it counts how many cycles fall within the
% cadence tolerance in each assessment.
%
% The selected cadence maximizes the number of comparable cycles, giving
% priority to the assessment with the lowest number of good cycles.

best_score = -Inf;

for i = 1:length(possible_target_cadences)

    target_candidate = possible_target_cadences(i);
    counts = zeros(1,3);

    for a = 1:3

        cadence = CycleInfo{a}.cadence;

        counts(a) = sum(cadence >= target_candidate - cadence_tolerance & ...
                        cadence <= target_candidate + cadence_tolerance);

    end

    score = min(counts);

    if score > best_score

        best_score = score;
        common_target_cadence = target_candidate;
        best_counts = counts;

    end

end

cadence_selection.best_score = best_score;
cadence_selection.best_counts = best_counts;
cadence_selection.cadence_tolerance = cadence_tolerance;

end