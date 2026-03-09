%% ============================================================
% Full code: Load ECG + Notch filter + Detect R-peaks
% + Compare against MIT-BIH .atr (ground truth) + metrics + plots
% Works with WFDB Toolbox (rdsamp, rdann)
% ============================================================

clear; clc; close all;

%% -------------------- SETTINGS --------------------
recordName = '232';      % MIT-BIH record (e.g., '100', '232', ...)
annName    = 'atr';      % annotation file
f0         = 50;         % notch frequency (Hz)
Q          = 35;         % notch quality factor (higher = narrower notch)
tol_ms     = 100;        % matching tolerance (ms) for evaluation
tol_s      = tol_ms/1000;

% Visual window (seconds)
visStart = 0;
visLen   = 10;

% Optional: evaluate on full record; visuals only show a window
useFullForEval = true;

%% -------------------- LOAD ECG --------------------
[signal, Fs, tm] = rdsamp(recordName);
raw_ecg = signal(:,1);

t = (0:length(raw_ecg)-1)'/Fs;

fprintf('Sampling Frequency (Fs): %.0f Hz\n', Fs);
fprintf('Signal Length: %d samples (%.2f minutes)\n', length(raw_ecg), length(raw_ecg)/Fs/60);

%% -------------------- NOTCH FILTER (50 Hz) --------------------
wo = f0/(Fs/2);
bw = wo/Q;
[b,a] = iirnotch(wo,bw);

ecg_filt = filtfilt(b,a,raw_ecg);

%% -------------------- LOAD GROUND TRUTH (ATR) --------------------
% Your toolbox returns arrays, not struct -> use this:
[ref_samp, ref_type] = rdann(recordName, annName);

ref_samp = ref_samp(:);
ref_type = char(ref_type);  % ensure char array

ref_time = ref_samp / Fs;

% Keep only common beat symbols (recommended)
beatSyms = ['N','L','R','A','V','F','/','E','j','a','S','J','e','Q'];
keep = ismember(ref_type, beatSyms);

ref_samp = ref_samp(keep);
ref_time = ref_time(keep);
ref_type = ref_type(keep);

fprintf('Reference annotated beats (kept): %d\n', length(ref_time));

%% -------------------- DETECT YOUR R-PEAKS --------------------
[pks, det_locs, det_time] = detect_rpeaks_findpeaks(ecg_filt, t, Fs);

fprintf('Detected peaks: %d\n', length(det_time));

%% -------------------- OPTIONAL: EVALUATE ON FULL OR WINDOW --------------------
if ~useFullForEval
    maskRef = ref_time >= visStart & ref_time <= (visStart + visLen);
    maskDet = det_time >= visStart & det_time <= (visStart + visLen);
    ref_eval = ref_time(maskRef);
    det_eval = det_time(maskDet);
else
    ref_eval = ref_time;
    det_eval = det_time;
end

%% -------------------- MATCH DETECTED vs TRUE (±tol) --------------------
[TP, FP, FN, match_det_idx, match_ref_idx, time_errors_ms] = match_peaks(det_eval, ref_eval, tol_s);

precision = TP / max(TP+FP, 1);
recall    = TP / max(TP+FN, 1);           % sensitivity
F1        = 2*precision*recall / max(precision+recall, 1e-12);

meanAbsErr   = mean(abs(time_errors_ms));
medianAbsErr = median(abs(time_errors_ms));

fprintf('\n========== R-PEAK EVALUATION vs ATR ==========\n');
fprintf('Tolerance: ±%d ms\n', tol_ms);
fprintf('TP: %d | FP: %d | FN: %d\n', TP, FP, FN);
fprintf('Precision (PPV): %.4f\n', precision);
fprintf('Recall (Sens.) : %.4f\n', recall);
fprintf('F1-score       : %.4f\n', F1);
fprintf('Mean |time error| (ms)   : %.2f\n', meanAbsErr);
fprintf('Median |time error| (ms) : %.2f\n', medianAbsErr);

%% -------------------- VISUAL COMPARISON (10s WINDOW) --------------------
visMask = (t >= visStart) & (t <= visStart + visLen);

ref_in = ref_time(ref_time >= visStart & ref_time <= visStart+visLen);
det_in = det_time(det_time >= visStart & det_time <= visStart+visLen);

det_in_samp = round(det_in*Fs);
det_in_samp(det_in_samp < 1) = 1;
det_in_samp(det_in_samp > length(ecg_filt)) = length(ecg_filt);

figure;
plot(t(visMask), ecg_filt(visMask), 'b'); hold on; grid on;
xlabel('Time (s)'); ylabel('mV');
title(sprintf('Filtered ECG with True (ATR) vs Detected R-peaks | tol=±%d ms', tol_ms));

% True peaks: green vertical lines
for k = 1:length(ref_in)
    xline(ref_in(k), 'g', 'LineWidth', 1);
end

% Detected peaks: red triangles
plot(det_in, ecg_filt(det_in_samp), 'rv', 'MarkerFaceColor','r');

legend('Filtered ECG','True R-peaks (ATR)','Detected R-peaks');

%% -------------------- NUMERIC SUMMARY BAR --------------------
figure;
bar([TP FP FN]);
grid on;
set(gca,'XTickLabel',{'TP','FP','FN'});
title('Detection Summary (TP / FP / FN)');
ylabel('Count');

%% -------------------- TIMING ERROR HISTOGRAM --------------------
if ~isempty(time_errors_ms)
    figure;
    histogram(time_errors_ms, 30);
    grid on;
    xlabel('Timing Error (ms)  [Detected - True]');
    ylabel('Count');
    title('Timing Error Distribution');
end

%% ============================================================
% LOCAL FUNCTIONS
%% ============================================================

function [pks, locs, r_times] = detect_rpeaks_findpeaks(x, t, Fs)
    % Ensure we detect upward R-peaks; flip if negative spikes dominate
    xDet = x;
    if abs(min(xDet)) > max(xDet)
        xDet = -xDet;
    end

    % Minimum distance between beats based on max HR
    maxHR = 180; % bpm
    minDist = round(Fs*(60/maxHR));

    % Prominence threshold based on signal range (tune if needed)
    prom = 0.35 * (max(xDet)-min(xDet));

    [pks, locs] = findpeaks(xDet, ...
        'MinPeakDistance', minDist, ...
        'MinPeakProminence', prom);

    r_times = t(locs);
end

function [TP, FP, FN, detMatchIdx, refMatchIdx, err_ms] = match_peaks(det_t, ref_t, tol_s)
    % One-to-one greedy matching: each detected peak matches at most 1 ref peak.
    detMatch = false(size(det_t));
    refMatch = false(size(ref_t));

    detMatchIdx = [];
    refMatchIdx = [];
    err_ms = [];

    j = 1; % detected pointer
    for i = 1:length(ref_t)
        while j <= length(det_t) && det_t(j) < ref_t(i) - tol_s
            j = j + 1;
        end
        if j > length(det_t)
            break;
        end

        % search candidates within tolerance
        k = j;
        bestK = 0;
        bestErr = inf;

        while k <= length(det_t) && det_t(k) <= ref_t(i) + tol_s
            if ~detMatch(k)
                e = abs(det_t(k) - ref_t(i));
                if e < bestErr
                    bestErr = e;
                    bestK = k;
                end
            end
            k = k + 1;
        end

        if bestK ~= 0
            detMatch(bestK) = true;
            refMatch(i) = true;

            detMatchIdx(end+1,1) = bestK; %#ok<AGROW>
            refMatchIdx(end+1,1) = i;     %#ok<AGROW>
            err_ms(end+1,1) = (det_t(bestK) - ref_t(i))*1000; %#ok<AGROW>
        end
    end

    TP = sum(refMatch);
    FP = sum(~detMatch);
    FN = sum(~refMatch);
end