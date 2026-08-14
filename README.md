# NeuroGraph ANGP v4.3 -- Security Simulations

> Reproducible security simulations for verifying the assumptions from the NeuroGraph ANGP paper.

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Windows](https://img.shields.io/badge/Platform-Windows-0078D4.svg)]()
[![PowerShell](https://img.shields.io/badge/Shell-PowerShell-5391F2.svg)]()
[![Release](https://img.shields.io/badge/Release-v4.3.5-green.svg)](https://github.com/NeuroGraph-ANGP/neurograph-simulations/releases/latest)

---

## Quick Start

```powershell
git clone https://github.com/NeuroGraph-ANGP/neurograph-simulations.git
cd neurograph-simulations
.\setup.ps1
```

Then choose a test script below.

---

## Test Scripts

| | **RUN-TESTS-A.ps1** | **RUN-NG-BENCHMARK.ps1** |
|---|---|---|
| **Purpose** | Interactive test suite | Full benchmark suite |
| **Use case** | Explore specific scenarios | Reproduce paper results |
| **Steps** | 10K / 30K / 50K / 100K | Fixed (333s, 8 nodes) |
| **Attacker %** | 10%--90% selectable | 20% (paper default) |
| **Output** | Per-run TPS report | Benchmark report file |

### RUN-TESTS-A.ps1 -- Interactive Test Suite

Run individual tests with custom parameters:

```powershell
.\RUN-TESTS-A.ps1
```

**Options:**

| Step Set | Options | Attacker % |
|----------|---------|------------|
| 10K STEPS | 1--9 | 10%--90% |
| 30K STEPS | 11--19 | 10%--90% |
| 50K STEPS | 21--29 | 10%--90% |
| 100K STEPS | 31--39 | 10%--90% |
| QUICK 10% | 51 | 10% (fast) |
| CUSTOM | 88 | Your values |

### RUN-NG-BENCHMARK.ps1 -- Benchmark Suite

Reproduce the exact results from the paper:

```powershell
.\RUN-NG-BENCHMARK.ps1
```

**Benchmark configuration:**

| Parameter | Value |
|-----------|-------|
| Duration | 333 seconds |
| Nodes | 8 |
| Attacker % | 20% |
| Output | benchmark-reports/TPS-*.txt |

---

## Reproducing Paper Results

1. Run .\RUN-NG-BENCHMARK.ps1 for the full benchmark
2. Run .\RUN-TESTS-A.ps1 to explore individual scenarios
3. Compare your results with the paper's reported values

---

## System Requirements

- **OS**: Windows 10 / 11
- **Shell**: PowerShell 5.1+
- **Internet**: First run only (to download the binary)

---

## License

MIT License -- simulations and test scripts.
The ANGP engine binary is provided for verification purposes only.
