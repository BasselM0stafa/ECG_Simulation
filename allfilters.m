%% ================= ECG Complete Filter Pipeline — Visual Before vs After =================
% This script applies High-Pass (0.5Hz), Low-Pass (30Hz), and Notch (50Hz) filters.
clear; close all; clc;

%% ---------- Load ECG ----------
recordName = '232'; 
[signal, Fs, tm] = rdsamp(recordName);
raw_ecg = signal(:,1);

%% ---------- Window for clear plots (first 10 seconds) ----------
Tshow = 10; 
Nshow = min(round(Tshow*Fs), length(raw_ecg));
t = (0:Nshow-1)/Fs;
x_raw = raw_ecg(1:Nshow);

% =================================================================
% STAGE 1: High-Pass Filter (Baseline Wander Removal)
% =================================================================
% Target: Remove frequencies < 0.5 Hz
order_hp = 4;
fc_hp    = 0.5; % Hz
[b_hp, a_hp] = butter(order_hp, fc_hp/(Fs/2), 'high');
x_hp = filtfilt(b_hp, a_hp, x_raw);

% =================================================================
% STAGE 2: Low-Pass Filter (Muscle Artifact Removal)
% =================================================================
% Target: Remove frequencies > 30 Hz
order_lp = 4;
fc_lp    = 30; % Hz
[b_lp, a_lp] = butter(order_lp, fc_lp/(Fs/2), 'low');
x_lp = filtfilt(b_lp, a_lp, x_hp);

% =================================================================
% STAGE 3: Notch Filter (Powerline 50 Hz Removal)
% =================================================================
f0 = 50; % Hz
Q  = 35; 
[b_n, a_n] = iirnotch(f0/(Fs/2), (f0/Q)/(Fs/2)); 
x_final = filtfilt(b_n, a_n, x_lp); % Final clean signal

%% ===================== Figure 1: Time domain (Before vs After) =====================
figure('Name','ECG Full Filtering (Time Domain)');
subplot(2,1,1);
plot(t, x_raw, 'b'); grid on;
title('Raw ECG (Noisy)'); ylabel('Amplitude (mV)');

subplot(2,1,2);
plot(t, x_final, 'g', 'LineWidth', 1.2); grid on;
title('Clean ECG (HP 0.5Hz + LP 30Hz + Notch 50Hz)'); 
xlabel('Time (s)'); ylabel('Amplitude (mV)');

%% ===================== Figure 2: Spectrum Comparison =====================
N = length(x_raw);
f = (0:N-1)*(Fs/N);
mask = (f <= 100);

Xraw = 20*log10(abs(fft(x_raw)/N)+eps);
Xfil = 20*log10(abs(fft(x_final)/N)+eps);

figure('Name','Spectrum Comparison');
plot(f(mask), Xraw(mask), 'b'); hold on;
plot(f(mask), Xfil(mask), 'r', 'LineWidth', 1);
grid on;
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title('Frequency Spectrum: Raw vs. Fully Filtered');
legend('Raw','Fully Filtered');