# A Network Optimization Framework for Portable Charging-Station Placement on the UW–Madison Campus

**Authors:** Linyan Li ([lli643@wisc.edu](mailto:lli643@wisc.edu)), Shirley Xu ([mxu369@wisc.edu](mailto:mxu369@wisc.edu))  
**Course:** CS/ECE/ISyE 524 Final Project · Spring 2026  
**Report:** See [`CS524_Team35_Report.pdf`](CS524_Team35_Report.pdf) for the full write-up.

## Overview

This project formulates the placement of portable charging kiosks (e.g., ChargeFUZE, Brick, FuelRod) on the UW–Madison campus as a family of network-optimization problems. Five progressively richer mixed-integer programs are developed — from a basic minimum-cost shortest-path formulation to an equity-aware, budget-constrained model — and solved in Julia/JuMP with the open-source HiGHS solver.

Computational experiments on a graph of **|N| = 20** buildings, **|E| = 32** pedestrian edges, and **|R| = 36** commuting origin–destination (OD) pairs identify a set of robust station locations and produce a **three-phase deployment recommendation** that achieves **100% coverage** of all student trips with only **five kiosks**.

## Mathematical Models

The five models form a progressive framework, each adding one new structural element:

| Model | Name | Key Idea |
|-------|------|----------|
| **A** | Minimum-Cost Shortest Path (MCNF) | Solves shortest walking paths for all 36 OD pairs via network flow |
| **B** | Set-Covering Placement (SCP) | Selects minimum-cost stations so every route passes through ≥ 1 station; ignores battery dynamics |
| **C** | Battery-Aware Station Placement (BASP) | Tracks device battery along routes; stations must keep charge above a comfort threshold B_min |
| **D** | Budget-Constrained Coverage Maximization (BCCM) | Maximizes covered routes subject to a total budget constraint α |
| **E** | Equity-Aware Placement (EAP) | Maximizes the worst-category coverage rate η* across three OD flow types (max–min fairness) |

## Data

All node coordinates are real GPS positions from Google Maps for 20 representative UW–Madison buildings. The 36 OD pairs reflect three flow categories:

- **RA (14 pairs):** Residence → Academic (morning commutes)
- **AA (12 pairs):** Academic → Academic (between-class transitions)
- **RC (10 pairs):** Residence/Academic → Community amenities

Installation-cost weights are calibrated to reflect theft risk, available outlets, and custodial coverage (academic libraries ≈ 0.9, residence halls ≈ 1.4). Default battery parameters: β = 2000 m (100%), β₀ = 1200 m (60% start), B_min = 200 m (10% comfort threshold).

## Key Results

**Cross-model comparison (default parameters):**

| Model | #Stations | Cost | Coverage | η* |
|-------|-----------|------|----------|----|
| B (SCP, λ=2) | 6 | 6.40 | 36/36 | — |
| C (BASP) | 5 | 5.30 | 36/36 | — |
| D (BCCM, α=5) | 4 | 4.60 | 35/36 | — |
| E (EAP, α=5) | 4 | 4.60 | 35/36 | 0.929 |

**Monte Carlo robustness (50 trials, random demand weights):** Four stations appear consistently — Law School Library (100%), Microbial Sciences Building (88%), Gordon Dining (64%), and Van Hise Hall (52%).

**Recommended three-phase rollout:**

| Phase | Stations Added | Coverage |
|-------|---------------|----------|
| Phase 1 | Law School Library + Microbial Sciences Building | 89% |
| Phase 2 | + Gordon Dining + Van Hise Hall | 97% |
| Phase 3 | + Memorial Library (redundancy / equity) | 100% |

## Repository Structure

```
├── README.md                 # This file
├── data.jl                   # Campus network data: coordinates, edges, costs, weights, OD pairs
├── routing.jl                # Shortest-path routing via MCNF (Model A); includes data.jl
├── models.jl                 # Optimization Models B, C, D, E + B-budgeted; includes routing.jl
├── experiments.jl            # Computational experiments & sensitivity analyses; includes models.jl
├── visualization.jl          # Campus maps & battery trajectory plots; includes models.jl
├── network_plot.jl           # Standalone schematic network graph (Figure 3 in report)
```

**Dependency chain:** `data.jl` → `routing.jl` → `models.jl` → `experiments.jl` / `visualization.jl`

| File | Contents |
|------|----------|
| `data.jl` | Node coordinates (GPS), edge list, arc construction, distance computation (Eq. 2.1), installation-cost weights, battery parameters, OD pair definitions |
| `routing.jl` | `shortest_path(O, D)` function implementing the MCNF LP (Eq. 2.2); builds `route_record` and `route_nodes_record` for all 36 OD pairs |
| `models.jl` | `model_B_SCP(λ)` — Set-Covering Placement (Eq. 2.3); `model_C_BASP()` — Battery-Aware Placement (Eq. 2.4); `model_D_BCCM()` — Budget-Constrained Coverage Max (Eq. 2.5); `model_E_EAP()` — Equity-Aware Placement (Eq. 2.6); `model_B_budgeted()` — Connectivity Mode variant |
| `experiments.jl` | Table 1 cross-model comparison; sensitivity to β (staircase plot), α (diminishing returns), λ (penalty sweep); Monte Carlo robustness (50 trials); battery-aware vs. connectivity-mode comparison |
| `visualization.jl` | `plot_campus()` — Chan-style campus map with Lake Mendota, road axes, and category-colored nodes; four-model map comparison (Figure 7); staged rollout α = 1…6 (Figure 8); `trace_battery()` — battery trajectory visualization (Figure 9) |
| `network_plot.jl` | Grid-layout schematic network with edge distances and cost-colored nodes (Figure 3) |

## Dependencies

- **Julia** ≥ 1.10
- **JuMP** ≥ 1.22
- **HiGHS** ≥ 1.7 (open-source MIP solver)
- **Plots** (visualization)
- `Statistics`, `Random`, `Printf` (Julia stdlib)

```julia
using Pkg
Pkg.add(["JuMP", "HiGHS", "Plots"])
```

## Usage

```julia
# Run all optimization models and print results
include("models.jl")

# Run full experiments with sensitivity analyses and Monte Carlo
include("experiments.jl")

# Generate campus map and battery trajectory visualizations
include("visualization.jl")

# Generate the schematic network graph (Figure 3)
include("network_plot.jl")
```

## Assumptions

- **(A1)** Students follow exact shortest paths between origin and destination
- **(A2)** Battery consumption is linear in walking distance (ρ = 1)
- **(A3)** Kiosks have unlimited capacity (no queueing)
- **(A4)** A kiosk fully recharges any device that visits it (instantaneous jump to 100%)
- **(A5)** The network is undirected and demand is symmetric

See Section 4.8 of the report for a discussion of limitations and sensitivity to these assumptions.

## References

1. Bertsimas, D. and Tsitsiklis, J. N. *Introduction to Linear Optimization.* Athena Scientific, 1997.
2. Capar, I. et al. "An arc cover–path-cover formulation and strategic analysis of alternative-fuel station locations." *EJOR*, 227(1):142–151, 2013.
3. Chan, W. "Siting electric vehicle fast charging stations in Wisconsin." CS 524 Project Report, UW–Madison, Summer 2020.
4. Church, R. and ReVelle, C. "The maximal covering location problem." *Papers of the Regional Science Association*, 32(1):101–118, 1974.
5. Hakimi, S. L. "Optimum locations of switching centers." *Operations Research*, 12(3):450–459, 1964.
6. Kuby, M. and Lim, S. "The flow-refueling location problem for alternative-fuel vehicles." *Socio-Economic Planning Sciences*, 39(2):125–145, 2005.
