function plot_EMG_trike_integrated_summary(EMGTrikeRelationship, assessment_labels)

%% --- EMG-TRIKE INTEGRATED SUMMARY PLOTS ---
% This function plots integrated EMG-trike results using two EMG cost definitions:
%
% 1) Cost from mean values:
%    mean(iEMG) / mean(power)
%
% 2) Mean of cycle-by-cycle costs:
%    mean(iEMG_cycle / power_cycle)
%
% For each method, three figures are generated:
% - Total
% - Right
% - Left
%
% Each figure contains:
% - mean power
% - mean iEMG
% - EMG cost
%
% For cycle-by-cycle cost plots, individual good-cycle values are also shown
% as aligned dots over the cost bar plot.

colors = [ ...
    0.0000 0.4470 0.7410; ...
    0.8500 0.3250 0.0980; ...
    0.4660 0.6740 0.1880];

n_assessments = 3;


%% --- EXTRACT MEAN POWER AND iEMG VALUES ---

MeanPowerTotal = zeros(1,n_assessments);
MeanPowerR     = zeros(1,n_assessments);
MeanPowerL     = zeros(1,n_assessments);

MeanTotal_iEMG = zeros(1,n_assessments);
MeanRight_iEMG = zeros(1,n_assessments);
MeanLeft_iEMG  = zeros(1,n_assessments);

MeanTotalCost_fromMeans = zeros(1,n_assessments);
MeanRightCost_fromMeans = zeros(1,n_assessments);
MeanLeftCost_fromMeans  = zeros(1,n_assessments);

MeanTotalCost_cycleMean = zeros(1,n_assessments);
MeanRightCost_cycleMean = zeros(1,n_assessments);
MeanLeftCost_cycleMean  = zeros(1,n_assessments);

for a = 1:n_assessments

    ET = EMGTrikeRelationship{a};

    MeanPowerTotal(a) = mean(ET.PowerTotal, 'omitnan');
    MeanPowerR(a)     = mean(ET.PowerR, 'omitnan');
    MeanPowerL(a)     = mean(ET.PowerL, 'omitnan');

    MeanTotal_iEMG(a) = mean(ET.total_iEMG, 'omitnan');
    MeanRight_iEMG(a) = mean(ET.right_iEMG, 'omitnan');
    MeanLeft_iEMG(a)  = mean(ET.left_iEMG, 'omitnan');

    MeanTotalCost_fromMeans(a) = ET.MeanTotalEMGCost_fromMeans;
    MeanRightCost_fromMeans(a) = ET.MeanRightEMGCost_fromMeans;
    MeanLeftCost_fromMeans(a)  = ET.MeanLeftEMGCost_fromMeans;

    MeanTotalCost_cycleMean(a) = ET.MeanTotalEMGCost_cycleMean;
    MeanRightCost_cycleMean(a) = ET.MeanRightEMGCost_cycleMean;
    MeanLeftCost_cycleMean(a)  = ET.MeanLeftEMGCost_cycleMean;

end


%% --- ORGANIZE VALUES FOR PLOTTING ---

side_names = {'Total','Right','Left'};

power_values = { ...
    MeanPowerTotal, ...
    MeanPowerR, ...
    MeanPowerL};

iemg_values = { ...
    MeanTotal_iEMG, ...
    MeanRight_iEMG, ...
    MeanLeft_iEMG};

cost_from_means_values = { ...
    MeanTotalCost_fromMeans, ...
    MeanRightCost_fromMeans, ...
    MeanLeftCost_fromMeans};

cost_cycle_mean_values = { ...
    MeanTotalCost_cycleMean, ...
    MeanRightCost_cycleMean, ...
    MeanLeftCost_cycleMean};

cycle_cost_fields = { ...
    'TotalEMGCost_cycle', ...
    'RightEMGCost_cycle', ...
    'LeftEMGCost_cycle'};

power_ylabels = { ...
    'Mean total power [W]', ...
    'Mean right power [W]', ...
    'Mean left power [W]'};

iemg_ylabels = { ...
    'Mean total iEMG', ...
    'Mean right iEMG', ...
    'Mean left iEMG'};

cost_ylabels = { ...
    'Total iEMG / total power', ...
    'Right iEMG / right power', ...
    'Left iEMG / left power'};


%% --- METHOD 1: COST FROM MEAN VALUES ---

for s = 1:3

    figure('Name',[side_names{s} ' EMG-trike summary - cost from means'], ...
           'Units','normalized','Position',[0.1 0.1 0.85 0.45]);

    subplot(1,3,1)

    b = bar(power_values{s});
    b.FaceColor = 'flat';

    for a = 1:n_assessments
        b.CData(a,:) = colors(a,:);
    end

    xticks(1:n_assessments);
    xticklabels(assessment_labels);
    ylabel(power_ylabels{s});
    title([side_names{s} ' power']);
    grid on;


    subplot(1,1,2)

    b = bar(iemg_values{s});
    b.FaceColor = 'flat';

    for a = 1:n_assessments
        b.CData(a,:) = colors(a,:);
    end

    xticks(1:n_assessments);
    xticklabels(assessment_labels);
    ylabel(iemg_ylabels{s});
    title([side_names{s} ' iEMG']);
    grid on;


    subplot(1,,3)

    b = bar(cost_from_means_values{s});
    b.FaceColor = 'flat';

    for a = 1:n_assessments
        b.CData(a,:) = colors(a,:);
    end

    xticks(1:n_assessments);
    xticklabels(assessment_labels);
    ylabel(cost_ylabels{s});
    title([side_names{s} ' EMG cost - from means']);
    grid on;

end



end