# ============================================================
# models.jl — Optimization Models B, C, D, E
# UW-Madison Portable Charging-Station Placement
# ============================================================

using JuMP, HiGHS

include("routing.jl")

# ============================================================
# Model B — Set-Covering Placement (SCP)
# ============================================================
function model_B_SCP(λ::Float64)
    m = Model(HiGHS.Optimizer); set_silent(m)
    N = nodes; R = collect(keys(route_nodes_record))
    @variable(m, X[i in N], Bin)
    @variable(m, y[r in R], Bin)
    @objective(m, Min, sum(weights[i]*X[i] for i in N) + λ*sum(1-y[r] for r in R))
    for r in R
        @constraint(m, sum(X[i] for i in route_nodes_record[r]) >= y[r])
    end
    optimize!(m)
    return [i for i in N if value(X[i])>0.5],
           [r for r in R if value(y[r])>0.5],
           objective_value(m)
end

sel_B, cov_B, obj_B = model_B_SCP(2.0)
println("Model B (SCP, λ=2.0): $(length(sel_B)) stations, $(length(cov_B))/$(length(route_nodes_record)) covered")
println("  -> ", sel_B)

# ============================================================
# Model C — Battery-Aware Placement (BASP)
# ============================================================
function model_C_BASP(; β=BETA_DEFAULT, β0=BETA0_DEFAULT, Bmin=BMIN_DEFAULT)
    m = Model(HiGHS.Optimizer); set_silent(m); set_time_limit_sec(m, 60.0)
    N = nodes; R = collect(keys(route_nodes_record))
    M_big = β
    @variable(m, X[i in N], Bin)
    @variable(m, B[r in R, i in route_nodes_record[r]] >= Bmin)
    @variable(m, e[r in R, i in route_nodes_record[r]] >= 0)
    @objective(m, Min, sum(weights[i]*X[i] for i in N))
    for r in R
        pn = route_nodes_record[r]; pa = route_record[r]
        @constraint(m, B[r, pn[1]] == β0)
        for (i,j) in pa
            @constraint(m, B[r,i] + e[r,i] - costs[(i,j)] == B[r,j])
        end
        for i in pn
            @constraint(m, B[r,i] + e[r,i] <= β)
            @constraint(m, e[r,i] <= M_big * X[i])
        end
    end
    optimize!(m)
    sel = [i for i in N if value(X[i])>0.5]
    return sel, objective_value(m)
end

sel_C, cost_C = model_C_BASP()
println("Model C (BASP): $(length(sel_C)) stations, cost $(round(cost_C, digits=2))")
for s in sel_C; println("  • ", s); end

# ============================================================
# Model D — Budget-Constrained Coverage Maximization (BCCM)
# ============================================================
function model_D_BCCM(; α=5.0, β=BETA_DEFAULT, β0=BETA0_DEFAULT,
                        Bmin=BMIN_DEFAULT, weights_route=nothing)
    m = Model(HiGHS.Optimizer); set_silent(m); set_time_limit_sec(m, 60.0)
    N = nodes; R = collect(keys(route_nodes_record)); M_big = β; M1 = β
    weights_route === nothing && (weights_route = Dict(r => 1.0 for r in R))
    @variable(m, X[i in N], Bin)
    @variable(m, y[r in R], Bin)
    @variable(m, B[r in R, i in route_nodes_record[r]])
    @variable(m, e[r in R, i in route_nodes_record[r]] >= 0)
    @variable(m, δ[r in R, i in route_nodes_record[r]], Bin)
    @objective(m, Max, sum(weights_route[r] * y[r] for r in R))
    @constraint(m, sum(weights[i]*X[i] for i in N) <= α)
    for r in R
        pn = route_nodes_record[r]; pa = route_record[r]
        @constraint(m, B[r, pn[1]] == β0)
        for (i,j) in pa
            @constraint(m, B[r,i] + e[r,i] - costs[(i,j)] == B[r,j])
        end
        for i in pn
            @constraint(m, B[r,i] + e[r,i] <= β)
            @constraint(m, e[r,i] <= M_big * X[i])
            @constraint(m, B[r,i] >= Bmin - M1 * δ[r,i])
            @constraint(m, y[r] + δ[r,i] <= 1)
        end
    end
    optimize!(m)
    return [i for i in N if value(X[i])>0.5],
           [r for r in R if value(y[r])>0.5],
           objective_value(m)
end

sel_D, cov_D, _ = model_D_BCCM(α=5.0)
println("Model D (BCCM, α=5): $(length(sel_D)) stns, $(length(cov_D))/$(length(route_nodes_record)) covered")
println("  -> ", sel_D)

# ============================================================
# Model E — Equity-Aware Placement (EAP)
# ============================================================
function model_E_EAP(; α=5.0, β=BETA_DEFAULT, β0=BETA0_DEFAULT, Bmin=BMIN_DEFAULT)
    m = Model(HiGHS.Optimizer); set_silent(m); set_time_limit_sec(m, 120.0)
    N = nodes; R = collect(keys(route_nodes_record)); M_big = β; M1 = β
    categories = [("RA", collect(OD_pairs_RA)),
                  ("AA", collect(OD_pairs_AA)),
                  ("RC", collect(OD_pairs_RC))]
    @variable(m, X[i in N], Bin)
    @variable(m, y[r in R], Bin)
    @variable(m, B[r in R, i in route_nodes_record[r]])
    @variable(m, e[r in R, i in route_nodes_record[r]] >= 0)
    @variable(m, δ[r in R, i in route_nodes_record[r]], Bin)
    @variable(m, 0 <= ηstar <= 1)
    @objective(m, Max, ηstar)
    @constraint(m, sum(weights[i]*X[i] for i in N) <= α)
    for r in R
        pn = route_nodes_record[r]; pa = route_record[r]
        @constraint(m, B[r, pn[1]] == β0)
        for (i,j) in pa
            @constraint(m, B[r,i] + e[r,i] - costs[(i,j)] == B[r,j])
        end
        for i in pn
            @constraint(m, B[r,i] + e[r,i] <= β)
            @constraint(m, e[r,i] <= M_big * X[i])
            @constraint(m, B[r,i] >= Bmin - M1 * δ[r,i])
            @constraint(m, y[r] + δ[r,i] <= 1)
        end
    end
    for (tag, Rt) in categories
        @constraint(m, (1/length(Rt)) * sum(y[r] for r in Rt) >= ηstar)
    end
    optimize!(m)
    sel = [i for i in N if value(X[i])>0.5]
    cov = [r for r in R if value(y[r])>0.5]
    rates = Dict(tag => sum(value(y[r]) for r in Rt)/length(Rt) for (tag,Rt) in categories)
    return sel, cov, value(ηstar), rates
end

sel_E, cov_E, ηstar_E, rates_E = model_E_EAP(α=5.0)
println("Model E (EAP, α=5): $(length(sel_E)) stns, η* = $(round(ηstar_E, digits=3))")
println("  -> ", sel_E)
for (tag,rate) in rates_E; println("    $tag : $(round(rate, digits=3))"); end

# ============================================================
# Model B — Budgeted variant (for Connectivity Mode)
# ============================================================
function model_B_budgeted(; α=5.0, weights_route=nothing)
    m = Model(HiGHS.Optimizer); set_silent(m)
    N = nodes; R = collect(keys(route_nodes_record))
    weights_route === nothing && (weights_route = Dict(r => 1.0 for r in R))
    @variable(m, X[i in N], Bin)
    @variable(m, y[r in R], Bin)
    @objective(m, Max, sum(weights_route[r] * y[r] for r in R))
    @constraint(m, sum(weights[i]*X[i] for i in N) <= α)
    for r in R
        @constraint(m, sum(X[i] for i in route_nodes_record[r]) >= y[r])
    end
    optimize!(m)
    return [i for i in N if value(X[i])>0.5],
           [r for r in R if value(y[r])>0.5]
end
