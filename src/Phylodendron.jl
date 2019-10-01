module Phylodendron
using DataStructures
using PrettyTables: pretty_table, borderless, ft_printf
using DelimitedFiles

#=
#### CORE TYPE DEFINITIONS ####
The files "exceptions.jl", "Branch.jl", "Link.jl", and "Node.jl" must be included in that exact order, as each file successively define types on which the following type definitions depend.
=#
include("exceptions.jl")
    export
        LinkingError,
        UndefParentError,
        UndirectedError,
        MissingTreeInfo,
        InvalidNewick,
        MissingSpeciesDirectory,
        WrongTopology,
        FinishedTraversalError,
        RootError

include("species.jl")
export
    SpeciesDirectory,
    showerror,
    name, name!,
    length,
    getindex,
    in,
    add!

include("Bipartition.jl")
export
    Bipartition

include("SpeciesData.jl")
export
    SpeciesDataMatrix,
    size,
    getindex, setindex!,
    firstindex, lastindex,
    summary,
    show,
    write,
    write_phylip,
    read_species_data

include("models.jl")
export
    ModelPlugin, TreeModelPlugin, NodeModelPlugin, BranchModelPlugin

include("Branch.jl")
    export Branch

include("Link.jl")
    export Link

include("Node.jl")
    export
        Node,
        NodeVector,
        isdirected,
        hasparent,
        neighbours, n_neighbours,
        parent,
        children, n_children,
        label, label!,
        istip,
        hasdata,
        hasspecies,
        matchlabel!,
        subtree_size,
        issplitting

include("Tree.jl")
    export
        Tree,
        TreeVector,
        update!,
        tips,
        internal_nodes,
        tiplabels,
        nodelabels,
        branches,
        species,
        create_species!,
        map_species!,
        map_data!

#=
#### TREE INSPECTION AND MANIPULATION ####
These files define various functions for getting and setting properties of tree components, and altering the topology of the tree.
=#

include("linking_core.jl")
include("topomanip.jl")
    export
        link!, unlink!,
        graft!, snip!,
        ascent_order, descent_order,
        collapse_nonsplitting!

include("branches.jl")
    export
        getbranch,
        brlength, brlength!,
        brlabel, brlabel!

include("rooting.jl")
    export
        root!, unroot!,
        getroot,
        as_outgroup!

include("traversing.jl")
    export
        PreorderTraverser, PostorderTraverser,
        preorder, postorder,
        next!, nextpair!,
        isfinished,
        ancestry,
        node_path,
        mrca

include("find.jl")
    export findspecies

include("bipartition_methods.jl")
export
    update_bipartition!,
    compute_bipartitions!,
    istrivial, 
    isinformative,
    are_compatible,
    are_conflicting

include("clone.jl")
export
    clone

include("model_methods.jl")
export patch_models!

#=
#### TREE I/O ####
These files define various functions for getting and setting properties of tree components, and altering the topology of the tree.
=#

include("lexer.jl")
include("newick.jl")
export
    parse_newick,
    read_newick,
    newick_string,
    write_newick

include("randtree.jl")
export
    randtree

include("brownian/simulate.jl")
export simulate_bm

include("brownian/reml.jl")
export
    add_rel_brownian_model!,
    optimise_v!,
    rel_brownian_prune!,
    calc_llh!,
    phylip_llh

end # module Phylodendron
