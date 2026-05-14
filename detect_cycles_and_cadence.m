function C = detect_cycles_and_cadence(P)

%% --- DETECT EMG TRIGGER EVENTS ---
% This function detects trigger peaks in the EMG signal.
%
% In this pipeline, EMG triggers are used only to synchronize EMG and trike
% recordings. Final cycle segmentation is based on trike crank angle resets.
%
% Trigger-based cadence is saved only as a diagnostic value.

trig_raw = P.trig_raw;
t = P.t;
fs_EMG = P.fs_EMG;

%% --- TRIGGER PEAKS ---

trig_thresh = 0.1 * max(trig_raw);
min_peak_distance = round(fs_EMG * 0.5);

[~, locs_trig] = findpeaks(trig_raw, ...
    'MinPeakHeight', trig_thresh, ...
    'MinPeakDistance', min_peak_distance);

%% --- TRIGGER-BASED CADENCE ---

cycle_duration = diff(t(locs_trig));
cadence = 60 ./ cycle_duration;

%% --- OUTPUT ---

C.label = P.label;

C.locs_trig = locs_trig;
C.cycle_duration = cycle_duration;
C.cadence = cadence;
C.n_cycles_total = length(cadence);

fprintf('%s - EMG trigger events detected: %d\n', ...
    P.label, length(locs_trig));

end