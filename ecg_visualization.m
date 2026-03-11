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