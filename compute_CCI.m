function CCI = compute_CCI(N, cci_pairs, cci_pair_names, assessment_label)

%% --- CO-CONTRACTION INDEX ANALYSIS ---
% This function computes the co-contraction index from the normalized EMG
% envelope.
%
% For each good cycle and each selected antagonist muscle pair, CCI is
% computed as:
%
% CCI = 2 * sum(min(E1,E2)) / (sum(E1) + sum(E2))
%
% where E1 and E2 are the two envelope profiles.
% Higher values indicate greater overlap between the two muscle activations.

EMG_env_good_norm = N.EMG_env_good_norm;

n_valid = N.n_valid;
n_pairs = size(cci_pairs,1);

CCI_env = zeros(n_valid, n_pairs);


%% --- COMPUTE CCI ---

for c = 1:n_valid

    cycle_env = EMG_env_good_norm{c};

    for p = 1:n_pairs

        m1 = cci_pairs(p,1);
        m2 = cci_pairs(p,2);

        E1 = cycle_env(:,m1);
        E2 = cycle_env(:,m2);

        numerator = 2 * sum(min(E1,E2));
        denominator = sum(E1) + sum(E2);

        if denominator == 0
            CCI_env(c,p) = NaN;
        else
            CCI_env(c,p) = numerator / denominator;
        end

    end

end


%% --- SUMMARY ---

CCI_env_mean = mean(CCI_env, 1, 'omitnan');
CCI_env_std  = std(CCI_env, 0, 1, 'omitnan');

T_CCI = table(cci_pair_names', CCI_env_mean', CCI_env_std', ...
    'VariableNames', {'MusclePair','CCI_env_mean','CCI_env_std'});


%% --- OUTPUT ---

CCI.label = assessment_label;

CCI.CCI_env = CCI_env;
CCI.CCI_env_mean = CCI_env_mean;
CCI.CCI_env_std = CCI_env_std;

CCI.cci_pair_names = cci_pair_names;
CCI.T_CCI = T_CCI;


%% --- DISPLAY ---

fprintf('\n--- CCI RESULTS: %s ---\n', assessment_label);
disp(T_CCI);

end