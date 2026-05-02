# ============================================================
# experiments.jl — Computational Experiments
# Table 2, sensitivity analyses, Monte Carlo robustness
# ============================================================

using Printf, Random

include("models.jl")

# ============================================================
# Table 2 — Comparison across models
# ============================================================
results = []
sel, cov, obj = model_B_SCP(2.0)
push!(results, ("B  (SCP, λ=2.0)", length(sel), sum(weights[i] for i in sel; init=0.0),
                length(cov), "-", sel))

sel, cost = model_C_BASP()
push!(results, ("C  (BASP)", length(sel), cost, length(route_nodes_record), "-", sel))

sel, cov, _ = model_D_BCCM(α=5.0)
push!(results, ("D  (BCCM, α=5)", length(sel), sum(weights[i] for i in sel; init=0.0),
                length(cov), "-", sel))

sel, cov, η, _ = model_E_EAP(α=5.0)
push!(results, ("E  (EAP,  α=5)", length(sel), sum(weights[i] for i in sel; init=0.0),
                length(cov), @sprintf("%.2f", η), sel))

R_total = length(route_nodes_record)
println("="^92)
@printf "%-18s  %6s  %6s  %-12s  %-6s\n" "Model" "#Stns" "Cost" "Coverage" "η*"
println("="^92)
for (name, nstn, cost, covr, eta, sel) in results
    @printf "%-18s  %6d  %6.2f  %-4d / %-3d    %-6s\n" name nstn cost covr R_total eta
end
println("="^92)
println("\nSelected stations per model:")
for (name, _, _, _, _, sel) in results
    println("  • ", name, "  ==>  ", join(sel, ", "))
end

# ============================================================
# Sensitivity to battery capacity β
# ============================================================
β_values = collect(1100.0:100.0:3500.0)
β_stations = Int[]; β_costs = Float64[]
for β in β_values
    try
        sel, cost = model_C_BASP(β=β, β0=0.6*β, Bmin=0.1*β)
        push!(β_stations, length(sel)); push!(β_costs, cost)
    catch
        push!(β_stations, -1); push!(β_costs, NaN)
    end
end

plt1 = plot(β_values, β_stations,
    marker=:circle, linewidth=2, markersize=6,
    xlabel="Battery capacity β (m)  [100% = β]",
    ylabel="Stations required (Model C)",
    title="Sensitivity to battery capacity β  (staircase)",
    legend=false, grid=true, size=(760, 430))
display(plt1)

# ============================================================
# Sensitivity to budget α
# ============================================================
α_values = collect(1.0:0.5:8.0)
α_coverage = Int[]
for α in α_values
    _, cov, _ = model_D_BCCM(α=α)
    push!(α_coverage, length(cov))
end

plt2 = plot(α_values, α_coverage,
    marker=:diamond, linewidth=2, markersize=7,
    xlabel="Budget α (Memorial-equivalent stations)",
    ylabel="Routes covered (of $(length(route_nodes_record)))",
    title="Sensitivity to budget α  (diminishing returns)",
    legend=false, grid=true, size=(760, 430))
display(plt2)

# ============================================================
# Sensitivity to penalty λ (Model B)
# ============================================================
λ_values = [0.1, 0.3, 0.5, 0.7, 1.0, 2.0, 5.0, 10.0]
println("   λ       #Stns   Coverage    Objective")
println("  " * "-"^42)
for λ in λ_values
    sel, cov, obj = model_B_SCP(λ)
    @printf "  %5.2f     %3d     %2d / %d      %6.2f\n" λ length(sel) length(cov) length(route_nodes_record) obj
end

# ============================================================
# Monte Carlo robustness — Battery-aware (Model D)
# ============================================================
Random.seed!(524)
n_trials = 50
sel_freq = Dict(i => 0 for i in nodes)
for t in 1:n_trials
    w = Dict(r => 0.5 + rand() for r in keys(route_nodes_record))
    sel, _, _ = model_D_BCCM(α=5.0, weights_route=w)
    for s in sel
        sel_freq[s] += 1
    end
end

sorted_freq = sort(collect(sel_freq), by = x -> -x[2])
println("Monte Carlo selection frequency (α=5, $n_trials trials)")
println("="^60)
for (name, cnt) in sorted_freq
    cnt > 0 && @printf "  %-36s  %3d / %d  (%.1f%%)\n" name cnt n_trials (100*cnt/n_trials)
end

top = first(filter(x -> x[2] > 0, sorted_freq), 10)
plt3 = bar([x[1] for x in top], [x[2] for x in top],
    xrotation=40, xlabel="Station", ylabel="Selections (of $n_trials)",
    title="Monte Carlo station-selection frequency",
    legend=false, size=(950, 520), bottom_margin=35Plots.mm)
display(plt3)

# ============================================================
# Monte Carlo robustness — Connectivity Mode (Model B)
# ============================================================
Random.seed!(524)
n_trials_conn = 50
conn_freq = Dict(i => 0 for i in nodes)

for t in 1:n_trials_conn
    w = Dict(r => 0.5 + rand() for r in keys(route_nodes_record))
    sel, _ = model_B_budgeted(α=5.0, weights_route=w)
    for s in sel; conn_freq[s] += 1; end
end

sorted_conn = sort(collect(conn_freq), by = x -> -x[2])
println("Connectivity Mode — Monte Carlo (α=5, $n_trials_conn trials)")
println("="^60)
for (n, c) in sorted_conn
    c > 0 && @printf "  %-36s  %3d / %d  (%.1f%%)\n" n c n_trials_conn (100*c/n_trials_conn)
end

# ============================================================
# Side-by-side comparison: battery-aware vs. connectivity
# ============================================================
all_names = union(Set([n for (n,c) in sorted_freq if c>0]),
                  Set([n for (n,c) in sorted_conn if c>0]))
merged = [(n, get(sel_freq, n, 0), get(conn_freq, n, 0)) for n in all_names]
sort!(merged, by = x -> -(x[2] + x[3]))
merged = first(merged, 10)

names_vec = [x[1] for x in merged]
basp_vals = [x[2] for x in merged]
conn_vals = [x[3] for x in merged]

# Manual grouped bar (avoids needing StatsPlots.jl)
n = length(names_vec)
xs = collect(1:n)
bw = 0.38  # bar width

plt4 = plot(xlabel = "Station", ylabel = "Selections (of $n_trials)",
            title = "Monte Carlo comparison: battery-aware vs. connectivity",
            size = (1150, 560), bottom_margin = 38Plots.mm,
            xticks = (xs, names_vec), xrotation = 40, grid = :y)

bar!(plt4, xs .- bw/2, basp_vals, bar_width = bw,
     color = :steelblue, label = "Battery-aware (Model D)", linecolor = :black)
bar!(plt4, xs .+ bw/2, conn_vals, bar_width = bw,
     color = :darkorange, label = "Connectivity (Model B)", linecolor = :black)
display(plt4)
