%% 1 - Plot RAW DATA

% Right Leg (1-9)
% 1. Tibialis anterior R 
% 2. Gastro lat R 
% 3. Soleus R 
% 4. Gastro med R 
% 5. Rectus R   
% 6. Vastus Lat R 
% 7. Vastus Med R 
% 8. Semitendinous R 
% 9. Tibialis anterior L 
% 10. Gastro lat L 
% 11. Soleus L 
% 12. Gastro med L 
% 13. Rectus L 
% 14. Vastus Lat L 
% 15. Vastus Med L 
% 16. Semitendinous L 


n_sample = size(leftGAL_resampled, 1);
t = (0:n_sample-1) / fs_channels;
t=t';

figure()
tiledlayout(6,3)

nexttile;
plot(t,rightTA_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Tibialis anterior R ');

nexttile;
plot(t,rightGAL_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Gastro lat R');

nexttile;
plot(t,rightSOL_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('SoleusR');

nexttile;
plot(t,rightGAM_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Gastro med R');

nexttile;
plot(t,rightRF_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Rectus R');

nexttile;
plot(t,rightVL_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Vastus Let R');

nexttile;
plot(t,rightVM_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Vastus Med R');

nexttile;
plot(t,rightSM_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Semitendinous R');

nexttile;
plot(t,leftTA_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Tibialis anterior L');

nexttile;
plot(t,leftGAL_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Gastro lat L');

nexttile;
plot(t,leftSOL_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Soleus L');

nexttile;
plot(t,leftGAM_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Gastro med L');

nexttile;
plot(t,leftRF_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Rectus L');

nexttile;
plot(t,leftVL_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Vastus Lat L');

nexttile;
plot(t,leftGAM_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Vastus Med L');

nexttile;
plot(t,leftSM_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('Semitedinous L');

nexttile;
plot(t,trigger_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);
title('trigger');

%% BAND-PASS FILTERING

% Band-pass filter 5th order
% Matlab functions: Butter(); filtfilt()
% cut off frequency = [20-400] Hz 


W= [20; 400];
Wn = W/(fs_channels/2); %frequenza noralizzata
[b,a ]= butter(5,Wn,"bandpass");

leftGALisnan = fillmissing(leftGAL_resampled, 'constant', 0);

leftGAL_f = filtfilt(b,a,leftGALisnan);


n_sample = size(leftGAL_f, 1);
t_f = (0:n_sample-1) / fs_channels;
t_f=t_f';


% plot of the filtered data 

figure()

plot(t_f,leftGAL_f), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);