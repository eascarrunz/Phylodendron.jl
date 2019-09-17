
mutable struct Node
    links::Vector{Link}
    isdirected::Bool
    hasparent::Bool
    istip::Bool
    label::AbstractString
    dataviews::Vector{SubArray}
    models::Vector{NodeModelPlugin}
    species::Int
    idx::Int

    function Node()
        links = Link[]
        sizehint!(links, 3)

        return new(links, false, false, false, "", SubArray[], NodeModelPlugin[], 0, 0)
    end
end

const NodeVector = Vector{Node}

"""
    Node(v::AbstractString)::Node

Create a new `Node` with label string `v`.
"""
function Node(v::AbstractString)::Node
    p = Node()
    p.label = v
    return p
end

"""
show(io::IO, p::Node)

Fancy printing for `Node` objects. Gives a hint about the number of neighbours or parent and children.
"""
function Base.show(io::IO, p::Node)
    if isdirected(p)
        str = hasparent(p) ? "→" : " "
        str *= "○"
        n_children_p = n_children(p)
        if n_children_p > 0
            if n_children_p == 1
                str *= "→ "
            elseif n_children_p == 2
                str *= "⇉ "
            elseif n_children_p == 3
                str *= "⇶ "
            else n_children_p
                str *= "⋰⇶"
            end
        else
            str *= "  "
        end
    else
        n_neighbours_p = n_neighbours(p)
        if n_neighbours_p == 0
            str = " ○  "
        elseif n_neighbours_p == 1
            str = "—○  "
        elseif n_neighbours_p == 2
            str = "—○— "
        elseif n_neighbours_p == 3
            str = "—○̖´ "
        elseif n_neighbours_p == 4
            str = "—̩̍○— "
        else n_neighbours_p
            str = "—̩̍○⋰≡"
        end
    end

    label_p = label(p)
    str *= label_p == "" ? "" : " \"" * label(p) * "\""
    print(io, str)

    return nothing
end

"""
    isdirected(p::Node)::Bool

Return `true` if the node `p` is directed, i.e. the neighbour nodes are meant to be interpreted as explicit parent or children.
"""
@inline isdirected(p::Node)::Bool = p.isdirected

"""
    hasparent(p::Node)::Bool

Return `true` if the directed node `p` has a parent.
"""
@inline function hasparent(p::Node)::Bool
    isdirected(p) || throw(UndirectedError())
    return p.hasparent
end

"""
    neighbours(p::Node)::NodeVector

Return the vector of neighbours of node `p`.
"""
neighbours(p::Node)::NodeVector = @inbounds [link.node for link in p.links]

"""
    n_neighbours(p::Node)::Int

Return the number of neighbours of node `p`.
"""
n_neighbours(p::Node)::Int = length(p.links)

import Base.parent
"""
    parent(p::Node)::Node

Return the parent of the directed node `p`. Throws an exception if the node does not have a parent.
"""
@inline function parent(p::Node)::Node
    if hasparent(p)
        return @inbounds p.links[1].node
    else
        throw(UndefParentError())
    end
end

"""
    children(p::Node)::NodeVector

Return the vector of children of the directed node `p`. See `neighbours` for undirected nodes.
"""
function children(p::Node)::NodeVector
    isdirected(p) || throw(UndirectedError())
    if hasparent(p)
        return @inbounds Node[link.node for link in p.links[2:end]]
    else
        return @inbounds Node[link.node for link in p.links]
    end
end

"""
    n_children(p::Node)::Int

Return the number of children of node `p`.
"""
function n_children(p::Node)::Int
    isdirected(p) || throw(UndirectedError())
    return hasparent(p) ? length(p.links) - 1 : length(p.links)
end

"""
    label(p::Node)::AbstractString

Return the label string of node `p`.
"""
label(p::Node)::AbstractString = p.label

"""
    label!(p::Node, v::AbstractString)::Nothing

Set the string `v` as the label of node `p`.
"""
function label!(p::Node, v::AbstractString)::Nothing
    p.label = v
    
    return nothing
end

"""
    istip(p::Node)::Bool

Determine whether a node is a tip, i.e. it has only one neighbour.
"""
istip(p::Node)::Bool = length(p.links) == 1

"""
    hasdata(p::Node)::Bool

Return true if the node `p` has at least one data view.
"""
hasdata(p::Node)::Bool = length(p.dataviews) > 0 ? true : false

"""
    getdata(p::Node, viewnumber::Int=1)

Get the data from the view number `i` in node `p`.
"""
getdata(p::Node, i::Int=1) = p.dataviews[viewnumber]

"""
    hasspecies(p::Node)

Check that node `p` has a non-zero species index.
"""
hasspecies(p::Node)::Bool = p.species ≠ 0

"""
matchlabel!(p::Node, directory::SpeciesDirectory)

Assign to node `p` the species in the `directory` whose name matches the node label.

If no match is found, the node is assigned the species index 0.
"""
function matchlabel!(p::Node, directory::SpeciesDirectory)::Int
    if p.label == ""
        p.species = 0
    else
        p.species = haskey(directory.dict, p.label) ? directory[p.label] : 0
    end

    return p.species
end

"""
    subtree_size(p::Node, q::Node)::Int

Return the number of nodes in the subtree subtended by node `p` that does not include the neighbour node `q`.
"""
function subtree_size(p::Node, q::Node)::Int
    if p ∉ neighbours(q)
        throw(ArgumentError("`q` should be a neighbour of `p`."))
    end
    stsize = 0
    trav = PreorderTraverser(p, q, false)
    while ! isfinished(trav)
        next!(trav)
        stsize += 1
    end

    return stsize
end

"""
    subtree_size(p::Node)::Int

Return the number of nodes in the subtree subtended by the directed node `p`.
"""
function subtree_size(p::Node)::Int
    stsize = 0
    trav = PreorderTraverser(p, p, true)
    while ! isfinished(trav)
        next!(trav)
        stsize += 1
    end

    return stsize
end

"""
    issplitting(p::Node)

Return `true` if a node is non-splitting.
"""
function issplitting(p::Node)::Bool
    if n_neighbours(p) < 3
        isdirected(p) || return false
        hasparent(p) && return false
    end

    return true
end
