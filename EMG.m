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



plot(t,leftGAL_resampled), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);


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
t = (0:n_sample-1) / fs_channels;
t=t';


% plot of the filtered data 

figure()

plot(t,leftGAL_f), xlabel('time [s]'), ylabel('Crank angle [°]'), xlim([0 max(t)]),sgtitle('Right Leg','FontSize',14,'FontWeight','b');
set(gca,'FontSize',12);