function ET = compute_EMG_trike_relationship(Results, assessment_labels, min_total_power)

%% --- EMG-TRIKE RELATIONSHIP ANALYSIS ---
% This function combines EMG and trike metrics cycle by cycle.
%
% Two EMG cost definitions are computed:
%
% 1) Mean of cycle-by-cycle costs:
%    mean(iEMG_cycle / power_cycle)
%    Low-power cycles are excluded to avoid unstable divisions.
%
% 2) Cost from mean values:
%    mean(iEMG) / mean(power)
%    All selected good cycles are used, so the good-cycle distribution is not altered.
%
% Both definitions are computed for:
% - total output
% - right side
% - left side

ET = cell(1,3);

for a = 1:3

    label = assessment_labels{a};

    Activation = Results{a}.Activation;
    CCI = Results{a}.CCI;
    TrikeMetrics = Results{a}.TrikeMetrics;


    %% --- EMG VARIABLES ---

    iEMG = Activation.iEMG;

    n_muscles = size(iEMG,2);
    n_side = n_muscles / 2;

    right_iEMG = sum(iEMG(:,1:n_side), 2);
    left_iEMG  = sum(iEMG(:,n_side+1:end), 2);
    total_iEMG = right_iEMG + left_iEMG;

    global_SI_iEMG = Activation.SI_global_iEMG;
    mean_CCI_cycle = mean(CCI.CCI_env, 2, 'omitnan');


    %% --- TRIKE VARIABLES ---

    PowerR = TrikeMetrics.PowerR_mean(:);
    PowerL = TrikeMetrics.PowerL_mean(:);
    PowerTotal = TrikeMetrics.PowerTotal_mean(:);

    PowerRContribution = TrikeMetrics.PowerR_contribution(:);
    PowerLContribution = TrikeMetrics.PowerL_contribution(:);

    PowerRNonZeroFraction = TrikeMetrics.PowerR_nonzero_fraction(:);
    PowerLNonZeroFraction = TrikeMetrics.PowerL_nonzero_fraction(:);


    %% --- EMG COST METHOD 1: MEAN OF CYCLE-BY-CYCLE COSTS ---
    % This method computes iEMG / power for each cycle.
    % Cycles with power below threshold are excluded to avoid unstable ratios.

    valid_power_total = PowerTotal > min_total_power;
    valid_power_R = PowerR > min_total_power;
    valid_power_L = PowerL > min_total_power;

    TotalEMGCost_cycle = NaN(size(total_iEMG));
    RightEMGCost_cycle = NaN(size(right_iEMG));
    LeftEMGCost_cycle  = NaN(size(left_iEMG));

    TotalEMGCost_cycle(valid_power_total) = ...
        total_iEMG(valid_power_total) ./ PowerTotal(valid_power_total);

    RightEMGCost_cycle(valid_power_R) = ...
        right_iEMG(valid_power_R) ./ PowerR(valid_power_R);

    LeftEMGCost_cycle(valid_power_L) = ...
        left_iEMG(valid_power_L) ./ PowerL(valid_power_L);

    MeanTotalEMGCost_cycle = mean(TotalEMGCost_cycle, 'omitnan');
    MeanRightEMGCost_cycle = mean(RightEMGCost_cycle, 'omitnan');
    MeanLeftEMGCost_cycle  = mean(LeftEMGCost_cycle, 'omitnan');


    %% --- EMG COST METHOD 2: COST FROM MEAN VALUES ---
    % This method computes mean iEMG / mean power using all selected good cycles.
    % No good cycle is excluded here.

    MeanPowerTotal_tmp = mean(PowerTotal, 'omitnan');
    MeanPowerR_tmp = mean(PowerR, 'omitnan');
    MeanPowerL_tmp = mean(PowerL, 'omitnan');

    MeanTotalEMGCost_fromMeans = NaN;
    MeanRightEMGCost_fromMeans = NaN;
    MeanLeftEMGCost_fromMeans  = NaN;

    if abs(MeanPowerTotal_tmp) > eps
        MeanTotalEMGCost_fromMeans = ...
            mean(total_iEMG, 'omitnan') / MeanPowerTotal_tmp;
    end

    if abs(MeanPowerR_tmp) > eps
        MeanRightEMGCost_fromMeans = ...
            mean(right_iEMG, 'omitnan') / MeanPowerR_tmp;
    end

    if abs(MeanPowerL_tmp) > eps
        MeanLeftEMGCost_fromMeans = ...
            mean(left_iEMG, 'omitnan') / MeanPowerL_tmp;
    end


    %% --- SUMMARY TABLE ---

    SummaryTable = table( ...
        mean(total_iEMG, 'omitnan'), ...
        mean(right_iEMG, 'omitnan'), ...
        mean(left_iEMG, 'omitnan'), ...
        mean(abs(global_SI_iEMG), 'omitnan'), ...
        mean(mean_CCI_cycle, 'omitnan'), ...
        mean(PowerR, 'omitnan'), ...
        mean(PowerL, 'omitnan'), ...
        mean(PowerTotal, 'omitnan'), ...
        mean(PowerRContribution, 'omitnan') * 100, ...
        mean(PowerLContribution, 'omitnan') * 100, ...
        mean(PowerRNonZeroFraction, 'omitnan') * 100, ...
        mean(PowerLNonZeroFraction, 'omitnan') * 100, ...
        MeanTotalEMGCost_cycle, ...
        MeanRightEMGCost_cycle, ...
        MeanLeftEMGCost_cycle, ...
        MeanTotalEMGCost_fromMeans, ...
        MeanRightEMGCost_fromMeans, ...
        MeanLeftEMGCost_fromMeans, ...
        'VariableNames', { ...
        'MeanTotal_iEMG', ...
        'MeanRight_iEMG', ...
        'MeanLeft_iEMG', ...
        'MeanAbsGlobalSI_iEMG', ...
        'MeanCCI', ...
        'MeanPowerR', ...
        'MeanPowerL', ...
        'MeanPowerTotal', ...
        'MeanPowerRContribution_pct', ...
        'MeanPowerLContribution_pct', ...
        'MeanPowerRNonZeroFraction_pct', ...
        'MeanPowerLNonZeroFraction_pct', ...
        'MeanTotalEMGCost_cycleMean', ...
        'MeanRightEMGCost_cycleMean', ...
        'MeanLeftEMGCost_cycleMean', ...
        'MeanTotalEMGCost_fromMeans', ...
        'MeanRightEMGCost_fromMeans', ...
        'MeanLeftEMGCost_fromMeans'});


    %% --- OUTPUT ---

    ET{a}.label = label;
    ET{a}.n_cycles = length(total_iEMG);
    ET{a}.min_total_power = min_total_power;

    ET{a}.total_iEMG = total_iEMG;
    ET{a}.right_iEMG = right_iEMG;
    ET{a}.left_iEMG = left_iEMG;

    ET{a}.global_SI_iEMG = global_SI_iEMG;
    ET{a}.mean_CCI_cycle = mean_CCI_cycle;

    ET{a}.PowerR = PowerR;
    ET{a}.PowerL = PowerL;
    ET{a}.PowerTotal = PowerTotal;

    ET{a}.PowerRContribution = PowerRContribution;
    ET{a}.PowerLContribution = PowerLContribution;

    ET{a}.PowerRNonZeroFraction = PowerRNonZeroFraction;
    ET{a}.PowerLNonZeroFraction = PowerLNonZeroFraction;

    % Cycle-by-cycle EMG cost vectors
    ET{a}.TotalEMGCost_cycle = TotalEMGCost_cycle;
    ET{a}.RightEMGCost_cycle = RightEMGCost_cycle;
    ET{a}.LeftEMGCost_cycle = LeftEMGCost_cycle;

    % Mean of cycle-by-cycle costs
    ET{a}.MeanTotalEMGCost_cycleMean = MeanTotalEMGCost_cycle;
    ET{a}.MeanRightEMGCost_cycleMean = MeanRightEMGCost_cycle;
    ET{a}.MeanLeftEMGCost_cycleMean = MeanLeftEMGCost_cycle;

    % Cost from mean values
    ET{a}.MeanTotalEMGCost_fromMeans = MeanTotalEMGCost_fromMeans;
    ET{a}.MeanRightEMGCost_fromMeans = MeanRightEMGCost_fromMeans;
    ET{a}.MeanLeftEMGCost_fromMeans = MeanLeftEMGCost_fromMeans;

    % Valid cycles used only for cycle-by-cycle cost
    ET{a}.valid_power_total = valid_power_total;
    ET{a}.valid_power_R = valid_power_R;
    ET{a}.valid_power_L = valid_power_L;

    ET{a}.SummaryTable = SummaryTable;


    %% --- DISPLAY ---

    fprintf('\n--- EMG-TRIKE RELATIONSHIP: %s ---\n', label);
    disp(SummaryTable);

end

end