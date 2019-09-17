using Test
using Phylodendron

@test [] == detect_ambiguities(Base, Core, Phylodendron)

include("linking.jl")
include("properties.jl")
include("newick.jl")
include("randtree.jl")
include("traversing.jl")
include("rooting.jl")
include("topomanip.jl")
include("species.jl")
include("speciesdata.jl")
include("trees.jl")
include("bipartitions.jl")
include("find.jl")
include("brownian/simulate.jl")
include("brownian/reml.jl")