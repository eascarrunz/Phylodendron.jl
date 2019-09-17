mutable struct Tree
    origin::Node
    rooted::Bool
    label::AbstractString
    dir::Union{Nothing,SpeciesDirectory}
    autoupdate::Bool
    n_tips::Int
    n_nodes::Int
    n_species::Int
    preorder::Vector{Tuple{Node,Node}}
    models::Vector{TreeModelPlugin}
    n_dataviews::Int
    bipartitions::Set{Bipartition}

    Tree() = new()
end

"""
    Tree(p::Node; fullinit::Bool=true)

Create a `Tree` object with node `p` as its origin.

Set the keyword argument `fullinit` to `false` in order to prevent the  initiailsation of non-essential fields of the tree object. This can save time when creating many trees or very large trees
"""
function Tree(p::Node; fullinit::Bool=true)::Tree
    tr = Tree()
    tr.label = ""
    tr.origin = p
    tr.rooted = isdirected(p)
    tr.models = TreeModelPlugin[]
    tr.autoupdate = true
    tr.dir = nothing
    tr.n_dataviews = 0
    fullinit && update!(tr)
    return tr
end

"""
    update!(tr::Tree)::Nothing

Make all the information about the tree `tr` and the preorder cache be consistent with the current links between the nodes.
"""
function update!(tr::Tree)::Nothing
    if isdirected(tr.origin)
        tr.origin = getroot(tr.origin)
        tr.rooted = true
    else
        tr.rooted = false
    end
    tr.n_tips = 0
    tr.n_nodes = 0
    tr.n_species = 0
    node_index = 1
    trav = PreorderTraverser(tr.origin)

    tr.n_dataviews = 0
    tmp_preorder = Deque{Tuple{Node,Node}}()
    while ! isfinished(trav)
        p, parent_p = nextpair!(trav)
        p.idx = node_index
        node_index += 1
        push!(tmp_preorder, (p, parent_p))
        tr.n_tips += istip(p)
        tr.n_nodes += 1
        tr.n_species += hasspecies(p)
        if tr.n_dataviews == 0
            tr.n_dataviews = length(p.dataviews)
        elseif hasdata(p)
            # Check that all nodes with data views have the same number of data views.
            @assert tr.n_dataviews == length(p.dataviews)
        end
    end

    tr.preorder = collect(tmp_preorder)

    return nothing
end

function Base.summary(io::IO, t::Tree)
    print(io, "Tree (", t.rooted ? "rooted" : "unrooted", "): ", t.n_nodes, " nodes, ", t.n_tips, " tips")

    return nothing
end

function Base.show(io::IO, t::Tree)
    summary(io, t)
end

const TreeVector = Vector{Tree}
function Base.show(io::IO, x::TreeVector)
    print(io, length(x), " phylogenetic trees")
end

"""
    tips(t::Tree)

Get the tip nodes of tree `t`.
"""
function tips(t::Tree)
    tipnodes = Vector{Node}(undef, t.n_tips)
    trav = PreorderTraverser(t)
    counter = 0
    while ! isfinished(trav)
        p = next!(trav)
        ! istip(p) && continue
        counter += 1
        tipnodes[counter] = p
    end

    return tipnodes
end

"""
    internal_nodes(t::Tree)

Get the internal nodes of tree `t`.
"""
function internal_nodes(t::Tree)
    innodes = Vector{Node}(undef, t.n_nodes - t.n_tips)
    trav = PreorderTraverser(t)
    counter = 0
    while ! isfinished(trav)
        p = next!(trav)
        istip(p) && continue
        counter += 1
        innodes[counter] = p
    end

    return innodes
end

"""
    branches(t::Tree)

Get the branches of tree `t`.
"""
function branches(t::Tree)::Vector{Branch}
    if isdefined(t, :preorder)
        return map(x-> getbranch(x...), t.preorder[2:end])
    end
    brlist = Deque{Branch}()
    trav = PreorderTraverser(t)
    next!(trav)
    while ! isfinished(trav)
        p, q = nextpair!(trav)
        push!(brlist, getbranch(p, q))
    end

    return collect(brlist)
end

"""
    brlengths(t::Tree)

Get the branch lengths of tree `t`.
"""
function brlengths(t::Tree)::Vector{Float64}
    if isdefined(t, :preorder)
        return map(x-> brlength(x...), t.preorder[2:end])
    end
    brlist = Deque{Float64}()
    trav = PreorderTraverser(t)
    next!(trav)
    while ! isfinished(trav)
        p, q = nextpair!(trav)
        push!(brlist, brlength(p, q))
    end

    return collect(brlist)
end

"""
    tiplabels(t::Tree)

Get the labels of the tips of tree `t`.
"""
function tiplabels(t::Tree)::Vector{String}
    tlabels = fill("", t.n_tips)
    trav = PreorderTraverser(t)
    counter = 0
    while ! isfinished(trav)
        p = next!(trav)
        if istip(p)
            counter += 1
            tlabels[counter] = label(p)
        end
    end

    return tlabels
end

"""
    nodelabels(t::Tree)

Get the labels of the nodes of tree `t`.
"""
function nodelabels(t::Tree)::Vector{String}
    nlabels = fill("", t.n_nodes)
    trav = PreorderTraverser(t)
    counter = 0
    while ! isfinished(trav)
        p = next!(trav)
        counter += 1
        nlabels[counter] = label(p)
    end

    return nlabels
end

"""
    species(t::Tree)

Get the species indices of the nodes of tree `t`.
"""
function species(t::Tree)::Vector{Int}
    nlabels = fill(0, t.n_tips)
    trav = PreorderTraverser(t)
    counter = 0
    while ! isfinished(trav)
        p = next!(trav)
        p.species == 0 && continue
        counter += 1
        nlabels[counter] = p.species
    end

    return nlabels
end

"""
    SpeciesDirectory(t::Tree; tipsonly=false)

Create a `SpeciesDirectory` from the node labels in tree `t`.

This only creates a new directory and has no effect on the tree itself. Setting `tipsonly` to `true` to only get the labels from the tip nodes.
"""
SpeciesDirectory(t::Tree; tipsonly=false) =
    tipsonly ? SpeciesDirectory(tiplabels(t)) : SpeciesDirectory(nodelabels(t))

"""
    create_species!(t::Tree; tipsonly=false)

Create new species based on the labels of the nodes of tree `t`.

The new species are automatically mapped to the nodes of the tree, and added to a new species directory that replaces the previous species directory of the tree, if it had one. `tipsonly=true` will only assign species to the tip nodes.
"""
function create_species!(t::Tree; tipsonly=false)
    n = tipsonly ? t.n_tips : t.n_nodes
    spplabels = fill("", n)
    trav = PreorderTraverser(t)
    sppcounter = 0
    while ! isfinished(trav)
        p = next!(trav)
        if tipsonly && ! istip(p)
            p.species = 0
            continue
        end
        if label(p) ≠ ""
            sppcounter += 1
            spplabels[sppcounter] = label(p)
            p.species = sppcounter
        end
    end

    dir = SpeciesDirectory(spplabels)
    t.dir = dir
    t.n_species = sppcounter

    return nothing
end


"""
    map_species!(t::Tree, dir::SpeciesDirectory; tipsonly=false)

Assign the species directory `dir` to tree `t`, and its species to the tree nodes by matching node labels to species names.

`tipsonly=true` will only assign species to the tip nodes.
"""
function map_species!(t::Tree, dir::SpeciesDirectory; tipsonly=false)
    t.dir = dir
    map_species!(t; tipsonly=tipsonly)

    return nothing
end

"""
    map_species!(t::Tree; tipsonly=false)

Assign the species to the nodes of the tree `t` by matching node labels to names in the tree's species directory.

`tipsonly=true` will only assign species to the tip nodes.
"""
function map_species!(t::Tree; tipsonly=false)
    trav = PreorderTraverser(t)
    t.n_species = 0
    while ! isfinished(trav)
        p = next!(trav)
        (tipsonly && ! istip(p)) && continue
        if label(p) ≠ ""
            p.species = t.dir[label(p)]
            t.n_species += p.species == 0 ? 0 : 1
        end
    end

    return nothing
end

function map_data!(t::Tree, dm::SpeciesDataMatrix)
    trav = PreorderTraverser(t)
    viewnumber = 0
    while ! isfinished(trav)
        p = next!(trav)
        if hasspecies(p)
            push!(p.dataviews, view(dm, p.species, :))
            viewnumber = viewnumber == 0 ? length(p.dataviews) : viewnumber
            @assert viewnumber == length(p.dataviews)
        end
    end

    @assert viewnumber == t.n_dataviews + 1
    t.n_dataviews = viewnumber

    return viewnumber
end