function C = build_trike_based_cycle_info(S)

%% --- BUILD TRIKE-BASED CYCLE INFO ---
% This function defines pedaling cycles from the trike crank-angle resets.
%
% The reset times are converted into EMG sample indices, so that EMG signals
% can be segmented using the same mechanical cycles measured by the trike.
%
% Abnormal cycles with unrealistic cadence are removed before the final
% cadence vector is saved.

%% --- TRIKE RESET TIMES ---

locs_trike = S.locs_trike_sync;
t_trike_resets = S.t_trike_sync(locs_trike);


%% --- CONVERT TRIKE RESET TIMES INTO EMG INDICES ---

locs_emg_sync_from_trike = round(t_trike_resets * S.fs_EMG) + 1;
locs_emg_full_from_trike = S.idx_emg_start + locs_emg_sync_from_trike - 1;

%% --- REMOVE TRIKE BOUNDARIES OUTSIDE EMG SIGNAL ---

max_emg_idx = S.idx_emg_start + length(S.t_emg_sync) - 1;

valid_boundaries = locs_emg_full_from_trike >= 1 & ...
                   locs_emg_full_from_trike <= max_emg_idx;

locs_trike = locs_trike(valid_boundaries);
t_trike_resets = t_trike_resets(valid_boundaries);
locs_emg_full_from_trike = locs_emg_full_from_trike(valid_boundaries);


%% --- REMOVE ABNORMAL CADENCE CYCLES ---

cycle_duration = diff(t_trike_resets);
cadence = 60 ./ cycle_duration;

min_cadence_allowed = 10;
max_cadence_allowed = 80;

valid_cycles = cadence >= min_cadence_allowed & cadence <= max_cadence_allowed;

% If cycle i is invalid, remove boundary i+1.
valid_boundaries = [true; valid_cycles(:)];

locs_trike = locs_trike(valid_boundaries);
t_trike_resets = t_trike_resets(valid_boundaries);
locs_emg_full_from_trike = locs_emg_full_from_trike(valid_boundaries);

cycle_duration = diff(t_trike_resets);
cadence = 60 ./ cycle_duration;


%% --- OUTPUT ---
% locs_trig keeps this structure compatible with the EMG functions,
% even if the cycle boundaries now come from the trike.

C.label = S.label;

C.locs_trig = locs_emg_full_from_trike;
C.locs_trike = locs_trike;

C.t_trike_resets = t_trike_resets;
C.cycle_duration = cycle_duration;
C.cadence = cadence;

C.n_cycles_total = length(cadence);

fprintf('%s - trike-based cycles: %d\n', S.label, C.n_cycles_total);

end