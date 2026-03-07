# ECG Signal Simulation

A MATLAB & Simulink project that mathematically simulates a human ECG signal using a sum of Gaussian functions, with regular and arrhythmic rhythms, physiological noise sources, and instrumentation amplifier modeling.

---

## 📁 Project Files

| File | Description |
|---|---|
| `regularRythm.mlx` | MATLAB Live Script — clean periodic ECG signal |
| `irregularRythm.mlx` | MATLAB Live Script — arrhythmic ECG with random beat timing |
| `InAmp.slx` | Simulink model — ECG with noise sources + amplification |

---

## ▶️ How to Run

### Part 1 — Regular ECG (MATLAB)

1. Open `regularRythm.mlx` in MATLAB
2. Press **Run**
3. Output: time-domain ECG plot + frequency spectrum (dB)

> Adjust `duration`, `fs`, and `beat_every` at the top to control simulation length, sampling rate, and beat period.

---

### Part 2 — Arrhythmia ECG (MATLAB)

1. Open `irregularRythm.mlx` in MATLAB
2. Press **Run**
3. Output: ECG with randomly spaced beats simulating arrhythmia

> Each run produces a **different** rhythm pattern due to random beat timing.  
> To fix the pattern, add `rng(42)` before the beat onset generation line.

**Tuning irregularity:** change the `0.8` factor in the `cumsum` line:
- `0.2` → mild arrhythmia
- `0.8` → strong arrhythmia

---

### Part 3 — Noisy ECG + Amplification (Simulink)

1. Run **Part 1 or Part 2** first to load `ecg_sim` into the workspace
2. Open `InAmp.slx` in MATLAB:
   ```matlab
   open('InAmp.slx')
   ```
3. Press **Run (▶)** in Simulink
4. Open the **Scope** block to view the output

> The model adds three noise sources:
> - **Powerline** — 50 Hz interference
> - **Muscle artifact** — 120 Hz high-frequency noise
> - **Baseline wander** — 0.2 Hz slow drift
>
> An instrumentation amplifier (InAmp) stage then processes the combined signal.
