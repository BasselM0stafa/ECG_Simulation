% 1. Import the ECG signal into MATLAB (Using WFDB)
recordName = '232';
[signal, Fs, tm] = rdsamp(recordName);

% Extract just the first column (Channel 1 of the ECG)
raw_ecg = signal(:, 1);

% 2. Determine Sampling frequency (Fs)
% Fs is automatically pulled from the .hea file by rdsamp
disp(['Sampling Frequency (Fs): ', num2str(Fs), ' Hz']);

% 3. Determine Signal length
% Using the 'length' function as requested by your rubric
signal_length = length(raw_ecg);
disp(['Signal Length: ', num2str(signal_length), ' total samples']);

% Optional: Re-calculate time vector using 'linspace' (from your rubric)
% Total time in seconds = (number of samples) / Fs
total_time_seconds = signal_length / Fs;
time_vector = linspace(0, total_time_seconds, signal_length);

% 4. Plot the raw ECG signal before processing
figure;
plot(time_vector, raw_ecg, 'b'); % Plotting using your new time_vector
xlabel('Time (seconds)');
ylabel('Amplitude (mV)');
title('Raw ECG Signal - MIT-BIH Record 232');
grid on;

% Zoom in on the first 10 seconds so it looks readable
xlim([0 10]);
%% ==============================
%  ECG Task — Person 1 + Person 2 (Notch Only) + Clear Before/After Proof
%  Dataset: MIT-BIH (example record 232)
%  Outputs:
%   1) Raw ECG (0–10 s)
%   2) Notch-filtered ECG (0–10 s)
%   3) Overlay raw vs filtered (0–10 s)
%   4) Notch filter response (freqz)
%   5) Spectrum before vs after (dB, 0–100 Hz)
%   6) Zoomed spectrum (45–55 Hz) to clearly show the notch effect
%% ==============================

clear; clc; close all;

%% ---- (A) Load ECG using WFDB ----
% Make sure you are in the folder that contains 232.dat / 232.hea / 232.atr
% Example:
% cd('C:\ECG_Project\data\mit-bih-arrhythmia-database-1.0.0\mit-bih-arrhythmia-database-1.0.0');

recordName = '232';
[signal, Fs, tm] = rdsamp(recordName);

raw_ecg = signal(:,1);                 % channel 1
signal_length = length(raw_ecg);

disp(['Sampling Frequency (Fs): ', num2str(Fs), ' Hz']);
disp(['Signal Length: ', num2str(signal_length), ' total samples']);

time_vector = (0:signal_length-1) / Fs;

%% ---- Plot RAW ECG (first 10 seconds) ----
tEnd = 10;                             % seconds
idx10 = time_vector <= tEnd;

figure;
plot(time_vector(idx10), raw_ecg(idx10), 'b');
grid on;
xlabel('Time (s)');
ylabel('Amplitude (mV)');
title(['Raw ECG Signal - MIT-BIH Record ', recordName, ' (0–10 s)']);

%% ---- (B) Person 2: 50 Hz Notch Filter ONLY ----
f0 = 50;                 % Hz
wo = f0/(Fs/2);           % normalized notch freq
Q  = 35;                  % quality factor (narrow notch)
bw = wo/Q;                % normalized bandwidth

[b,a] = iirnotch(wo, bw);

% Zero-phase filtering to avoid waveform distortion
ecg_notch = filtfilt(b, a, raw_ecg);

%% ---- Plot FILTERED ECG (first 10 seconds) ----
figure;
plot(time_vector(idx10), ecg_notch(idx10), 'b');
grid on;
xlabel('Time (s)');
ylabel('Amplitude (mV)');
title(['ECG After 50 Hz Notch Filter - Record ', recordName, ' (0–10 s)']);

%% ---- Clear Before/After Comparison (Overlay) ----
% To make the difference visible even if small, we:
% 1) overlay raw and filtered
% 2) zoom y-limits automatically based on this 10-second segment

seg_raw = raw_ecg(idx10);
seg_flt = ecg_notch(idx10);

ymin = min([seg_raw; seg_flt]);
ymax = max([seg_raw; seg_flt]);
pad  = 0.10*(ymax - ymin + eps);

figure;
plot(time_vector(idx10), seg_raw, 'b'); hold on;
plot(time_vector(idx10), seg_flt, 'r');
grid on;
xlabel('Time (s)');
ylabel('Amplitude (mV)');
title('Before vs After (Overlay) - 0–10 s');
legend('Raw','Notch filtered');
ylim([ymin-pad, ymax+pad]);

%% ---- (C) Filter Proof 1: Frequency Response ----
figure;
freqz(b, a, 4096, Fs);
title('50 Hz Notch Filter Frequency Response');

%% ---- (D) Filter Proof 2: Spectrum Before vs After (dB) ----
% Why your previous spectrum looked "minimized":
% linear FFT magnitude can create a huge y-scale that squashes both curves.
% Using dB + window + zoom around 50 Hz makes the notch effect visible.

N = length(seg_raw);
w = hann(N);

RAW = fft(seg_raw .* w);
FIL = fft(seg_flt .* w);

F = (0:N-1)*(Fs/N);

RAWdB = 20*log10(abs(RAW) + 1e-12);
FILdB = 20*log10(abs(FIL) + 1e-12);

% Plot 0–100 Hz
mask = F <= 100;

figure;
plot(F(mask), RAWdB(mask), 'b'); hold on;
plot(F(mask), FILdB(mask), 'r');
grid on;
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('Spectrum Before vs After Notch (dB, 0–100 Hz)');
legend('Raw','Notch filtered');

% Zoom 45–55 Hz to clearly show notch effect at 50 Hz
mask2 = (F >= 45) & (F <= 55);

figure;
plot(F(mask2), RAWdB(mask2), 'b'); hold on;
plot(F(mask2), FILdB(mask2), 'r');
grid on;
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('Zoomed Spectrum (45–55 Hz) — Clear Notch at 50 Hz');
legend('Raw','Notch filtered');

%% ---- (Optional) Save figures as PDF/PNG (uncomment if needed) ----
% exportgraphics(figure(1), 'raw_ecg_0_10s.png');
% exportgraphics(figure(2), 'notch_ecg_0_10s.png');
% exportgraphics(figure(3), 'overlay_before_after.png');
% exportgraphics(figure(4), 'notch_freq_response.png');
% exportgraphics(figure(5), 'spectrum_0_100Hz_dB.png');
% exportgraphics(figure(6), 'spectrum_zoom_45_55Hz_dB.png');
%% ============================================================
% FINAL CODE: R-Peak Detection + HR + HRV Stress (Baseline-normalized)
% Uses: filtered ECG (notch 50 Hz) from MIT-BIH record (e.g., 232)
% Output:
%  - R-peaks plot (10 s snippet)
%  - HR (mean bpm)
%  - HRV: RMSSD, SDNN, pNN50, LF/HF
%  - Stress% (0–100) vs baseline 5 min
%% ============================================================

clear; clc; close all;

%% ---- Set your data folder (edit if needed) ----
% cd('C:\ECG_Project\data\mit-bih-arrhythmia-database-1.0.0\mit-bih-arrhythmia-database-1.0.0');

recordName = '232';
[signal, Fs, tm] = rdsamp(recordName);
raw_ecg = signal(:,1);

N = length(raw_ecg);
t = (0:N-1)'/Fs;

disp(['Fs = ', num2str(Fs), ' Hz']);
disp(['Signal length = ', num2str(N), ' samples']);
disp(['Total duration (min) = ', num2str(t(end)/60)]);

%% =========================
% Notch filter only (50 Hz)
%% =========================
f0 = 50;
wo = f0/(Fs/2);
Q  = 35;                 % narrower notch = higher Q
bw = wo/Q;

[b,a] = iirnotch(wo, bw);
ecg_filt = filtfilt(b,a,raw_ecg);
