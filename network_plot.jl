# ============================================================
# network_plot.jl — Schematic Network Graph Visualization
# Grid-layout campus network with edge distances and node costs
# (from NetworkBuild_1_.ipynb)
# ============================================================

using Plots

### Set Data
coords = Dict(
    "College Library" => (43.0767609, -89.4038309),
    "Memorial Library" => (43.0754378, -89.4027379),
    "Law School Library" => (43.0732524, -89.4066479),
    "Social Work Library" => (43.0723281, -89.4117139),
    "Geology & Geophysics Library" => (43.0703966, -89.4142644),
    "Memorial Union" => (43.0744328, -89.4021045),
    "Union South" => (43.0720038, -89.4102213),
    "Gordon Dining and Event Center" => (43.0711998, -89.4034828),
    "Engineering Hall" => (43.0717682, -89.4128689),
    "Van Hise Hall" => (43.0731487, -89.4091674),
    "Microbial Sciences Building" => (43.0753727, -89.4139974),
    "Nicholas Recreation Center" => (43.0707356, -89.4015178),
    "Bakke" => (43.0767539, -89.4226803),
    "Smith Residence Hall" => (43.0689229, -89.4030899),
    "Witte Residence Hall" => (43.0714837, -89.3996364),
    "Sellery Residence Hall" => (43.0709654, -89.4022810),
    "Tripp Residence Hall" => (43.0774263, -89.4176647),
    "Leopold Residence Hall" => (43.0767202, -89.4163657),
    "Dejope Residence Hall" => (43.0775611, -89.4196152),
    "Phillips Residence Hall" => (43.0774263, -89.4213767)
)

# Manually adjusted layout positions for clearer visualization
grid_pos = Dict(
    "Bakke" => (1.0, 6.2),
    "Dejope Residence Hall" => (3.0, 6.9),
    "Phillips Residence Hall" => (2.2, 7.8),
    "Leopold Residence Hall" => (5.0, 7.0),
    "Tripp Residence Hall" => (7.2, 7.0),
    "Microbial Sciences Building" => (6.8, 5.4),
    "Social Work Library" => (8.8, 4.2),
    "Van Hise Hall" => (10.8, 5.3),
    "Law School Library" => (13.8, 4.3),
    "Engineering Hall" => (7.0, 2.8),
    "Union South" => (9.2, 2.8),
    "Geology & Geophysics Library" => (9.8, 1.2),
    "College Library" => (14.4, 6.2),
    "Memorial Union" => (15.8, 5.9),
    "Memorial Library" => (17.6, 5.3),
    "Sellery Residence Hall" => (15.2, 2.3),
    "Gordon Dining and Event Center" => (16.6, 2.0),
    "Witte Residence Hall" => (19.0, 2.8),
    "Nicholas Recreation Center" => (16.6, 1.2),
    "Smith Residence Hall" => (15.0, 0.2)
)

edges = [
    ("Bakke", "Phillips Residence Hall"),
    ("Bakke", "Dejope Residence Hall"),
    ("Dejope Residence Hall", "Phillips Residence Hall"),
    ("Phillips Residence Hall", "Leopold Residence Hall"),
    ("Dejope Residence Hall", "Leopold Residence Hall"),
    ("Leopold Residence Hall", "Tripp Residence Hall"),
    ("Leopold Residence Hall", "Microbial Sciences Building"),
    ("Tripp Residence Hall", "Microbial Sciences Building"),
    ("Microbial Sciences Building", "Van Hise Hall"),
    ("Tripp Residence Hall", "Van Hise Hall"),
    ("Microbial Sciences Building", "Engineering Hall"),
    ("Microbial Sciences Building", "Social Work Library"),
    ("Van Hise Hall", "College Library"),
    ("Van Hise Hall", "Law School Library"),
    ("College Library", "Memorial Union"),
    ("Law School Library", "Memorial Union"),
    ("Memorial Union", "Memorial Library"),
    ("Law School Library", "Memorial Library"),
    ("Social Work Library", "Law School Library"),
    ("Social Work Library", "Union South"),
    ("Engineering Hall", "Union South"),
    ("Engineering Hall", "Geology & Geophysics Library"),
    ("Union South", "Sellery Residence Hall"),
    ("Sellery Residence Hall", "Law School Library"),
    ("Sellery Residence Hall", "Smith Residence Hall"),
    ("Smith Residence Hall", "Geology & Geophysics Library"),
    ("Sellery Residence Hall", "Gordon Dining and Event Center"),
    ("Memorial Library", "Gordon Dining and Event Center"),
    ("Gordon Dining and Event Center", "Witte Residence Hall"),
    ("Witte Residence Hall", "Nicholas Recreation Center"),
    ("Nicholas Recreation Center", "Smith Residence Hall"),
    ("Union South", "Geology & Geophysics Library")
]

# Node (installation cost)
weights = Dict(
    "College Library" => 0.9,
    "Memorial Library" => 0.9,
    "Law School Library" => 1.0,
    "Social Work Library" => 1.0,
    "Geology & Geophysics Library" => 1.0,
    "Engineering Hall" => 1.0,
    "Van Hise Hall" => 1.0,
    "Microbial Sciences Building" => 1.0,
    "Memorial Union" => 1.1,
    "Union South" => 1.1,
    "Gordon Dining and Event Center" => 1.2,
    "Nicholas Recreation Center" => 1.2,
    "Bakke" => 1.3,
    "Sellery Residence Hall" => 1.4,
    "Witte Residence Hall" => 1.4,
    "Smith Residence Hall" => 1.4,
    "Tripp Residence Hall" => 1.4,
    "Leopold Residence Hall" => 1.4,
    "Dejope Residence Hall" => 1.4,
    "Phillips Residence Hall" => 1.4
)

# Map node installation cost to colors
# Low cost (<= 1.0): blue
# Medium cost (1.0 < c <= 1.2): orange
# High cost (> 1.2): red
function cost_color(c)
    if c <= 1.0
        return :blue
    elseif c <= 1.2
        return :orange
    else
        return :red
    end
end


### Distance function
# Compute the approximate surface distance between two geographic points
# using a local Euclidean approximation.
#
# Since this study focuses on a relatively small geographic area (the UW–Madison campus)
# the curvature of the Earth can be ignored.
# This makes Euclidean distance a simple and sufficiently accurate method for short-range travel estimation.
function euclidean(coord1, coord2)
    lat1, lon1 = coord1
    lat2, lon2 = coord2

    # Approximate conversion from degrees to meters
    dx = (lon2 - lon1) * 111000 * cosd((lat1 + lat2) / 2)
    dy = (lat2 - lat1) * 111000

    return sqrt(dx^2 + dy^2)
end

edge_dist = Dict{Tuple{String,String},Float64}()
for (a, b) in edges
    edge_dist[(a, b)] = euclidean(coords[a], coords[b])
end


### Labels
label_map = Dict(
    "Bakke" => "Bakke",
    "Dejope Residence Hall" => "Dejope",
    "Phillips Residence Hall" => "Phillips",
    "Leopold Residence Hall" => "Leopold",
    "Tripp Residence Hall" => "Tripp",
    "Microbial Sciences Building" => "Microbial",
    "Social Work Library" => "Social\nWork",
    "Van Hise Hall" => "Van Hise",
    "Law School Library" => "Law\nSchool",
    "Engineering Hall" => "Engineering",
    "Union South" => "Union\nSouth",
    "Geology & Geophysics Library" => "Geology",
    "College Library" => "College\nLib",
    "Memorial Union" => "Memorial\nUnion",
    "Memorial Library" => "Memorial\nLib",
    "Sellery Residence Hall" => "Sellery",
    "Gordon Dining and Event Center" => "Gordon",
    "Witte Residence Hall" => "Witte",
    "Nicholas Recreation Center" => "Nick",
    "Smith Residence Hall" => "Smith"
)

xs = [v[1] for v in values(grid_pos)]
ys = [v[2] for v in values(grid_pos)]

### Plot

p = plot(
    legend = false,
    axis = false,
    grid = false,
    framestyle = :none,
    background_color = RGB(0.96, 0.96, 0.96),
    size = (1600, 1000),
    xlims = (minimum(xs) - 1.0, maximum(xs) + 2.0),
    ylims = (minimum(ys) - 1.0, maximum(ys) + 1.0)
)

# Draw edges and distance labels
for (a, b) in edges
    x1, y1 = grid_pos[a]
    x2, y2 = grid_pos[b]

    # Draw edge
    plot!(p, [x1, x2], [y1, y2], color = :orange, lw = 2.5)

    # Midpoint for distance label
    mx = (x1 + x2) / 2
    my = (y1 + y2) / 2
    dist_text = string(round(edge_dist[(a, b)], digits = 0), " m")

    dx = x2 - x1
    dy = y2 - y1

    if abs(dy) < 0.25
        tx = mx
        ty = my + 0.22
        halign = :center
    elseif abs(dx) < 0.25
        tx = mx - 0.45
        ty = my
        halign = :right
    else
        len = sqrt(dx^2 + dy^2)
        nx = -dy / len
        ny = dx / len
        tx = mx + 0.22 * nx
        ty = my + 0.22 * ny
        halign = :center
    end

    annotate!(p, tx, ty, text(dist_text, 8, :darkred, halign, "sans-serif"))
end

# Draw nodes
for (name, (x, y)) in grid_pos
    scatter!(
        p, [x], [y],
        markersize = 27,
        markershape = :rect,
        markercolor = cost_color(weights[name]),
        markerstrokecolor = :black,
        markerstrokewidth = 1.5
    )

    annotate!(p, x, y, text(label_map[name], 8, :white, :center, "sans-serif"))
end

# Legend
annotate!(p, 18.0, 7.8, text("Node cost", 10, :black, :left, "sans-serif"))
annotate!(p, 18.0, 7.3, text("Blue (c ≤ 1.0)", 9, :blue, :left, "sans-serif", :bold))
annotate!(p, 18.0, 6.9, text("Orange (1.0 < c ≤ 1.2)", 9, :goldenrod, :left, "sans-serif", :bold))
annotate!(p, 18.0, 6.5, text("Red (c > 1.2)", 9, :red, :left, "sans-serif", :bold))

display(p)
savefig(p, "uw_madison_network_final.png")
