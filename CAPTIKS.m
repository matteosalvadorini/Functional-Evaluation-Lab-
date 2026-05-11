%% --- CAPTIKS 10m WALK ANALYSIS (CLEAN VERSION) ---

clearvars -except cpk_anatomical_angles*
clc
close all

%% Load anatomical angles automatically
vars = who('cpk_anatomical_angles*');

if isempty(vars)
    error('No cpk_anatomical_angles variable found. Run import first.');
end

data_angles = eval(vars{1});

Remove_first_sample_Offset = 1;

% Sampling time
T_sample = mean(diff(data_angles.TIMESTAMPRELATIVE));

%% LEFT LEG ANGLES
left_Ankle_angle_phi_x = data_angles.ANKLEDORSIFLEXION_PLANTARFLEXIONLEFT;
left_Knee_angle_phi_x  = data_angles.KNEEFLEXION_EXTENSIONLEFT;
left_Hip_angle_phi_x   = data_angles.HIPFLEXION_EXTENSIONLEFT;

%% RIGHT LEG ANGLES
right_Ankle_angle_phi_x = data_angles.ANKLEDORSIFLEXION_PLANTARFLEXIONRIGHT;
right_Knee_angle_phi_x  = data_angles.KNEEFLEXION_EXTENSIONRIGHT;
right_Hip_angle_phi_x   = data_angles.HIPFLEXION_EXTENSIONRIGHT;

%% Offset removal
if Remove_first_sample_Offset
    left_Ankle_angle_phi_x = left_Ankle_angle_phi_x - left_Ankle_angle_phi_x(1);
    left_Knee_angle_phi_x  = left_Knee_angle_phi_x - left_Knee_angle_phi_x(1);
    left_Hip_angle_phi_x   = left_Hip_angle_phi_x - left_Hip_angle_phi_x(1);

    right_Ankle_angle_phi_x = right_Ankle_angle_phi_x - right_Ankle_angle_phi_x(1);
    right_Knee_angle_phi_x  = right_Knee_angle_phi_x - right_Knee_angle_phi_x(1);
    right_Hip_angle_phi_x   = right_Hip_angle_phi_x - right_Hip_angle_phi_x(1);
end

%% Synthetic gyro (derivative of ankle angle)
left_Gyro_foot  = -[0; diff(left_Ankle_angle_phi_x)/T_sample];
right_Gyro_foot = -[0; diff(right_Ankle_angle_phi_x)/T_sample];

%% Filtering
fs = 100;
fc = 6;

[left_b,left_a] = butter(4, fc/(fs/2), 'low');

left_Gyro_foot  = medfilt1(left_Gyro_foot,15);
right_Gyro_foot = medfilt1(right_Gyro_foot,15);

left_Gyro_foot  = filtfilt(left_b,left_a,left_Gyro_foot);
right_Gyro_foot = filtfilt(left_b,left_a,right_Gyro_foot);

left_Ankle_angle_phi_x  = filtfilt(left_b,left_a,left_Ankle_angle_phi_x);
right_Ankle_angle_phi_x = filtfilt(left_b,left_a,right_Ankle_angle_phi_x);

%% High-pass style filtered signal (for FSM logic)
omega_hp = 1.5;
K_hp = 1;

left_G_foot_phi_x_filtered = zeros(size(left_Ankle_angle_phi_x));
right_G_foot_phi_x_filtered = zeros(size(right_Ankle_angle_phi_x));

left_G_foot_phi_x_filtered(1) = left_Ankle_angle_phi_x(1);
right_G_foot_phi_x_filtered(1) = right_Ankle_angle_phi_x(1);

for ii = 2:length(left_Ankle_angle_phi_x)
    left_G_foot_phi_x_filtered(ii) = ...
        exp(-omega_hp*T_sample)*left_G_foot_phi_x_filtered(ii-1) + ...
        K_hp*(left_Ankle_angle_phi_x(ii)-left_Ankle_angle_phi_x(ii-1));
end

for ii = 2:length(right_Ankle_angle_phi_x)
    right_G_foot_phi_x_filtered(ii) = ...
        exp(-omega_hp*T_sample)*right_G_foot_phi_x_filtered(ii-1) + ...
        K_hp*(right_Ankle_angle_phi_x(ii)-right_Ankle_angle_phi_x(ii-1));
end

%% Synchronize lengths
N_left = min([length(left_Gyro_foot), ...
              length(left_Ankle_angle_phi_x), ...
              length(left_G_foot_phi_x_filtered)]);

left_Gyro_foot = left_Gyro_foot(1:N_left);
left_Ankle_angle_phi_x = left_Ankle_angle_phi_x(1:N_left);
left_G_foot_phi_x_filtered = left_G_foot_phi_x_filtered(1:N_left);

N_right = min([length(right_Gyro_foot), ...
               length(right_Ankle_angle_phi_x), ...
               length(right_G_foot_phi_x_filtered)]);

right_Gyro_foot = right_Gyro_foot(1:N_right);
right_Ankle_angle_phi_x = right_Ankle_angle_phi_x(1:N_right);
right_G_foot_phi_x_filtered = right_G_foot_phi_x_filtered(1:N_right);

%% FSM PARAMETERS
AngleLimit = -5;
SpeedLimitMax = 25;
SpeedLimitMin = -25;
SpeedLimitMin2 = -10;

%% LEFT FSM
State_left = zeros(N_left,1);
CurrentPhase_left = 0;

for ii = 3:N_left

    if sign(left_Gyro_foot(ii)*left_Gyro_foot(ii-1)) <= 0 && ...
       sign(left_Gyro_foot(ii)) < 0 && ...
       left_Ankle_angle_phi_x(ii) > AngleLimit

        CurrentPhase_left = 0;
    end

    switch CurrentPhase_left
        case 0
            if sign(left_G_foot_phi_x_filtered(ii)*left_G_foot_phi_x_filtered(ii-1)) <= 0
                CurrentPhase_left = 1;
            end

        case 1
            if left_Gyro_foot(ii-1) <= SpeedLimitMin
                CurrentPhase_left = 2;
            end

        case 2
            if left_Gyro_foot(ii-1) >= SpeedLimitMin2
                CurrentPhase_left = 3;
            end

        case 3
            if left_Gyro_foot(ii) > SpeedLimitMax
                CurrentPhase_left = 4;
            end

        case 4
            if sign(left_Gyro_foot(ii)*left_Gyro_foot(ii-1)) <= 0 && ...
               sign(left_Gyro_foot(ii)) < 0

                CurrentPhase_left = 0;
            end
    end

    State_left(ii) = CurrentPhase_left;
end

%% RIGHT FSM
State_right = zeros(N_right,1);
CurrentPhase_right = 0;

for ii = 3:N_right

    if sign(right_Gyro_foot(ii)*right_Gyro_foot(ii-1)) <= 0 && ...
       sign(right_Gyro_foot(ii)) < 0 && ...
       right_Ankle_angle_phi_x(ii) > AngleLimit

        CurrentPhase_right = 0;
    end

    switch CurrentPhase_right
        case 0
            if sign(right_G_foot_phi_x_filtered(ii)*right_G_foot_phi_x_filtered(ii-1)) <= 0
                CurrentPhase_right = 1;
            end

        case 1
            if right_Gyro_foot(ii-1) <= SpeedLimitMin
                CurrentPhase_right = 2;
            end

        case 2
            if right_Gyro_foot(ii-1) >= SpeedLimitMin2
                CurrentPhase_right = 3;
            end

        case 3
            if right_Gyro_foot(ii) > SpeedLimitMax
                CurrentPhase_right = 4;
            end

        case 4
            if sign(right_Gyro_foot(ii)*right_Gyro_foot(ii-1)) <= 0 && ...
               sign(right_Gyro_foot(ii)) < 0

                CurrentPhase_right = 0;
            end
    end

    State_right(ii) = CurrentPhase_right;
end

%% Time vector
t = seconds(data_angles.TIMESTAMPRELATIVE - ...
            data_angles.TIMESTAMPRELATIVE(1));

t = t(1:min([length(t),N_left,N_right]));

%% Final plots
figure('Name','FSM Gait Analysis',...
       'Units','normalized',...
       'Position',[0.1 0.1 0.8 0.8]);

subplot(2,1,1)
yyaxis left
plot(t,left_Ankle_angle_phi_x(1:length(t)),'r','LineWidth',1.5)
ylabel('Left Ankle Angle (deg)')
grid on
hold on

yyaxis right
plot(t,State_left(1:length(t)),'k--')
ylabel('Gait Phase')
ylim([-1 5])

title('LEFT LEG')

subplot(2,1,2)
yyaxis left
plot(t,right_Ankle_angle_phi_x(1:length(t)),'b','LineWidth',1.5)
ylabel('Right Ankle Angle (deg)')
grid on
hold on

yyaxis right
plot(t,State_right(1:length(t)),'k--')
ylabel('Gait Phase')
ylim([-1 5])

title('RIGHT LEG')
xlabel('Time (s)')