<div align="center">

# NeuroGraph ANGP v4.3

### Security an Scalability Simulations

<i>Reproducible simulations for verifying assumptions from the ANGP paper</i>

---

[![License: MIT](https://img.shields.io/badge/License-MIT-9b7eff?style=for-the-badge)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows-4a9eff?style=for-the-badge)]()
[![Shell: PowerShell](https://img.shields.io/badge/Shell-PowerShell-5391F2?style=for-the-badge)]()
[![Release: v4.3.1](https://img.shields.io/badge/Release-v4.3.1-00d4aa?style=for-the-badge)](https://github.com/NeuroGraph-ANGP/neurograph-simulations/releases/latest)

---
</div>

## Quick Start

Clone the repo and run setup:

```powershell
git clone https://github.com/NeuroGraph-ANGP/neurograph-simulations.git
cd neurograph-simulations
.\setup.ps1
```

---
---

## Test Scripts

Choose one script and click Copy to run it:

```powershell
.\RUN-TESTS-A.ps1
```

```powershell
.\RUN-NG-BENCHMARK.ps1
```

| | .\RUN-TESTS-A.ps1 | .\RUN-NG-BENCHMARK.ps1 |
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

**2. Warmup** (optional):

```powershell
.\RUN-WARMUP-BOOTSTRAP.ps1 
```

**3. Run simulation** (choose one):

```powershell
.\RUN-TESTS-A.ps1
```

```powershell
.\RUN-NG-BENCHMARK.ps1
```

**4. Compare** your results with the ANGP paper

---

## Reproducing Paper Results

1. Run `.\RUN-WARMUP-BOOTSTRAP.ps1` to warm up the engine and stabilize baseline metrics
2. Run `.\RUN-NG-BENCHMARK.ps1` for the full multi-shard benchmark
3. Run `.\RUN-TESTS-A.ps1` for single-shard security analysis
4. Compare your results with the paper's reported values

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
