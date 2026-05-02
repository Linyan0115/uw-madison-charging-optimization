# ============================================================
# data.jl — Campus network data definitions
# UW-Madison Portable Charging-Station Placement
# ============================================================

using Statistics

# ------------------------------------------------------------
# Geographic coordinates from Google Maps
# ------------------------------------------------------------
coords = Dict(
    "College Library"                => (43.0767009, -89.4038309),
    "Memorial Library"               => (43.0754378, -89.4027379),
    "Law School Library"             => (43.0732524, -89.4066479),
    "Social Work Library"            => (43.0723281, -89.4117139),
    "Geology & Geophysics Library"   => (43.0703966, -89.4142644),
    "Memorial Union"                 => (43.0744328, -89.4021045),
    "Union South"                    => (43.0720038, -89.4102213),
    "Gordon Dining and Event Center" => (43.0711998, -89.4034828),
    "Engineering Hall"               => (43.0717682, -89.4128689),
    "Van Hise Hall"                  => (43.0731487, -89.4091674),
    "Microbial Sciences Building"    => (43.0753727, -89.4139974),
    "Nicholas Recreation Center"     => (43.0707356, -89.4015178),
    "Bakke"                          => (43.0767539, -89.4226803),
    "Smith Residence Hall"           => (43.0689229, -89.4030899),
    "Witte Residence Hall"           => (43.0714837, -89.3996364),
    "Sellery Residence Hall"         => (43.0709654, -89.4022810),
    "Tripp Residence Hall"           => (43.0774263, -89.4176647),
    "Leopold Residence Hall"         => (43.0767202, -89.4163657),
    "Dejope Residence Hall"          => (43.0775611, -89.4196152),
    "Phillips Residence Hall"        => (43.0774263, -89.4213767),
)

nodes = collect(keys(coords))
println("Number of nodes: ", length(nodes))

# ------------------------------------------------------------
# Euclidean distance (local equirectangular projection)
# ------------------------------------------------------------
function euclidean(c1, c2)
    lat1, lon1 = c1; lat2, lon2 = c2
    dx = (lon2 - lon1) * 111_000 * cosd((lat1 + lat2) / 2)
    dy = (lat2 - lat1) * 111_000
    return sqrt(dx^2 + dy^2)
end

# ------------------------------------------------------------
# Edge list (undirected graph)
# ------------------------------------------------------------
edges = [
    ("Bakke","Phillips Residence Hall"),("Bakke","Dejope Residence Hall"),
    ("Dejope Residence Hall","Phillips Residence Hall"),
    ("Phillips Residence Hall","Leopold Residence Hall"),
    ("Dejope Residence Hall","Leopold Residence Hall"),
    ("Leopold Residence Hall","Tripp Residence Hall"),
    ("Leopold Residence Hall","Microbial Sciences Building"),
    ("Tripp Residence Hall","Microbial Sciences Building"),
    ("Microbial Sciences Building","Van Hise Hall"),
    ("Tripp Residence Hall","Van Hise Hall"),
    ("Microbial Sciences Building","Engineering Hall"),
    ("Microbial Sciences Building","Social Work Library"),
    ("Van Hise Hall","College Library"),("Van Hise Hall","Law School Library"),
    ("College Library","Memorial Union"),("Law School Library","Memorial Union"),
    ("Memorial Union","Memorial Library"),("Law School Library","Memorial Library"),
    ("Social Work Library","Law School Library"),("Social Work Library","Union South"),
    ("Engineering Hall","Union South"),("Engineering Hall","Geology & Geophysics Library"),
    ("Union South","Sellery Residence Hall"),
    ("Sellery Residence Hall","Law School Library"),
    ("Sellery Residence Hall","Smith Residence Hall"),
    ("Sellery Residence Hall","Geology & Geophysics Library"),
    ("Sellery Residence Hall","Gordon Dining and Event Center"),
    ("Memorial Library","Gordon Dining and Event Center"),
    ("Gordon Dining and Event Center","Witte Residence Hall"),
    ("Witte Residence Hall","Nicholas Recreation Center"),
    ("Nicholas Recreation Center","Smith Residence Hall"),
    ("Union South","Geology & Geophysics Library"),
]

# Build directed arcs from undirected edges
arcs = Tuple{String,String}[]
for (a,b) in edges
    push!(arcs, (a,b)); push!(arcs, (b,a))
end

# Compute edge costs (distances in meters)
costs = Dict{Tuple{String,String},Float64}()
for (a,b) in edges
    d = euclidean(coords[a], coords[b])
    costs[(a,b)] = d; costs[(b,a)] = d
end

println("Edges: ", length(edges), "   Arcs: ", length(arcs))
println("Edge length: min = $(round(Int, minimum(values(costs)))) m, "
        * "max = $(round(Int, maximum(values(costs)))) m")

# ------------------------------------------------------------
# Node installation costs (weights)
# ------------------------------------------------------------
weights = Dict(
    "College Library" => 0.9,  "Memorial Library" => 0.9,
    "Law School Library" => 1.0, "Social Work Library" => 1.0,
    "Geology & Geophysics Library" => 1.0, "Engineering Hall" => 1.0,
    "Van Hise Hall" => 1.0, "Microbial Sciences Building" => 1.0,
    "Memorial Union" => 1.1, "Union South" => 1.1,
    "Gordon Dining and Event Center" => 1.2, "Nicholas Recreation Center" => 1.2,
    "Bakke" => 1.3,
    "Sellery Residence Hall" => 1.4, "Witte Residence Hall" => 1.4,
    "Smith Residence Hall" => 1.4, "Tripp Residence Hall" => 1.4,
    "Leopold Residence Hall" => 1.4, "Dejope Residence Hall" => 1.4,
    "Phillips Residence Hall" => 1.4,
);

# ------------------------------------------------------------
# Default battery parameters (calibrated to campus scale)
# ------------------------------------------------------------
const BETA_DEFAULT  = 2000.0   # 100% battery
const BETA0_DEFAULT = 1200.0   # 60% start
const BMIN_DEFAULT  = 200.0    # 10% comfort threshold

println("Default battery params:")
println("  β    = $BETA_DEFAULT  m  (100% battery)")
println("  β₀   = $BETA0_DEFAULT  m  (60% start)")
println("  Bmin = $BMIN_DEFAULT  m  (10% comfort threshold)")

# ------------------------------------------------------------
# Origin–Destination (OD) pairs by category
# ------------------------------------------------------------
OD_pairs_RA = [
    ("Dejope Residence Hall","College Library"),
    ("Dejope Residence Hall","Memorial Library"),
    ("Phillips Residence Hall","Engineering Hall"),
    ("Bakke","Law School Library"),
    ("Tripp Residence Hall","Van Hise Hall"),
    ("Leopold Residence Hall","Social Work Library"),
    ("Witte Residence Hall","Memorial Library"),
    ("Smith Residence Hall","Geology & Geophysics Library"),
    ("Sellery Residence Hall","Law School Library"),
    ("Sellery Residence Hall","Engineering Hall"),
    ("Dejope Residence Hall","Engineering Hall"),
    ("Phillips Residence Hall","College Library"),
    ("Witte Residence Hall","Law School Library"),
    ("Smith Residence Hall","Union South"),
]
OD_pairs_AA = [
    ("College Library","Engineering Hall"),
    ("Memorial Library","Social Work Library"),
    ("Law School Library","Geology & Geophysics Library"),
    ("Van Hise Hall","Engineering Hall"),
    ("Engineering Hall","Memorial Library"),
    ("Social Work Library","College Library"),
    ("Microbial Sciences Building","Law School Library"),
    ("College Library","Geology & Geophysics Library"),
    ("Memorial Library","Engineering Hall"),
    ("Van Hise Hall","Social Work Library"),
    ("Law School Library","Engineering Hall"),
    ("Microbial Sciences Building","Memorial Library"),
]
OD_pairs_RC = [
    ("Sellery Residence Hall","Union South"),
    ("Smith Residence Hall","Nicholas Recreation Center"),
    ("Dejope Residence Hall","Memorial Union"),
    ("Memorial Union","Nicholas Recreation Center"),
    ("Gordon Dining and Event Center","Law School Library"),
    ("Union South","Gordon Dining and Event Center"),
    ("Witte Residence Hall","Union South"),
    ("Leopold Residence Hall","Gordon Dining and Event Center"),
    ("College Library","Union South"),
    ("Tripp Residence Hall","Memorial Union"),
]
OD_pairs = vcat(OD_pairs_RA, OD_pairs_AA, OD_pairs_RC)
println("Total OD pairs: ", length(OD_pairs))
