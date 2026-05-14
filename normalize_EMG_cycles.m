function N = normalize_EMG_cycles(P, CycleInfo, GoodCycleInfo, AngBase)

%% --- NORMALIZE EMG CYCLES ---
% This function extracts the selected good cycles from rectified EMG and EMG
% envelope signals.
%
% Each cycle is segmented using the trike-based cycle boundaries and then
% resampled to the same 0-359° angular reference.
%
% Amplitude normalization is performed muscle by muscle using the median
% peak value across good cycles.
%
% Rectified EMG will be used for iEMG.
% EMG envelope will be used for CCI and timing analysis.

emg_rect = P.emg_rect;
emg_env  = P.emg_env;

locs_cycle = CycleInfo.locs_trig;
good_cycles = GoodCycleInfo.good_cycles;

n_valid = GoodCycleInfo.n_valid;
n_points = length(AngBase);
n_muscles = size(emg_rect, 2);

rect_good = cell(n_valid,1);
env_good  = cell(n_valid,1);

rect_peaks = zeros(n_valid,n_muscles);
env_peaks  = zeros(n_valid,n_muscles);


%% --- TIME NORMALIZATION ---

for i = 1:n_valid

    cyc = good_cycles(i);

    idx_start = locs_cycle(cyc);
    idx_end   = locs_cycle(cyc+1) - 1;

    rect_cycle = emg_rect(idx_start:idx_end, :);
    env_cycle  = emg_env(idx_start:idx_end, :);

    x_old = linspace(0,359,size(rect_cycle,1));

    rect_norm_time = zeros(n_points,n_muscles);
    env_norm_time  = zeros(n_points,n_muscles);

    for m = 1:n_muscles

        rect_norm_time(:,m) = interp1(x_old, rect_cycle(:,m), AngBase, 'spline');
        env_norm_time(:,m)  = interp1(x_old, env_cycle(:,m),  AngBase, 'spline');

        rect_peaks(i,m) = max(rect_norm_time(:,m));
        env_peaks(i,m)  = max(env_norm_time(:,m));

    end

    rect_good{i} = rect_norm_time;
    env_good{i}  = env_norm_time;

end


%% --- AMPLITUDE NORMALIZATION ---

rect_norm_factor = median(rect_peaks, 1);
env_norm_factor  = median(env_peaks, 1);

rect_norm_factor(rect_norm_factor == 0) = 1;
env_norm_factor(env_norm_factor == 0) = 1;

EMG_rect_good_norm = cell(n_valid,1);
EMG_env_good_norm  = cell(n_valid,1);

for i = 1:n_valid

    EMG_rect_good_norm{i} = rect_good{i} ./ rect_norm_factor;
    EMG_env_good_norm{i}  = env_good{i}  ./ env_norm_factor;

end


%% --- OUTPUT ---

N.label = P.label;

N.EMG_rect_good_norm = EMG_rect_good_norm;
N.EMG_env_good_norm  = EMG_env_good_norm;

N.AngBase = AngBase;
N.good_cycles = good_cycles;
N.n_valid = n_valid;

end