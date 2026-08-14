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

Explore specific scenarios with custom parameters.

| Parameter | Value |
|:----------|:-----:|
| Shards | 10K / 30K / 50K / 100K |
| Nodes | 8 |
| Attacker | 10% to 90% |
| Output | TPS report |

| Option | Step Set | Attacker % |
|:------:|:--------:|:----------:|
| 1-9 | 10K | 10%-90% |
| 11-19 | 30K | 10%-90% |
| 21-29 | 50K | 10%-90% |
| 31-39 | 100K | 10%-90% |
| 51 | QUICK | 10% |
| 88 | CUSTOM | any |

---

## RUN-NG-BENCHMARK.ps1  ![Benchmark](https://img.shields.io/badge/Type-Benchmark-00d4aa?style=flat-square)

```powershell
.\RUN-NG-BENCHMARK.ps1
```

Reproduce the exact results from the paper.

| Parameter | Value |
|:----------|:-----:|
| Shards | 333 |
| Nodes | 8 |
| Attacker | 20% |
| Output | TPS report |

| Metric | Description |
|:------:|:------------|
| TPS | Transactions per second |
| Latency | Per-shard latency |
| Security | Attacker success rate |
| Integrity | DAG integrity score |

---

## Reproducing Paper Results

> **1.** Run `.\RUN-NG-BENCHMARK.ps1` for the full benchmark
> **2.** Run `.\RUN-TESTS-A.ps1` to explore individual scenarios
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
