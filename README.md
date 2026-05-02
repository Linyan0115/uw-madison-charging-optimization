# Portable Charging-Station Placement on University Campuses

A network optimization framework for placing portable charging stations on the UW–Madison campus.

**Course:** CS/ECE/ISyE 524 — Spring 2026  
**Authors:** Shirley Xu, Linyan Li

## Project Structure

| File | Description |
|------|-------------|
| `data.jl` | Campus network data: coordinates, edges, arc costs, node weights, battery parameters, OD pairs |
| `routing.jl` | Shortest-path routing via MCNF LP (includes `data.jl`) |
| `models.jl` | Optimization models B (SCP), C (BASP), D (BCCM), E (EAP), and B-budgeted (includes `routing.jl`) |
| `experiments.jl` | Computational experiments: Table 2 comparison, sensitivity analyses (β, α, λ), Monte Carlo robustness (includes `models.jl`) |
| `visualization.jl` | Campus map plots (Chan-style with Lake Mendota), staged rollout, battery trajectory plots (includes `models.jl`) |
| `network_plot.jl` | Standalone schematic network graph with grid layout, edge distances, and cost-colored nodes |

## Dependencies

- **Julia** ≥ 1.10
- **JuMP** ≥ 1.22
- **HiGHS** ≥ 1.7
- **Plots**
- **Statistics**, **Random**, **Printf** (stdlib)

Install packages:
```julia
using Pkg
Pkg.add(["JuMP", "HiGHS", "Plots"])
```

## Usage

```julia
# Run all models and print Table 2
include("models.jl")

# Run full experiments with sensitivity plots
include("experiments.jl")

# Generate campus map visualizations
include("visualization.jl")

# Generate schematic network graph
include("network_plot.jl")
```

## Models

- **Model B (SCP):** Set-covering placement baseline
- **Model C (BASP):** Battery-aware station placement — tracks device battery along each route
- **Model D (BCCM):** Budget-constrained coverage maximization
- **Model E (EAP):** Equity-aware placement — maximizes worst-category coverage rate across RA/AA/RC route types
