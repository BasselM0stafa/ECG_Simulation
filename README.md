# ECG Signal Simulation

A MATLAB & Simulink project that mathematically simulates a human ECG signal using a sum of Gaussian functions, with added physiological noise sources and instrumentation amplifier modeling.

---

## 📁 Project Files

| File | Description |
|---|---|
| `regularRythm.mlx` | MATLAB Live Script — generates a clean, periodic ECG signal |
| `InAmp.slx` | Simulink model — ECG signal with noise sources + amplification |

---

## ▶️ How to Run

### Part 1 — Clean ECG Signal (MATLAB)

1. Open **MATLAB**
2. Open `regularRythm.mlx`
3. Press **Run** (or `Ctrl+Enter` section by section)
4. Output: time-domain ECG plot and frequency spectrum (dB)

> You can adjust `duration`, `fs`, and `beat_every` at the top of the script to control simulation length, sampling rate, and beat period.

---

### Part 2 — Noisy ECG + Amplification (Simulink)

1. Open **MATLAB**
2. In the MATLAB command window, run:
   ```matlab
   open('InAmp.slx')
   ```
3. Press the **Run** button (▶) in Simulink
4. Open the **Scope** block to view the output signal

> The model adds three noise sources to the ECG:
> - **Powerline interference** — 50 Hz sinusoidal noise
> - **Muscle artifact** — 120 Hz high-frequency noise  
> - **Baseline wander** — 0.2 Hz slow drift
>
> An instrumentation amplifier (InAmp) stage processes the combined signal.

