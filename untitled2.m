%% ================= ECG Notch Filter (50 Hz) — Visual Before vs After =================
% New script (standalone). Just press RUN.
% Requirements:
%   - WFDB toolbox is working (rdsamp works)
%   - You are in the folder that contains the record files (232.dat/.hea etc)
%
% What you will see:
%   Figure 1: Time-domain ECG (0–10 s) before vs after notch
%   Figure 2: Spectrum (0–100 Hz) before vs after notch
%   Figure 3: Zoomed spectrum (45–55 Hz) to show the notch at 50 Hz

clear; close all; clc;

%% ---------- Load ECG ----------
recordName = '232';                 % change if you want another record
[signal, Fs, tm] = rdsamp(recordName);
raw_ecg = signal(:,1);

fprintf('Sampling Frequency (Fs): %.0f Hz\n', Fs);
fprintf('Signal Length: %d samples\n', length(raw_ecg));
fprintf('Total Duration: %.2f minutes\n', length(raw_ecg)/Fs/60);

%% ---------- Take a clean window for clear plots (first 10 seconds) ----------
Tshow = 10;                                  % seconds
Nshow = min(round(Tshow*Fs), length(raw_ecg));
t = (0:Nshow-1)/Fs;

x_raw = raw_ecg(1:Nshow);

%% ---------- Notch Filter at 50 Hz ----------
f0 = 50;                      % notch frequency
Q  = 35;                      % Quality factor (higher = narrower notch)
bw = f0/Q;                    % bandwidth (Hz)

% iirnotch needs normalized frequencies (0..1), where 1 corresponds to Fs/2
wo = f0/(Fs/2);
bw_n = bw/(Fs/2);

[b,a] = iirnotch(wo, bw_n);

% Apply zero-phase filtering to avoid delay
x_filt = filtfilt(b,a, x_raw);

%% ===================== Figure 1: Time domain (Before vs After) =====================
figure('Name','ECG Before vs After Notch (Time Domain)');
plot(t, x_raw); hold on;
plot(t, x_filt);
grid on;
xlabel('Time (s)');
ylabel('Amplitude (mV)');
title(sprintf('ECG (0–%.0f s): Raw vs 50 Hz Notch Filtered', Tshow));
legend('Raw','Notch filtered','Location','best');

%% ===================== Spectrum helper (FFT) =====================
% Use the same length for both signals
N = length(x_raw);
Xraw = fft(x_raw);
Xfil = fft(x_filt);

% Frequency axis (Hz)
f = (0:N-1)*(Fs/N);

% Single-sided mask up to 100 Hz
fmax = 100;
mask = (f <= fmax);

% Magnitude in dB (avoid log(0))
RAWmag = 20*log10(abs(Xraw)+eps);
FILmag = 20*log10(abs(Xfil)+eps);

%% ===================== Figure 2: Spectrum 0–100 Hz =====================
figure('Name','Spectrum Before vs After Notch (0–100 Hz)');
plot(f(mask), RAWmag(mask)); hold on;
plot(f(mask), FILmag(mask));
grid on;
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('Spectrum Before vs After Notch (0–100 Hz)');
legend('Raw','Notch filtered','Location','best');

%% ===================== Figure 3: Zoom 45–55 Hz =====================
zoomMask = (f >= 45) & (f <= 55);

figure('Name','Zoomed Spectrum (45–55 Hz)');
plot(f(zoomMask), RAWmag(zoomMask)); hold on;
plot(f(zoomMask), FILmag(zoomMask));
grid on;
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('Zoomed Spectrum (45–55 Hz) — Notch at 50 Hz');
legend('Raw','Notch filtered','Location','best');

%% ---------- Optional: show the filter frequency response ----------
% Uncomment if you want to include it in report
% figure('Name','Notch Filter Frequency Response');
% freqz(b,a,2048,Fs);
% title('50 Hz Notch Filter Response');