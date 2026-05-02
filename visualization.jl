# ============================================================
# visualization.jl — Campus Map & Battery Trajectory Plots
# Chan (2020) style campus map with Lake Mendota overlay
# ============================================================

using Plots, Printf

include("models.jl")

# ================================================================
# Campus-map visualization helper — Chan (2020) style
# Draws UW-Madison with Lake Mendota, campus land polygon,
# major road axes, and the optimization result overlaid.
# ================================================================

# Project lat/lon to meters (local equirectangular).
# Origin at campus centroid so the plot is centered.
const CAMPUS_LAT0 = mean([coords[n][1] for n in nodes])
const CAMPUS_LON0 = mean([coords[n][2] for n in nodes])

to_xy(lat, lon) = (
    (lon - CAMPUS_LON0) * 111_000 * cosd(CAMPUS_LAT0),
    (lat - CAMPUS_LAT0) * 111_000,
)
to_xy(latlon) = to_xy(latlon[1], latlon[2])

coords_xy = Dict(n => to_xy(c) for (n, c) in coords)

# --- Lake Mendota simplified shoreline (north of campus) ---
mendota_latlon = [
    (43.0758, -89.4025), (43.0780, -89.4000), (43.0810, -89.3970),
    (43.0850, -89.3930), (43.0880, -89.3900), (43.0920, -89.3940),
    (43.0940, -89.4030), (43.0940, -89.4150), (43.0920, -89.4250),
    (43.0880, -89.4320), (43.0830, -89.4350), (43.0800, -89.4300),
    (43.0790, -89.4220), (43.0780, -89.4180), (43.0775, -89.4150),
    (43.0780, -89.4100), (43.0770, -89.4060), (43.0762, -89.4033),
]
const MENDOTA_XY = [to_xy(p) for p in mendota_latlon]

# --- Campus land boundary (south of lake) ---
campus_latlon = [
    (43.0680, -89.4250), (43.0680, -89.3970), (43.0762, -89.4033),
    (43.0770, -89.4060), (43.0780, -89.4100), (43.0775, -89.4150),
    (43.0780, -89.4180), (43.0790, -89.4220), (43.0800, -89.4300),
    (43.0790, -89.4340), (43.0750, -89.4350), (43.0700, -89.4330),
]
const CAMPUS_XY = [to_xy(p) for p in campus_latlon]

# --- Major road axes ---
const ROAD_AXES = [
    [to_xy(43.0735, -89.4200), to_xy(43.0732, -89.4020)],  # University Ave
    [to_xy(43.0720, -89.4220), to_xy(43.0717, -89.4015)],  # Johnson St
    [to_xy(43.0745, -89.4025), to_xy(43.0700, -89.3970)],  # State St
]

# --- Label offsets (meters, dx dy) to prevent overlap ---
const LABEL_OFFSETS = Dict(
    "Dejope Residence Hall"        => (-50,  45),
    "Phillips Residence Hall"      => (-55, -40),
    "Tripp Residence Hall"         => ( 45,  45),
    "Leopold Residence Hall"       => ( 15, -45),
    "Bakke"                        => (-35,  40),
    "Microbial Sciences Building"  => (  0, -35),
    "Van Hise Hall"                => (  0,  30),
    "Law School Library"           => ( 40, -10),
    "Social Work Library"          => (-60,  10),
    "College Library"              => (  0,  30),
    "Memorial Library"             => ( 45,  15),
    "Memorial Union"               => ( 15, -35),
    "Engineering Hall"             => (-75,  10),
    "Geology & Geophysics Library" => (  0, -35),
    "Union South"                  => (  5, -35),
    "Sellery Residence Hall"       => ( 40,  15),
    "Gordon Dining and Event Center" => (50,  0),
    "Nicholas Recreation Center"   => ( 55,  10),
    "Smith Residence Hall"         => ( 40, -25),
    "Witte Residence Hall"         => ( 45,  0),
)

const NODE_ABBR = Dict(
    "College Library" => "College Lib", "Memorial Library" => "Memorial Lib",
    "Law School Library" => "Law School", "Social Work Library" => "Social Work",
    "Geology & Geophysics Library" => "Geology", "Memorial Union" => "Memorial Union",
    "Union South" => "Union South", "Gordon Dining and Event Center" => "Gordon",
    "Engineering Hall" => "Engineering", "Van Hise Hall" => "Van Hise",
    "Microbial Sciences Building" => "Microbial Sci",
    "Nicholas Recreation Center" => "Nicholas Rec", "Bakke" => "Bakke",
    "Smith Residence Hall" => "Smith", "Witte Residence Hall" => "Witte",
    "Sellery Residence Hall" => "Sellery", "Tripp Residence Hall" => "Tripp",
    "Leopold Residence Hall" => "Leopold", "Dejope Residence Hall" => "Dejope",
    "Phillips Residence Hall" => "Phillips",
)

"""
    plot_campus(sel_stations; title_str="", show_legend=true)

Render a Chan-style UW-Madison campus map with Lake Mendota,
campus land polygon, road axes, pedestrian-graph edges, nodes
colored by category, and highlighted charging stations.
"""
function plot_campus(sel_stations::Vector{String}; title_str = "", show_legend = true)
    # Plot bounds in meters
    xlims_m = (-1050, 1100)
    ylims_m = ( -950, 1150)

    p = plot(; legend = show_legend ? :bottomright : false,
             grid = false, framestyle = :box,
             title = title_str, size = (900, 720),
             xlims = xlims_m, ylims = ylims_m,
             aspect_ratio = :equal,
             xticks = false, yticks = false,
             background_color = :white)

    # 1. Lake Mendota (light blue fill)
    lake_xs = [p[1] for p in MENDOTA_XY]
    lake_ys = [p[2] for p in MENDOTA_XY]
    plot!(p, Shape(lake_xs, lake_ys),
          fillcolor = RGB(0.78, 0.88, 0.96),
          linecolor = RGB(0.44, 0.64, 0.78),
          linewidth = 1.0, label = "")

    # 2. Campus land (pale green fill)
    land_xs = [p[1] for p in CAMPUS_XY]
    land_ys = [p[2] for p in CAMPUS_XY]
    plot!(p, Shape(land_xs, land_ys),
          fillcolor = RGB(0.93, 0.96, 0.86),
          linecolor = RGB(0.63, 0.63, 0.63),
          linewidth = 0.6, label = "")

    # 3. Road axes (grey)
    for axis in ROAD_AXES
        plot!(p, [axis[1][1], axis[2][1]], [axis[1][2], axis[2][2]],
              color = RGB(0.67, 0.67, 0.67), linewidth = 2.2,
              alpha = 0.55, label = "")
    end

    # 4. Pedestrian edges
    for (a, b) in edges
        xa, ya = coords_xy[a]
        xb, yb = coords_xy[b]
        plot!(p, [xa, xb], [ya, yb],
              color = RGB(0.88, 0.47, 0.34), linewidth = 1.4,
              alpha = 0.75, label = "")
    end

    # 5. Station halos
    if !isempty(sel_stations)
        xs_st = [coords_xy[s][1] for s in sel_stations]
        ys_st = [coords_xy[s][2] for s in sel_stations]
        scatter!(p, xs_st, ys_st,
                 markersize = 26, color = RGB(0.20, 0.60, 0.86),
                 alpha = 0.32, markerstrokewidth = 0,
                 label = show_legend ? "Charging station" : "")
    end

    # 6. Category-colored nodes
    acad  = ["College Library","Memorial Library","Law School Library",
             "Social Work Library","Geology & Geophysics Library",
             "Engineering Hall","Van Hise Hall","Microbial Sciences Building"]
    comm  = ["Memorial Union","Union South","Gordon Dining and Event Center",
             "Nicholas Recreation Center","Bakke"]
    resid = ["Smith Residence Hall","Witte Residence Hall","Sellery Residence Hall",
             "Tripp Residence Hall","Leopold Residence Hall","Dejope Residence Hall",
             "Phillips Residence Hall"]

    for (ns, col, lab) in [(acad,  RGB(0.12, 0.23, 0.42), "Academic"),
                            (comm,  RGB(0.18, 0.49, 0.20), "Community"),
                            (resid, RGB(0.70, 0.13, 0.20), "Residential")]
        xs_ = [coords_xy[n][1] for n in ns]
        ys_ = [coords_xy[n][2] for n in ns]
        scatter!(p, xs_, ys_,
                 markersize = 5.5, color = col,
                 markerstrokecolor = :white, markerstrokewidth = 1.0,
                 label = show_legend ? lab : "")
    end

    # 7. Node labels (offset)
    for n in keys(coords_xy)
        x, y = coords_xy[n]
        (dx, dy) = get(LABEL_OFFSETS, n, (0.0, 25.0))
        annotate!(p, x + dx, y + dy,
                  text(NODE_ABBR[n], 7, :black))
    end

    # 8. Lake label
    annotate!(p, -400, 1050,
              text("Lake Mendota", 10, :italic, RGB(0.23, 0.42, 0.54)))

    # 9. Compass
    plot!(p, [-950, -950], [900, 1050],
          arrow = :head, color = :black, linewidth = 1.5, label = "")
    annotate!(p, -950, 860, text("N", 10, :bold, :black))

    # 10. Scale bar (200 m)
    plot!(p, [-950, -750], [-880, -880],
          color = :black, linewidth = 2.5, label = "")
    annotate!(p, -850, -850, text("200 m", 8, :black))

    return p
end

println("Campus-map helper defined.")

# ============================================================
# Generate campus maps for all four models
# ============================================================
sel_B_def, _, _   = model_B_SCP(2.0)
sel_C_def, _       = model_C_BASP()
sel_D_def, _, _    = model_D_BCCM(α = 5.0)
sel_E_def, _, _, _ = model_E_EAP(α = 5.0)

pB = plot_campus(sel_B_def,
        title_str = "Model B (SCP, λ=2.0) — $(length(sel_B_def)) stations",
        show_legend = false)
pC = plot_campus(sel_C_def,
        title_str = "Model C (BASP, β=2000m) — $(length(sel_C_def)) stations",
        show_legend = false)
pD = plot_campus(sel_D_def,
        title_str = "Model D (BCCM, α=5) — $(length(sel_D_def)) stations",
        show_legend = false)
pE = plot_campus(sel_E_def,
        title_str = "Model E (EAP, α=5) — $(length(sel_E_def)) stations",
        show_legend = true)

plot(pB, pC, pD, pE, layout = (2, 2), size = (1700, 1200))

# ============================================================
# Staged rollout visualization (Model D, α = 1..6)
# ============================================================
rollout = []
for α in [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
    sel, cov, _ = model_D_BCCM(α=α)
    pct = round(100*length(cov)/length(route_nodes_record), digits=1)
    p = plot_campus(sel,
        title_str="α=$α  →  $(length(sel)) stns, $(length(cov))/$(length(route_nodes_record)) covered ($pct%)",
        show_legend=false)
    push!(rollout, p)
end
plot(rollout..., layout=(2,3), size=(2100, 1200))

# ============================================================
# Battery-trajectory plot
# ============================================================

# Trace device battery along a given OD route under a given station set
function trace_battery(O, D, stations; β=BETA_DEFAULT, β0=BETA0_DEFAULT, Bmin=BMIN_DEFAULT)
    path = route_nodes_record[(O, D)]
    arcs = route_record[(O, D)]
    n = length(path)

    cum_dist  = zeros(n)
    B_before  = zeros(n)   # battery when arriving at node i (before charging)
    B_after   = zeros(n)   # battery when leaving node i (after charging, if applicable)

    B_before[1] = β0
    B_after[1]  = path[1] in stations ? β : β0

    for i in 1:n-1
        d = costs[arcs[i]]
        cum_dist[i+1] = cum_dist[i] + d
        B_before[i+1] = B_after[i] - d
        B_after[i+1]  = (path[i+1] in stations) ? β : B_before[i+1]
    end
    return path, cum_dist, B_before, B_after
end

# Four representative routes
demo = [
    ("Dejope Residence Hall", "College Library"),
    ("Bakke", "Law School Library"),
    ("Phillips Residence Hall", "College Library"),
    ("Smith Residence Hall", "Geology & Geophysics Library"),
]

stations_C = Set(sel_C_def)

plt_traj = plot(
    xlabel = "Distance walked (m)", ylabel = "Device battery B (m range) → %",
    title  = "Battery trajectories under Model C's optimal placement",
    grid   = true, size = (1000, 580), legend = :outerright,
    ylims = (-50, BETA_DEFAULT + 150),
    yticks = ([0, BMIN_DEFAULT, BETA0_DEFAULT, BETA_DEFAULT],
              ["0", "B_min (10%)", "β₀ (60%)", "β (100%)"]),
)

# Comfort threshold
hline!(plt_traj, [BMIN_DEFAULT], color=:red, linestyle=:dash, linewidth=1.5,
       label="Comfort threshold (10%)")

colors = [:steelblue, :darkorange, :green, :purple]
for (idx, (O, D)) in enumerate(demo)
    path, cum, Bb, Ba = trace_battery(O, D, stations_C)
    label = "$O → $D"

    # Draw staircase: at each node, vertical segment from B_before to B_after, then walk to next node
    xs_line = Float64[]; ys_line = Float64[]
    for i in 1:length(path)
        push!(xs_line, cum[i]); push!(ys_line, Bb[i])
        push!(xs_line, cum[i]); push!(ys_line, Ba[i])
    end
    plot!(plt_traj, xs_line, ys_line, color=colors[idx], linewidth=2, label=label)

    # Mark charging events
    charge_x = [cum[i] for i in 1:length(path) if path[i] in stations_C]
    charge_y = [Ba[i]  for i in 1:length(path) if path[i] in stations_C]
    scatter!(plt_traj, charge_x, charge_y,
             marker=:utriangle, markersize=9, color=colors[idx],
             markerstrokecolor=:black, markerstrokewidth=1, label="")

    # Mark arrival dots at every node
    scatter!(plt_traj, cum, Bb, marker=:circle, markersize=3.5,
             color=colors[idx], markerstrokewidth=0, label="")
end

# Annotations explaining markers
annotate!(plt_traj, 50, BETA_DEFAULT + 80,
          text("Delta = charging event (jumps to 100%)", 8, :black, :left))
display(plt_traj)

# Print the textual trace for reference
println("\nTrajectory detail (stations: $(join(sort(collect(stations_C)), ", "))):")
println("="^100)
for (O, D) in demo
    path, cum, Bb, Ba = trace_battery(O, D, stations_C)
    println("\n$O → $D  ($(round(Int, last(cum))) m total)")
    for i in 1:length(path)
        star = path[i] in stations_C ? "Battery" : "  "
        below = Bb[i] < BMIN_DEFAULT ? "below threshold!" : ""
        @printf "  %s  %-35s  B_arrive = %4.0f m (%5.1f%%)$below\n" star path[i] Bb[i] (100*Bb[i]/BETA_DEFAULT)
    end
end
