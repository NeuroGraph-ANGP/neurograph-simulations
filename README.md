<div align="center">

# NeuroGraph ANGP v4.3

### Security Simulations

<i>Reproducible simulations for verifying assumptions from the ANGP paper</i>

---

[![License: MIT](https://img.shields.io/badge/License-MIT-9b7eff?style=for-the-badge)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows-4a9eff?style=for-the-badge)]()
[![Shell: PowerShell](https://img.shields.io/badge/Shell-PowerShell-5391F2?style=for-the-badge)]()
[![Release: v4.3.5](https://img.shields.io/badge/Release-v4.3.5-00d4aa?style=for-the-badge)](https://github.com/NeuroGraph-ANGP/neurograph-simulations/releases/latest)

---
</div>

## Quick Start

```powershell
git clone https://github.com/NeuroGraph-ANGP/neurograph-simulations.git
cd neurograph-simulations
.\setup.ps1
```

---

## Test Scripts

| | RUN-TESTS-A.ps1 ![copy](https://img.shields.io/badge/copy-6e7681?style=flat-square) | RUN-NG-BENCHMARK.ps1 ![copy](https://img.shields.io/badge/copy-6e7681?style=flat-square) |
|:---|:---|:---|
| | ![Single Shard](https://img.shields.io/badge/Single_Shard-9b7eff?style=for-the-badge) | ![Multi Shard](https://img.shields.io/badge/Multi_Shard-00d4aa?style=for-the-badge) |
| **Mode** | Single shard | Multi-shard (parallel) |
| **Nodes** | 2664 | 2664 (333 x 8) |
| **Attacker types** | 37 (T0-T36) | 37 (T0-T36) |
| **Attacker %** | 0 to 99% | 0 to 99% |
| **Key config** | Steps: 10K-100K | Shards: 100-444 |
| **Options** | Security / Clean / Resistance / Quick / Batch | Clean / Attack / Scaled / Custom / Info |
| **Purpose** | Test adversarial pressure at different intensities within one shard | Benchmark TPS, latency and security across distributed multi-shard network |

## Reproducing Paper Results

> **1.** Run `.\RUN-NG-BENCHMARK.ps1` for the full multi-shard benchmark
> **2.** Run `.\RUN-TESTS-A.ps1` for single-shard security analysis
> **3.** Compare your results with the paper's reported values

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
