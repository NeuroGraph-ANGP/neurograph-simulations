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

<br>

## Quick Start

```powershell
git clone https://github.com/NeuroGraph-ANGP/neurograph-simulations.git
cd neurograph-simulations
.\setup.ps1
```

Then choose a test script:

<table align="center" width="100%">
<tr>
<th width="50%" align="center">

### RUN-TESTS-A.ps1
[![Type: Interactive](https://img.shields.io/badge/Type-Interactive-9b7eff?style=flat-square)]()

</th>
<th width="50%" align="center">

### RUN-NG-BENCHMARK.ps1
[![Type: Benchmark](https://img.shields.io/badge/Type-Benchmark-00d4aa?style=flat-square)]()

</th>
</tr>
<tr>
<td align="center" valign="top">

```powershell
.\RUN-TESTS-A.ps1
```

**Explore specific scenarios**

| Step Set | Options | Attacker % |
|:--------|:-------:|:----------:|
| 10K | 1--9 | 10%--90% |
| 30K | 11--19 | 10%--90% |
| 50K | 21--29 | 10%--90% |
| 100K | 31--39 | 10%--90% |
| QUICK | 51 | 10% |
| CUSTOM | 88 | any |

</td>
<td align="center" valign="top">

```powershell
.\RUN-NG-BENCHMARK.ps1
```

**Reproduce paper results**

| Parameter | Value |
|:----------|:-----:|
| Duration | 333s |
| Nodes | 8 |
| Attacker | 20% |
| Output | TPS report |

</td>
</tr>
</table>

<br>

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
