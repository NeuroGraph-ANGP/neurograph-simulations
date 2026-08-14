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

## RUN-TESTS-A.ps1  ![Interactive](https://img.shields.io/badge/Type-Interactive-9b7eff?style=flat-square)

```powershell
.\RUN-TESTS-A.ps1
```

Runs a **single shard** with 2664 nodes and 37 attacker types (T0-T36). Each test applies one attacker percentage across all nodes within that shard, measuring how the system handles concentrated adversarial pressure at different intensities.

| Parameter | Value |
|:----------|:-----:|
| Mode | Single shard |
| Nodes | 2664 |
| Attacker types | 37 (T0-T36) |
| Attacker % | 0% to 90% |
| Steps | 10K / 30K / 50K / 100K |

| Option | Category | Config |
|:------:|:--------:|:------|
| 1-5 | Security | 10K steps, 10%-90% atk |
| 6-8 | Clean | 50K-500K steps, 0% atk |
| 9-10 | Resistance | 100K-200K steps, 30%-35% |
| 11-13 | Quick | 500 steps, 10%-50% atk |
| 20-22 | Batch | All security / all quick / full |

---

## RUN-NG-BENCHMARK.ps1  ![Benchmark](https://img.shields.io/badge/Type-Benchmark-00d4aa?style=flat-square)

```powershell
.\RUN-NG-BENCHMARK.ps1
```

Runs **333 shards in parallel** (4 shards batched, 2 Rayon threads each) with 8 nodes per shard and 37 attacker types (T0-T36). Measures TPS, latency, and security across a distributed multi-shard network under varying shard counts and attacker loads.

| Parameter | Value |
|:----------|:-----:|
| Mode | Multi-shard (parallel) |
| Nodes | 2664 (333 x 8) |
| Attacker types | 37 (T0-T36) |
| Attacker % | 0% to 50% |
| Shards | 100 / 200 / 222 / 333 / 444 |

| Option | Category | Config |
|:------:|:--------:|:------|
| 1-5 | Clean | 333-444 shards, 0% atk |
| 6-8 | Attack | 333 shards, 10%-50% atk |
| 9-10 | Scaled | 100-200 shards, 10% atk |
| 11 | Custom | Manual all parameters |
| 99 | Info | List 37 attacker types |

---

## Reproducing Paper Results

> **1.** Run `.\RUN-NG-BENCHMARK.ps1` for the full multi-shard benchmark
> **2.** Run `.\RUN-TESTS-A.ps1` for single-shard security analysis
> **3.** Compare your results with the paper's reported values

---

## System Requirements

[![Windows 10/11](https://img.shields.io/badge/OS-Windows_10_/_11-4a9eff?style=flat-square)]()
[![PowerShell 5.1+](https://img.shields.io/badge/Shell-PowerShell_5.1+-5391F2?style=flat-square)]()
[![Internet: first run only](https://img.shields.io/badge/Internet-first_run_only-888?style=flat-square)]()

---

<div align="center">

**MIT License** -- simulations and test scripts

The ANGP engine binary is provided for verification purposes only.

</div>
