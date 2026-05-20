# Adaptive Low-Power UART Communication System
### with ML-Based Traffic Prediction for IoT Edge Devices

Hey! This is my final year B.E. project (VLSI Design & Technology, S.A. Engineering College).

The basic idea: normal UART receivers stay ON all the time, even when there's no data being sent — which wastes a lot of power in IoT devices. So I built a system that *predicts* when data is coming using a simple ML model, and puts the receiver to sleep when it's not needed.

This project was presented at **InnoTech M'26 National Conference** (April 2026) 🎉

---

## What does it actually do?

Imagine your IoT sensor sends data in bursts — active for a few seconds, then quiet for a while. Instead of keeping the receiver running the whole time, my system learns that pattern and powers down during the quiet periods automatically.

- Predicts traffic using a Decision Tree classifier
- Controls power using a 3-state FSM (ACTIVE → SLEEP → WAKEUP)
- Achieved ~57% static power reduction in Vivado simulation
- Zero packet loss verified in testbench

---

## Project Structure

```
adaptive-uart-ml-power/
│
├── rtl/                        # All Verilog source files
│   ├── uart_tx.v               # UART Transmitter
│   ├── uart_rx.v               # UART Receiver
│   ├── traffic_monitor.v       # Monitors incoming traffic patterns
│   ├── ml_predictor.v          # Decision Tree logic (Verilog)
│   ├── power_controller.v      # 3-state FSM (ACTIVE/SLEEP/WAKEUP)
│   ├── baud_rate_controller.v  # Dynamic baud rate control
│   └── top_module.v            # Integrates everything together
│
├── testbench/
│   └── tb_top.v                # Main testbench for simulation
│
├── ml/                         # Python ML code
│   ├── train_model.py          # Trains the Decision Tree
│   ├── generate_verilog.py     # Converts model → Verilog logic
│   └── dataset_gen.py          # Synthetic dataset generation
│
├── constraints/
│   └── uart_constraints.xdc    # Vivado timing constraints
│
├── simulation/
│   └── waveform_notes.md       # What to look for in simulation
│
└── README.md                   # You're reading this!
```

---

## Tools Used

| Tool | What I used it for |
|------|-------------------|
| Xilinx Vivado | RTL synthesis, simulation, power analysis |
| Python 3.x | Training the ML model |
| Scikit-learn | Decision Tree classifier |
| NumPy / pandas | Dataset handling |
| ModelSim | Functional simulation |

---

## How the ML part works

I generated a synthetic dataset of 5,000 samples with 3 features:
- **Inter-arrival time** — how long between packets
- **Packet size** — how big each packet is
- **Time of day** — traffic varies by time (IoT patterns)

Trained a Decision Tree (max depth = 5) to classify traffic as ACTIVE or SLEEP. Then extracted the decision rules and manually converted them into synthesisable Verilog — no floating point math needed in hardware!

```python
# Quick look at training
from sklearn.tree import DecisionTreeClassifier
model = DecisionTreeClassifier(max_depth=5, random_state=42)
model.fit(X_train, y_train)
```

---

## Results (Xilinx Vivado Power Report)

| Metric | Value |
|--------|-------|
| Static Power | 0.224 W |
| Total Power | 3.49 W |
| Power Reduction (vs always-ON) | ~57% average |
| Area Overhead | < 10% |
| Packet Loss | Zero (verified in testbench) |

---

## How to simulate

1. Open Xilinx Vivado
2. Create new project → add all files from `rtl/` and `testbench/`
3. Run Behavioral Simulation
4. In the waveform, check:
   - `power_state` signal transitions (should go ACTIVE → SLEEP → WAKEUP)
   - `tx_data` and `rx_data` match (no data loss)
   - `baud_rate` changes dynamically

---

## Team

- **Poojitha S** — RTL design, ML model, testbench, report writing
- **Ahalya A** — Literature review, simulation support
- **Rahmath Ussra S** — Documentation, testing

**Guide:** Dr. Anandha Praba R, S.A. Engineering College

---

## Conference

📄 Paper: *"Adaptive Low-Power UART Communication System using ML-Based Traffic Prediction for IoT Edge Devices"*

🏛️ Presented at: InnoTech M'26 — National Conference on Innovation in Engineering & Management
GRT Institute of Engineering & Technology, Tiruttani — April 2026

---

## About Me

I'm Poojitha, a final year Electronics Engineering (VLSI) student from Chennai.
Currently looking for VLSI/Embedded internships and research opportunities!

📧 poojitha260806@gmail.com
🔗 [LinkedIn](https://linkedin.com/in/poojitha-s26)
