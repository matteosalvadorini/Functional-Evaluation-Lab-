function S = synchronize_EMG_trike(P, CycleInfo, datatrike, fs_trike, assessment_label)

%% --- SYNCHRONIZE EMG AND TRIKE DATA ---
% This function aligns EMG and trike recordings using:
% - the first detected EMG trigger peak as EMG start
% - the first trike crank-angle reset as trike start
%
% After synchronization, both signals are expressed from their own time zero.
% The EMG trigger is kept only to visually check synchronization quality.
% Final cycle segmentation is performed later using trike crank-angle resets.

%% --- 1. DEFINE SYNCHRONIZATION STARTS ---

idx_emg_start = CycleInfo.locs_trig(1);
idx_trike_start = find(diff(datatrike.angle) < -300, 1) + 1;


%% --- 2. CUT EMG TRIGGER ---

trig_sync = P.trig_raw(idx_emg_start:end);
t_emg_sync = (0:length(trig_sync)-1)' / P.fs_EMG;

locs_emg_sync = CycleInfo.locs_trig - idx_emg_start + 1;


%% --- 3. CUT TRIKE SIGNALS ---

S.trike.angle = datatrike.angle(idx_trike_start:end);
S.trike.cadence = datatrike.cadence(idx_trike_start:end);
S.trike.linearVelocity = datatrike.linearVelocity(idx_trike_start:end);
S.trike.powerLeft = datatrike.powerLeft(idx_trike_start:end);
S.trike.powerRight = datatrike.powerRight(idx_trike_start:end);
S.trike.totalDistance = datatrike.totalDistance(idx_trike_start:end);

t_trike_sync = (0:length(S.trike.angle)-1)' / fs_trike;

locs_trike_sync = [1; find(diff(S.trike.angle) < -300) + 1];


%% --- 4. OUTPUT ---

S.label = assessment_label;
S.idx_trike_start = idx_trike_start;
S.idx_emg_start = idx_emg_start;

S.trig_sync = trig_sync;
S.t_emg_sync = t_emg_sync;
S.locs_emg_sync = locs_emg_sync;

S.t_trike_sync = t_trike_sync;
S.locs_trike_sync = locs_trike_sync;

S.fs_EMG = P.fs_EMG;

fprintf('%s - EMG trigger cycles after sync: %d\n', ...
    assessment_label, length(locs_emg_sync)-1);

fprintf('%s - TRIKE cycles after sync: %d\n', ...
    assessment_label, length(locs_trike_sync)-1);

end