function A = compute_activation_symmetry(N, muscle_names, pair_names_short, assessment_label)

%% --- ACTIVATION AND iEMG SYMMETRY ANALYSIS ---
% This function computes total muscle activation and right-left activation
% symmetry from normalized rectified EMG.
%
% For each good cycle and muscle, iEMG is computed as the area under the
% rectified EMG curve over the 0-359° cycle.
%
% iEMG values are then used to compute:
% - muscle-specific right-left symmetry index
% - global right-left symmetry index

EMG_rect_good_norm = N.EMG_rect_good_norm;
AngBase = N.AngBase;
n_valid = N.n_valid;

n_muscles = length(muscle_names);
n_pairs = length(pair_names_short);


%% --- iEMG PER CYCLE AND MUSCLE ---

iEMG = zeros(n_valid, n_muscles);

for c = 1:n_valid

    cycle_rect = EMG_rect_good_norm{c};

    for m = 1:n_muscles
        iEMG(c,m) = trapz(AngBase, cycle_rect(:,m));
    end

end

mean_iEMG = mean(iEMG, 1);


%% --- MUSCLE-SPECIFIC SYMMETRY INDEX ---

SI_iEMG = zeros(n_valid, n_pairs);

for k = 1:n_pairs

    right_iEMG = iEMG(:,k);
    left_iEMG  = iEMG(:,k+n_pairs);

    SI_iEMG(:,k) = ((right_iEMG - left_iEMG) ./ ...
                   (0.5 * (right_iEMG + left_iEMG))) * 100;

end

SI_iEMG_mean = mean(SI_iEMG, 1);
SI_iEMG_abs_mean = mean(abs(SI_iEMG), 1);


%% --- GLOBAL SYMMETRY INDEX ---

iEMG_right_total = sum(iEMG(:,1:n_pairs), 2);
iEMG_left_total  = sum(iEMG(:,n_pairs+1:end), 2);

SI_global_iEMG = ((iEMG_right_total - iEMG_left_total) ./ ...
                 (0.5 * (iEMG_right_total + iEMG_left_total))) * 100;

SI_global_iEMG_mean = mean(SI_global_iEMG);
SI_global_iEMG_abs_mean = mean(abs(SI_global_iEMG));


%% --- OUTPUT TABLES ---

T_activation = table(muscle_names', mean_iEMG', ...
    'VariableNames', {'Muscle','Mean_iEMG'});

T_SI = table(pair_names_short', SI_iEMG_mean', SI_iEMG_abs_mean', ...
    'VariableNames', {'MusclePair','SI_iEMG_mean','SI_iEMG_abs_mean'});


%% --- OUTPUT ---

A.label = assessment_label;

A.iEMG = iEMG;
A.mean_iEMG = mean_iEMG;

A.SI_iEMG = SI_iEMG;
A.SI_iEMG_mean = SI_iEMG_mean;
A.SI_iEMG_abs_mean = SI_iEMG_abs_mean;

A.SI_global_iEMG = SI_global_iEMG;
A.SI_global_iEMG_mean = SI_global_iEMG_mean;
A.SI_global_iEMG_abs_mean = SI_global_iEMG_abs_mean;

A.T_activation = T_activation;
A.T_SI = T_SI;


%% --- DISPLAY ---

fprintf('\n--- ACTIVATION AND SYMMETRY RESULTS: %s ---\n', assessment_label);
disp(T_activation);
disp(T_SI);

fprintf('Global SI iEMG mean: %.2f %%\n', SI_global_iEMG_mean);
fprintf('Global SI iEMG absolute mean: %.2f %%\n', SI_global_iEMG_abs_mean);

end