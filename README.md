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

**Step 1:** Open PowerShell. If this is your first time running scripts, allow them with:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

**Step 2:** Download and enter the repository:

```powershell
git clone https://github.com/NeuroGraph-ANGP/neurograph-simulations.git
cd neurograph-simulations
```

> No git installed? Click the green **Code** button above, then **Download ZIP**. Extract it, open PowerShell in that folder.

**Step 3:** Download the simulation engine (internet needed, first run only):

```powershell
.\setup.ps1
```

**Step 4:** Run a test:

```powershell
.\RUN-TESTS-A.ps1
```

A menu appears. Type a number and press Enter. For example, type **1** for a 10% attacker test. Results are saved automatically in the results folder.

---

## Test Scripts

<table><tr>

<td width="50%" valign="top">

<h3 align="center">RUN-TESTS-A.ps1 <img src="https://img.shields.io/badge/Single_Shard-9b7eff?style=flat-square" alt="Single Shard"/></h3>

<p align="center"><code>.\RUN-TESTS-A.ps1</code></p>

<p>Runs a <strong>single shard</strong> with 2664 nodes and 37 attacker types (T0-T36). Each test applies one attacker percentage across all nodes within that shard, measuring how the system handles concentrated adversarial pressure at different intensities.</p>

<table width="100%">
<tr><th align="left">Parameter</th><th align="right">Value</th></tr>
<tr><td>Mode</td><td align="right">Single shard</td></tr>
<tr><td>Nodes</td><td align="right">2664</td></tr>
<tr><td>Attacker types</td><td align="right">37 (T0-T36)</td></tr>
<tr><td>Attacker %</td><td align="right">0 to 99%</td></tr>
<tr><td>Steps</td><td align="right">10K / 30K / 50K / 100K</td></tr>
</table>

<table width="100%">
<tr><th align="left">Option</th><th>Category</th><th align="right">Config</th></tr>
<tr><td>1-5</td><td align="center">Security</td><td align="right">10K steps, 10%-90%</td></tr>
<tr><td>6-8</td><td align="center">Clean</td><td align="right">50K-500K, 0% atk</td></tr>
<tr><td>9-10</td><td align="center">Resistance</td><td align="right">100K-200K, 30%-35%</td></tr>
<tr><td>11-13</td><td align="center">Quick</td><td align="right">500 steps, 10%-50%</td></tr>
<tr><td>20-22</td><td align="center">Batch</td><td align="right">All / Quick / Full</td></tr>
</table>

</td>

<td width="50%" valign="top">

<h3 align="center">RUN-NG-BENCHMARK.ps1 <img src="https://img.shields.io/badge/Multi_Shard-00d4aa?style=flat-square" alt="Multi Shard"/></h3>

<p align="center"><code>.\RUN-NG-BENCHMARK.ps1</code></p>

<p>Runs <strong>333 shards in parallel</strong> (4 shards batched, 2 Rayon threads each) with 8 nodes per shard and 37 attacker types (T0-T36). Measures TPS, latency, and security across a distributed multi-shard network under varying shard counts and attacker loads.</p>

<table width="100%">
<tr><th align="left">Parameter</th><th align="right">Value</th></tr>
<tr><td>Mode</td><td align="right">Multi-shard (parallel)</td></tr>
<tr><td>Nodes</td><td align="right">2664 (333 x 8)</td></tr>
<tr><td>Attacker types</td><td align="right">37 (T0-T36)</td></tr>
<tr><td>Attacker %</td><td align="right">0 to 99%</td></tr>
<tr><td>Shards</td><td align="right">100 / 200 / 222 / 333 / 444</td></tr>
</table>

<table width="100%">
<tr><th align="left">Option</th><th>Category</th><th align="right">Config</th></tr>
<tr><td>1-5</td><td align="center">Clean</td><td align="right">333-444 shards, 0% atk</td></tr>
<tr><td>6-8</td><td align="center">Attack</td><td align="right">333 shards, 10%-50%</td></tr>
<tr><td>9-10</td><td align="center">Scaled</td><td align="right">100-200 shards, 10%</td></tr>
<tr><td>11</td><td align="center">Custom</td><td align="right">Manual all params</td></tr>
<tr><td>99</td><td align="center">Info</td><td align="right">List 37 atk types</td></tr>
</table>

</td>

</tr></table>

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
