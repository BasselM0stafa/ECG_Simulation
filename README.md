# ECG Signal Simulation & Analysis

A MATLAB & Simulink project that mathematically simulates a human ECG signal using a sum of Gaussian functions, models physiological noises and instrumentation amplifiers, and analyzes real-world ECG data (MIT-BIH) for noise filtering, R-peak detection, and Heart Rate Variability (HRV) stress analysis.

---

## 📁 Project Files

| File | Description |
|---|---|
| `regularRythm.mlx` | MATLAB Live Script — mathematically simulates a clean periodic ECG signal |
| `irregularRythm.mlx` | MATLAB Live Script — simulates an arrhythmic ECG with random beat timing |
| `InAmpCode.slx` & `InAmpCircuit.slx` | Simulink models — add noise, amplify, and optionally filter the signal |
| `notchfilter.m` | Implements a 50 Hz Notch filter on MIT-BIH data to remove powerline noise |
| `allfilters.m` | Complete filter pipeline (High-Pass 0.5Hz, Low-Pass 30Hz, Notch 50Hz) |
| `Rpeaks detected on fully filtered.m` | R-peak detection, HR, and HRV analysis on filtered ECG data |
| `evaluate.m` | Evaluates R-peak detection precision and recall against MIT-BIH `.atr` annotations |
| `stress.m` | Calculates HRV metrics (LF/HF, RMSSD) to determine physical stress levels |

---

## ▶️ Execution Pipeline (How to Run)

The project follows a linear, step-by-step execution pipeline:

### Step 1: Generate the Signal
Run one of the following MATLAB Live Scripts to generate the core ECG signal and load it into your MATLAB workspace:
- **Regular Rhythm:** Open `regularRythm.mlx` and press **Run**.
- **Arrhythmia:** Open `irregularRythm.mlx` and press **Run**. *(To fix the randomized pattern, add `rng(42)` before the beat generation).*

### Step 2: Add Noise, Amplify, & Filter (Simulink)
Once the base signal is in your workspace, process it through one of the Simulink models. The models inject physiological noise (50 Hz powerline, 120 Hz muscle artifact, 0.2 Hz baseline wander).
- **Option A (Amplify Only):** Open and run `InAmpCode.slx` to add noise and process the signal through an Instrumentation Amplifier stage.
- **Option B (Amplify & Filter):** Open and run `InAmpCircuit.slx` to add noise, amplify, and additionally run the signal through a filter circuit.

*(Press **Run (▶)** in Simulink. You can view the output via the Scope block, and the final processed result is automatically returned to the MATLAB workspace).*

### Step 3: Analysis & Visualization (MATLAB)
With the fully processed result returned to your MATLAB workspace, run the remaining code for plotting and analysis:
- **Visuals & Spectral Analysis:** Run the rest of the MATLAB code to view time-domain overlays and frequency spectrum responses.
- **R-Peak & Heart Rate:** Run standard detection steps to calculate the RR interval, detect R-peaks, and output the Heart Rate.
- **Further Evaluation (Optional):** Use `evaluate.m` or `stress.m` to compute advanced HRV metrics.
