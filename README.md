# NeuroGraph ANGP v4.3 -- Security Simulations

Reproducible security simulations for verifying the assumptions from the NeuroGraph ANGP paper.

## Quick Start

Open PowerShell and run:

    git clone https://github.com/NeuroGraph-ANGP/neurograph-simulations.git
    cd neurograph-simulations
    .\setup.ps1
    .\RUN-TESTS-A.ps1

Or for the benchmark:

    .\RUN-NG-BENCHMARK.ps1

## Test Suite Options (RUN-TESTS-A.ps1)

| Step Set    | Options | Attacker % |
|-------------|---------|------------|
| 10K STEPS   | 1-9     | 10%-90%    |
| 30K STEPS   | 11-19   | 10%-90%    |
| 50K STEPS   | 21-29   | 10%-90%    |
| 100K STEPS  | 31-39   | 10%-90%    |
| CLEAN (0%)  | 41-44   | 0%         |
| CUSTOM      | 50      | 0-99%      |
| QUICK       | 51-53   | presets    |
| BATCH       | 60-64   | automated  |
| INFO        | 99      | show info  |
| EXIT        | 0       | exit       |

## Reproducing Paper Results

1. Run .\RUN-NG-BENCHMARK.ps1 for the full benchmark
2. Select individual tests from .\RUN-TESTS-A.ps1
3. Compare your results with the paper reported values

## System Requirements

- Windows 10/11
- PowerShell 5.1+
- Internet connection (first run only, for setup)

## License

MIT License -- simulations and test scripts.
The ANGP engine binary is provided for verification purposes only.
