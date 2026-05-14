function plot_EMG_trike_final_relationships(EMGTrikeRelationship, assessment_labels)

%% --- FINAL EMG-TRIKE RELATIONSHIP PLOTS ---
% This function plots cycle-by-cycle relationships between EMG activation
% and trike mechanical output.
%
% Each assessment is shown as a cloud of points.
% The large pentagon marker shows the centroid of each cloud.
%
% Right and left sides are plotted with the same logic.

colors = [ ...
    0.0000 0.4470 0.7410; ...
    0.8500 0.3250 0.0980; ...
    0.4660 0.6740 0.1880];


%% --- RIGHT iEMG VS RIGHT POWER ---

figure('Name','Right iEMG vs Right Power', ...
       'Units','normalized','Position',[0.1 0.1 0.75 0.55]);

hold on

for a = 1:3

    ET = EMGTrikeRelationship{a};

    x = ET.right_iEMG;
    y = ET.PowerR;

    scatter(x, y, 35, ...
        'MarkerFaceColor', colors(a,:), ...
        'MarkerEdgeColor', colors(a,:), ...
        'MarkerFaceAlpha', 0.55, ...
        'DisplayName', assessment_labels{a});

    plot(mean(x,'omitnan'), mean(y,'omitnan'), 'p', ...
        'MarkerSize', 16, ...
        'MarkerFaceColor', colors(a,:), ...
        'MarkerEdgeColor', 'k', ...
        'LineWidth', 1.4, ...
        'HandleVisibility','off');

end

xlabel('Right-side iEMG');
ylabel('Right-side power [W]');
title('Right EMG activation vs right mechanical power');
legend('Location','best');
grid on;


%% --- LEFT iEMG VS LEFT POWER ---

figure('Name','Left iEMG vs Left Power', ...
       'Units','normalized','Position',[0.1 0.1 0.75 0.55]);

hold on

for a = 1:3

    ET = EMGTrikeRelationship{a};

    x = ET.left_iEMG;
    y = ET.PowerL;

    scatter(x, y, 35, ...
        'MarkerFaceColor', colors(a,:), ...
        'MarkerEdgeColor', colors(a,:), ...
        'MarkerFaceAlpha', 0.55, ...
        'DisplayName', assessment_labels{a});

    plot(mean(x,'omitnan'), mean(y,'omitnan'), 'p', ...
        'MarkerSize', 16, ...
        'MarkerFaceColor', colors(a,:), ...
        'MarkerEdgeColor', 'k', ...
        'LineWidth', 1.4, ...
        'HandleVisibility','off');

end

xlabel('Left-side iEMG');
ylabel('Left-side power [W]');
title('Left EMG activation vs left mechanical power');
legend('Location','best');
grid on;


%% --- TOTAL iEMG VS TOTAL POWER ---

figure('Name','Total iEMG vs Total Power', ...
       'Units','normalized','Position',[0.1 0.1 0.75 0.55]);

hold on

for a = 1:3

    ET = EMGTrikeRelationship{a};

    x = ET.total_iEMG;
    y = ET.PowerTotal;

    scatter(x, y, 35, ...
        'MarkerFaceColor', colors(a,:), ...
        'MarkerEdgeColor', colors(a,:), ...
        'MarkerFaceAlpha', 0.55, ...
        'DisplayName', assessment_labels{a});

    plot(mean(x,'omitnan'), mean(y,'omitnan'), 'p', ...
        'MarkerSize', 16, ...
        'MarkerFaceColor', colors(a,:), ...
        'MarkerEdgeColor', 'k', ...
        'LineWidth', 1.4, ...
        'HandleVisibility','off');

end

xlabel('Total iEMG');
ylabel('Total power [W]');
title('Total EMG activation vs total mechanical power');
legend('Location','best');
grid on;


%% --- POWER CONTRIBUTION VS GLOBAL EMG ASYMMETRY ---

figure('Name','Power Contribution vs Global EMG Asymmetry', ...
       'Units','normalized','Position',[0.1 0.1 0.85 0.55]);

subplot(1,2,1)
hold on

for a = 1:3

    ET = EMGTrikeRelationship{a};

    x = ET.PowerRContribution * 100;
    y = abs(ET.global_SI_iEMG);

    scatter(x, y, 35, ...
        'MarkerFaceColor', colors(a,:), ...
        'MarkerEdgeColor', colors(a,:), ...
        'MarkerFaceAlpha', 0.55, ...
        'DisplayName', assessment_labels{a});

    plot(mean(x,'omitnan'), mean(y,'omitnan'), 'p', ...
        'MarkerSize', 16, ...
        'MarkerFaceColor', colors(a,:), ...
        'MarkerEdgeColor', 'k', ...
        'LineWidth', 1.4, ...
        'HandleVisibility','off');

end

xlabel('Right contribution to total power [%]');
ylabel('Absolute global EMG SI [%]');
title('Right contribution vs EMG asymmetry');
legend('Location','best');
grid on;


subplot(1,2,2)
hold on

for a = 1:3

    ET = EMGTrikeRelationship{a};

    x = ET.PowerLContribution * 100;
    y = abs(ET.global_SI_iEMG);

    scatter(x, y, 35, ...
        'MarkerFaceColor', colors(a,:), ...
        'MarkerEdgeColor', colors(a,:), ...
        'MarkerFaceAlpha', 0.55, ...
        'DisplayName', assessment_labels{a});

    plot(mean(x,'omitnan'), mean(y,'omitnan'), 'p', ...
        'MarkerSize', 16, ...
        'MarkerFaceColor', colors(a,:), ...
        'MarkerEdgeColor', 'k', ...
        'LineWidth', 1.4, ...
        'HandleVisibility','off');

end

xlabel('Left contribution to total power [%]');
ylabel('Absolute global EMG SI [%]');
title('Left contribution vs EMG asymmetry');
legend('Location','best');
grid on;


%% --- RIGHT AND LEFT POWER DISTRIBUTION ---

figure('Name','Right and Left Power Distribution', ...
       'Units','normalized','Position',[0.1 0.1 0.85 0.75]);

for a = 1:3

    ET = EMGTrikeRelationship{a};

    subplot(2,3,a)
    histogram(ET.PowerR, 20);
    xlabel('Right power [W]');
    ylabel('Number of cycles');
    title([assessment_labels{a} ' - PowerR distribution']);
    grid on;

    subplot(2,3,a+3)
    histogram(ET.PowerL, 20);
    xlabel('Left power [W]');
    ylabel('Number of cycles');
    title([assessment_labels{a} ' - PowerL distribution']);
    grid on;

end


%% --- SIDE-SPECIFIC MEAN POWER ---

MeanPowerR = zeros(1,3);
MeanPowerL = zeros(1,3);

PowerRNonZeroFraction = zeros(1,3);
PowerLNonZeroFraction = zeros(1,3);

PowerRContribution = zeros(1,3);
PowerLContribution = zeros(1,3);

for a = 1:3

    ET = EMGTrikeRelationship{a};

    MeanPowerR(a) = mean(ET.PowerR, 'omitnan');
    MeanPowerL(a) = mean(ET.PowerL, 'omitnan');

    PowerRNonZeroFraction(a) = mean(ET.PowerRNonZeroFraction, 'omitnan') * 100;
    PowerLNonZeroFraction(a) = mean(ET.PowerLNonZeroFraction, 'omitnan') * 100;

    PowerRContribution(a) = mean(ET.PowerRContribution, 'omitnan') * 100;
    PowerLContribution(a) = mean(ET.PowerLContribution, 'omitnan') * 100;

end

figure('Name','Right and Left Mean Power', ...
       'Units','normalized','Position',[0.1 0.1 0.75 0.5]);

Y_power = [MeanPowerR; MeanPowerL]';

b = bar(Y_power);

b(1).FaceColor = [0.2 0.4 0.8];
b(2).FaceColor = [0.8 0.4 0.2];

xticks(1:3);
xticklabels(assessment_labels);
ylabel('Mean power [W]');
title('Side-specific mean power');
legend({'Right power','Left power'}, 'Location','best');
grid on;


%% --- SIDE-SPECIFIC POWER INVOLVEMENT PERCENTAGES ---

figure('Name','Right and Left Mechanical Involvement Percentages', ...
       'Units','normalized','Position',[0.1 0.1 0.75 0.5]);

Y_percentage = [PowerRNonZeroFraction; PowerLNonZeroFraction; ...
                PowerRContribution; PowerLContribution]';

b = bar(Y_percentage);

b(1).FaceColor = [0.2 0.4 0.8];
b(2).FaceColor = [0.8 0.4 0.2];
b(3).FaceColor = [0.2 0.6 0.9];
b(4).FaceColor = [0.9 0.5 0.2];

xticks(1:3);
xticklabels(assessment_labels);
ylabel('Percentage [%]');
title('Side-specific mechanical involvement');
legend({'Right non-zero','Left non-zero', ...
        'Right contribution','Left contribution'}, ...
        'Location','best');
grid on;

end