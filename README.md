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

| | RUN-TESTS-A.ps1 ![Single Shard](https://img.shields.io/badge/-Single_Shard-9b7eff?style=flat-square) | RUN-NG-BENCHMARK.ps1 ![Multi Shard](https://img.shields.io/badge/-Multi_Shard-00d4aa?style=flat-square) |
|:---|:---|:---|
| **Mode** | Single shard | Multi-shard (parallel) |
| **Nodes** | 2664 | 2664 (333 x 8) |
| **Attacker types** | 37 (T0-T36) | 37 (T0-T36) |
| **Attacker %** | 0 to 99% | 0 to 99% |
| **Key config** | Steps: 10K-100K | Shards: 100-444 |
| **Purpose** | Test adversarial pressure at different intensities within one shard | Benchmark TPS, latency and security across distributed multi-shard network |

```powershell
.\RUN-TESTS-A.ps1          # Single-shard tests
```

```powershell
.\RUN-NG-BENCHMARK.ps1     # Multi-shard benchmark
```

---

## RUN-TESTS-A.ps1 Options

| Option | Category | Config |
|:------:|:--------:|:------|
| 1-5 | Security | 10K steps, 10%-90% attacker |
| 6-8 | Clean | 50K-500K steps, 0% attacker |
| 9-10 | Resistance | 100K-200K steps, 30%-35% |
| 11-13 | Quick | 500 steps, 10%-50% |
| 20-22 | Batch | All / Quick / Full sweep |

## RUN-NG-BENCHMARK.ps1 Options

| Option | Category | Config |
|:------:|:--------:|:------|
| 1-5 | Clean | 333-444 shards, 0% attacker |
| 6-8 | Attack | 333 shards, 10%-50% |
| 9-10 | Scaled | 100-200 shards, 10% |
| 11 | Custom | Configure all parameters |
| 99 | Info | List 37 attacker types |

---

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
