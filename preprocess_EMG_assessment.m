function P = preprocess_EMG_assessment(data_resampled, target, assessment_label)

%% --- PREPROCESS EMG ASSESSMENT ---
% This function prepares the EMG signals for the following analysis steps.
%
% Input data are converted from structure to matrix. Column 1 is the trigger,
% while columns 2:17 are the 16 EMG channels.
%
% EMG preprocessing:
% 1. band-pass filtering between 20 and 400 Hz
% 2. full-wave rectification
% 3. low-pass filtering at 5 Hz to obtain the linear envelope
%
% The trigger is kept raw and used only for EMG-trike synchronization.

data_array = struct2array(data_resampled);

trig_raw = data_array(:,1);
emg_raw  = data_array(:,2:17);

fs_EMG = target;

n_samples = size(data_array,1);
t = (0:n_samples-1)' / fs_EMG;


%% --- BAND-PASS FILTER ---

bandpass_range = [20 400];
Wn = bandpass_range / (fs_EMG/2);

[b_bp, a_bp] = butter(5, Wn, 'bandpass');

emg_filt = filtfilt(b_bp, a_bp, emg_raw);


%% --- RECTIFICATION AND ENVELOPE ---

emg_rect = abs(emg_filt);

envelope_cutoff = 5;
Wenv = envelope_cutoff / (fs_EMG/2);

[b_env, a_env] = butter(4, Wenv, 'low');

emg_env = filtfilt(b_env, a_env, emg_rect);


%% --- OUTPUT ---

P.label = assessment_label;

P.trig_raw = trig_raw;
P.emg_filt = emg_filt;
P.emg_rect = emg_rect;
P.emg_env  = emg_env;

P.fs_EMG = fs_EMG;
P.t = t;
P.n_samples = n_samples;

end