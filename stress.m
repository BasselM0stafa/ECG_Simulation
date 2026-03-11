%% ================= HRV + Stress Analysis =================
clearvars -except x_final Fs
close all
clc

%% ---------------- Time Vector ----------------
N = length(x_final);
t = (0:N-1)/Fs;

%% -------- Split Signal Automatically --------
mid_point = floor(length(x_final)/2);

ecg_base = x_final(1:mid_point);
t_base   = t(1:mid_point);

ecg_test = x_final(mid_point+1:end);
t_test   = t(mid_point+1:end);

%% ---------------- R Peak Detection ----------------
[pks_base,locs_base,r_base] = detect_rpeaks(ecg_base,t_base,Fs);
[pks_test,locs_test,r_test] = detect_rpeaks(ecg_test,t_test,Fs);

%% ---------------- RR Intervals ----------------
RR_base = diff(r_base);
RR_test = diff(r_test);

RR_base = RR_base(RR_base>=0.3 & RR_base<=2);
RR_test = RR_test(RR_test>=0.3 & RR_test<=2);

RR_base_ms = RR_base*1000;
RR_test_ms = RR_test*1000;

%% ---------------- Time Domain ----------------
RMSSD_base = sqrt(mean(diff(RR_base_ms).^2));
RMSSD_test = sqrt(mean(diff(RR_test_ms).^2));

SDNN_base = std(RR_base_ms);
SDNN_test = std(RR_test_ms);

pNN50_base = 100*mean(abs(diff(RR_base_ms))>50);
pNN50_test = 100*mean(abs(diff(RR_test_ms))>50);

HR_base = mean(60./RR_base);
HR_test = mean(60./RR_test);

%% ---------------- Frequency Domain ----------------
fs_hrv = 4;

[nni_base,f_base,LF_base,HF_base] = compute_freq(RR_base_ms,r_base(2:end),fs_hrv);
[nni_test,f_test,LF_test,HF_test] = compute_freq(RR_test_ms,r_test(2:end),fs_hrv);

LFHF_base = LF_base/(HF_base+eps);
LFHF_test = LF_test/(HF_test+eps);

%% ---------------- Stress Proxy ----------------
S0 = LFHF_base/(RMSSD_base+eps);
S  = LFHF_test/(RMSSD_test+eps);

StressRatio = S/(S0+eps);

StressRatio = min(max(StressRatio,0),2);

StressPercent = 100*(StressRatio/2);

%% ---------------- Stress State ----------------
if StressPercent < 33
    state = 'Low';
    color = [0.7 1 0.7];
elseif StressPercent < 66
    state = 'Moderate';
    color = [1 1 0.6];
else
    state = 'High';
    color = [1 0.6 0.6];
end

%% ---------------- Display Table ----------------
Data = {
'Baseline HR',HR_base;
'Stress HR',HR_test;
'Baseline RMSSD',RMSSD_base;
'Stress RMSSD',RMSSD_test;
'Baseline LF/HF',LFHF_base;
'Stress LF/HF',LFHF_test;
'Stress Ratio',StressRatio;
'Stress %',StressPercent;
'Stress State',state
};

figure('Name','HRV Stress Metrics','Color','w','Position',[200 200 500 320])

t_tab = uitable('Data',Data,...
'ColumnName',{'Metric','Value'},...
'RowName',[],...
'FontSize',12,...
'Position',[20 20 460 280]);

bg = repmat([1 1 1],size(Data,1),1);
bg(end,:) = color;

t_tab.BackgroundColor = bg;

%% ---------------- ECG Plot ----------------
figure

plot(t,x_final,'b')
hold on
plot(r_base,pks_base,'rv','MarkerFaceColor','r')
plot(r_test,pks_test,'g^','MarkerFaceColor','g')

xlabel('Time (s)')
ylabel('mV')
grid on

title(sprintf('Stress %.1f%% (%s)',StressPercent,state))

%% ---------------- Functions ----------------

function [nni_interp,f,LF,HF] = compute_freq(RR_ms,rr_time,fs_hrv)

ti = (rr_time(1):1/fs_hrv:rr_time(end))';

nni_interp = interp1(rr_time(:),RR_ms(:),ti,'pchip');

nni_detrend = detrend(nni_interp);

[pxx,f] = pwelch(nni_detrend,[],[],4096,fs_hrv);

LF = trapz(f(f>=0.04 & f<0.15),pxx(f>=0.04 & f<0.15));
HF = trapz(f(f>=0.15 & f<=0.40),pxx(f>=0.15 & f<=0.40));

end

function [pks,locs,r_times] = detect_rpeaks(x,t,Fs)

xDet = x;

if abs(min(xDet))>max(xDet)
    xDet = -xDet;
end

maxHR = 180;

minDist = round(Fs*(60/maxHR));

prom = 0.35*(max(xDet)-min(xDet));

[pks,locs] = findpeaks(xDet,...
'MinPeakDistance',minDist,...
'MinPeakProminence',prom);

r_times = t(locs);

end