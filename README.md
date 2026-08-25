<div align="center">

# NeuroGraph ANGP v4.3.1

### Security an Scalability Simulations

<i>Reproducible simulations for verifying assumptions from the ANGP paper</i>

---

[![Platform: Windows](https://img.shields.io/badge/Platform-Windows-4a9eff?style=for-the-badge)]()
[![Shell: PowerShell](https://img.shields.io/badge/Shell-PowerShell-5391F2?style=for-the-badge)]()
[![Release: v4.3.1](https://img.shields.io/badge/Release-v4.3.1-00d4aa?style=for-the-badge)](https://github.com/NeuroGraph-ANGP/neurograph-simulations/releases/latest)

---
</div>

## Quick Start

| | RUN-TESTS-A | RUN-NG-BENCHMARK |
|:---|:---|:---|
| **Mode** | Single shard | Multi-shard (parallel) |
| **Nodes** | 2664 | 2664 (333 x 8) |
| **Attacker types** | 37 (T0-T36) | 37 (T0-T36) |
| **Attacker %** | 0 to 99% | 0 to 99% |
| **Key config** | Steps: 10K-100K | Shards: 100-444 |
| **Options** | Security / Clean / Resistance / Quick / Batch | Clean / Attack / Scaled / Custom / Info |
| **Purpose** | Test adversarial pressure at different intensities within one shard | Benchmark TPS, latency and security across distributed multi-shard network |

---

## How to Run

Follow these steps in order:

**1. Setup** (first time only):

```powershell
git clone https://github.com/NeuroGraph-ANGP/neurograph-simulations.git
cd neurograph-simulations
.\setup.ps1
```

**2. Run simulation** (choose one):

```powershell
.\RUN-TESTS-A.ps1
```

```powershell
.\RUN-NG-BENCHMARK.ps1
```

**3. Compare** your results with the  paper's reported values

**4. Whitepaper:** https://neurograph-angp.surge.sh/whitepaper.html


   **Note**: For best TPS results, run simulation on a cool system shortly after restart,
   as prolonged runtime and thermal throttling can significantly reduced observed throughput.
   
   **Important**: If you are running the simulations on a laptop, make sure it is plugged
   into AC power. Running on battery can significantly reduce CPU performance due to power-saving
   and thermal-management limits, resulting in substantially lower simulation performance and TPS.
   
---

## System Requirements

[![Windows](https://img.shields.io/badge/OS-Windows_10_/_11-4a9eff?style=flat-square)]()
[![PowerShell](https://img.shields.io/badge/Shell-PowerShell_5.1+-5391F2?style=flat-square)]()
[![Internet](https://img.shields.io/badge/Internet-first_run_only-888?style=flat-square)]()

---

<div align="center">

**MIT License** -- simulations and test scripts

The ANGP engine binary is provided for verification purposes only.

</div>
