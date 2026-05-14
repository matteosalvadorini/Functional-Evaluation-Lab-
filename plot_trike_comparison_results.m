function plot_trike_comparison_results(Results, assessment_labels)

%% --- PLOT TRIKE COMPARISON RESULTS ---
% This function compares the main trike mechanical metrics across T0, T1 and T2:
% power, right/left contribution, non-zero power fraction, power symmetry,
% cadence, velocity and distance per cycle.

colors = [ ...
    0.0000 0.4470 0.7410; ...
    0.8500 0.3250 0.0980; ...
    0.4660 0.6740 0.1880];

n_assessments = 3;

MeanPowerR = zeros(1,n_assessments);
MeanPowerL = zeros(1,n_assessments);
MeanPowerTotal = zeros(1,n_assessments);

PowerRContribution = zeros(1,n_assessments);
PowerLContribution = zeros(1,n_assessments);

PowerRNonZeroFraction = zeros(1,n_assessments);
PowerLNonZeroFraction = zeros(1,n_assessments);
PowerTotalNonZeroFraction = zeros(1,n_assessments);

PowerSI_abs = zeros(1,n_assessments);

MeanCadence = zeros(1,n_assessments);
MeanVelocity = zeros(1,n_assessments);
MeanDistancePerCycle = zeros(1,n_assessments);


%% --- EXTRACT MEAN VALUES ---

for a = 1:n_assessments

    TM = Results{a}.TrikeMetrics;

    MeanPowerR(a) = mean(TM.PowerR_mean, 'omitnan');
    MeanPowerL(a) = mean(TM.PowerL_mean, 'omitnan');
    MeanPowerTotal(a) = mean(TM.PowerTotal_mean, 'omitnan');

    PowerRContribution(a) = mean(TM.PowerR_contribution, 'omitnan') * 100;
    PowerLContribution(a) = mean(TM.PowerL_contribution, 'omitnan') * 100;

    PowerRNonZeroFraction(a) = mean(TM.PowerR_nonzero_fraction, 'omitnan') * 100;
    PowerLNonZeroFraction(a) = mean(TM.PowerL_nonzero_fraction, 'omitnan') * 100;
    PowerTotalNonZeroFraction(a) = mean(TM.PowerTotal_nonzero_fraction, 'omitnan') * 100;

    PowerSI_abs(a) = mean(TM.PowerSI_abs, 'omitnan');

    MeanCadence(a) = mean(TM.Cadence_mean, 'omitnan');
    MeanVelocity(a) = mean(TM.Velocity_mean, 'omitnan');
    MeanDistancePerCycle(a) = mean(TM.Distance_delta, 'omitnan');

end


%% --- POWER RIGHT / LEFT / TOTAL ---

figure('Name','Trike power comparison T0-T1-T2', ...
       'Units','normalized','Position',[0.1 0.1 0.75 0.5]);

Y_power = [MeanPowerR; MeanPowerL; MeanPowerTotal]';

b = bar(Y_power);

b(1).FaceColor = [0.3 0.3 0.9];
b(2).FaceColor = [0.9 0.3 0.3];
b(3).FaceColor = [0.3 0.7 0.3];

xticks(1:n_assessments);
xticklabels(assessment_labels);
ylabel('Mean power [W]');
title('Mean trike power during selected good cycles');
legend({'Power Right','Power Left','Power Total'}, 'Location','best');
grid on;


%% --- RIGHT / LEFT CONTRIBUTION TO TOTAL POWER ---

figure('Name','Trike power contribution comparison T0-T1-T2', ...
       'Units','normalized','Position',[0.1 0.1 0.75 0.5]);

Y_contribution = [PowerRContribution; PowerLContribution]';

b = bar(Y_contribution);

b(1).FaceColor = [0.3 0.3 0.9];
b(2).FaceColor = [0.9 0.3 0.3];

xticks(1:n_assessments);
xticklabels(assessment_labels);
ylabel('Contribution to total power [%]');
title('Right/left contribution to total trike power');
legend({'Right contribution','Left contribution'}, 'Location','best');
ylim([0 100]);
grid on;


%% --- NON-ZERO POWER FRACTION ---

figure('Name','Trike non-zero power fraction comparison T0-T1-T2', ...
       'Units','normalized','Position',[0.1 0.1 0.75 0.5]);

Y_nonzero = [PowerRNonZeroFraction; PowerLNonZeroFraction; PowerTotalNonZeroFraction]';

b = bar(Y_nonzero);

b(1).FaceColor = [0.3 0.3 0.9];
b(2).FaceColor = [0.9 0.3 0.3];
b(3).FaceColor = [0.3 0.7 0.3];

xticks(1:n_assessments);
xticklabels(assessment_labels);
ylabel('Non-zero power samples [%]');
title('Fraction of non-zero power samples during selected good cycles');
legend({'Right','Left','Total'}, 'Location','best');
ylim([0 100]);
grid on;


%% --- POWER SYMMETRY INDEX ---

figure('Name','Trike power symmetry comparison T0-T1-T2', ...
       'Units','normalized','Position',[0.1 0.1 0.6 0.45]);

b = bar(PowerSI_abs);
b.FaceColor = 'flat';

for a = 1:n_assessments
    b.CData(a,:) = colors(a,:);
end

xticks(1:n_assessments);
xticklabels(assessment_labels);
ylabel('Absolute Power SI [%]');
title('Power symmetry index during selected good cycles');
grid on;


%% --- CADENCE / VELOCITY / DISTANCE ---

figure('Name','Trike kinematic comparison T0-T1-T2', ...
       'Units','normalized','Position',[0.1 0.1 0.75 0.5]);

Y_kin = [MeanCadence; MeanVelocity; MeanDistancePerCycle]';

b = bar(Y_kin);

b(1).FaceColor = [0.2 0.6 0.8];
b(2).FaceColor = [0.8 0.5 0.2];
b(3).FaceColor = [0.5 0.7 0.3];

xticks(1:n_assessments);
xticklabels(assessment_labels);
ylabel('Value');
title('Cadence, velocity and distance per cycle');
legend({'Cadence [RPM]','Velocity','Distance/cycle'}, 'Location','best');
grid on;

end