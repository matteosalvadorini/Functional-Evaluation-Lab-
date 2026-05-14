function TM = extract_trike_cycle_metrics(S, TrikeCycleInfo, GoodCycleInfo)

%% --- EXTRACT TRIKE CYCLE METRICS ---
% This function extracts mechanical trike metrics cycle by cycle.
%
% Cycles are defined from trike crank-angle resets.
% Only the selected good cycles are saved, so the trike metrics are directly
% matched with the EMG cycles used in the analysis.

trike = S.trike;
locs_trike = TrikeCycleInfo.locs_trike;
good_cycles = GoodCycleInfo.good_cycles;

n_cycles_total = length(locs_trike) - 1;


%% --- PREALLOCATE METRICS FOR ALL CYCLES ---

PowerR_mean = NaN(n_cycles_total,1);
PowerL_mean = NaN(n_cycles_total,1);
PowerTotal_mean = NaN(n_cycles_total,1);

PowerSI_abs = NaN(n_cycles_total,1);

PowerR_contribution = NaN(n_cycles_total,1);
PowerL_contribution = NaN(n_cycles_total,1);

PowerR_nonzero_fraction = NaN(n_cycles_total,1);
PowerL_nonzero_fraction = NaN(n_cycles_total,1);
PowerTotal_nonzero_fraction = NaN(n_cycles_total,1);

Cadence_mean = NaN(n_cycles_total,1);
Velocity_mean = NaN(n_cycles_total,1);
Distance_delta = NaN(n_cycles_total,1);


%% --- COMPUTE CYCLE-BY-CYCLE METRICS ---

for c = 1:n_cycles_total

    idx_start = locs_trike(c);
    idx_end   = locs_trike(c+1) - 1;

    powerR = trike.powerRight(idx_start:idx_end);
    powerL = trike.powerLeft(idx_start:idx_end);

    cadence = trike.cadence(idx_start:idx_end);
    velocity = trike.linearVelocity(idx_start:idx_end);
    distance = trike.totalDistance(idx_start:idx_end);

    powerTotal = powerR + powerL;

    meanPowerR = mean(powerR, 'omitnan');
    meanPowerL = mean(powerL, 'omitnan');
    meanPowerTotal = mean(powerTotal, 'omitnan');

    PowerR_mean(c) = meanPowerR;
    PowerL_mean(c) = meanPowerL;
    PowerTotal_mean(c) = meanPowerTotal;

    if abs(meanPowerTotal) > eps
        PowerR_contribution(c) = meanPowerR / meanPowerTotal;
        PowerL_contribution(c) = meanPowerL / meanPowerTotal;
    end

    denominator = 0.5 * (meanPowerR + meanPowerL);

    if abs(denominator) > eps
        PowerSI_abs(c) = abs(((meanPowerR - meanPowerL) / denominator) * 100);
    end

    PowerR_nonzero_fraction(c) = mean(powerR ~= 0, 'omitnan');
    PowerL_nonzero_fraction(c) = mean(powerL ~= 0, 'omitnan');
    PowerTotal_nonzero_fraction(c) = mean(powerTotal ~= 0, 'omitnan');

    Cadence_mean(c) = mean(cadence, 'omitnan');
    Velocity_mean(c) = mean(velocity, 'omitnan');
    Distance_delta(c) = distance(end) - distance(1);

end


%% --- SAVE GOOD-CYCLE METRICS ONLY ---

TM.label = S.label;

TM.good_cycles = good_cycles;
TM.n_cycles_total = n_cycles_total;
TM.n_good_cycles = length(good_cycles);

TM.PowerR_mean = PowerR_mean(good_cycles);
TM.PowerL_mean = PowerL_mean(good_cycles);
TM.PowerTotal_mean = PowerTotal_mean(good_cycles);

TM.PowerSI_abs = PowerSI_abs(good_cycles);

TM.PowerR_contribution = PowerR_contribution(good_cycles);
TM.PowerL_contribution = PowerL_contribution(good_cycles);

TM.PowerR_nonzero_fraction = PowerR_nonzero_fraction(good_cycles);
TM.PowerL_nonzero_fraction = PowerL_nonzero_fraction(good_cycles);
TM.PowerTotal_nonzero_fraction = PowerTotal_nonzero_fraction(good_cycles);

TM.Cadence_mean = Cadence_mean(good_cycles);
TM.Velocity_mean = Velocity_mean(good_cycles);
TM.Distance_delta = Distance_delta(good_cycles);


%% --- SUMMARY TABLE ---

TM.T_summary = table( ...
    mean(TM.PowerR_mean, 'omitnan'), ...
    mean(TM.PowerL_mean, 'omitnan'), ...
    mean(TM.PowerTotal_mean, 'omitnan'), ...
    mean(TM.PowerSI_abs, 'omitnan'), ...
    mean(TM.PowerR_contribution, 'omitnan') * 100, ...
    mean(TM.PowerL_contribution, 'omitnan') * 100, ...
    mean(TM.PowerR_nonzero_fraction, 'omitnan') * 100, ...
    mean(TM.PowerL_nonzero_fraction, 'omitnan') * 100, ...
    mean(TM.PowerTotal_nonzero_fraction, 'omitnan') * 100, ...
    mean(TM.Cadence_mean, 'omitnan'), ...
    mean(TM.Velocity_mean, 'omitnan'), ...
    mean(TM.Distance_delta, 'omitnan'), ...
    'VariableNames', { ...
    'MeanPowerR', ...
    'MeanPowerL', ...
    'MeanPowerTotal', ...
    'MeanPowerSI_abs', ...
    'MeanPowerRContribution_pct', ...
    'MeanPowerLContribution_pct', ...
    'MeanPowerRNonZeroFraction_pct', ...
    'MeanPowerLNonZeroFraction_pct', ...
    'MeanPowerTotalNonZeroFraction_pct', ...
    'MeanCadence', ...
    'MeanVelocity', ...
    'MeanDistancePerCycle'});


%% --- DISPLAY ---

fprintf('\n--- TRIKE CYCLE METRICS: %s ---\n', S.label);
disp(TM.T_summary);

fprintf('Good cycles: %d / %d\n', TM.n_good_cycles, TM.n_cycles_total);

end