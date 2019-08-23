"""
    getbranch(p::Node, q::Node)::Branch

Get the `Branch` object connecting nodes `p` and `q`. Warning: For speed, this function assumes links between the nodes `p` and `q` are correctly constructed, and this assumption will not be checked.
"""
function getbranch(p::Node, q::Node)::Branch
    @inbounds for link in p.links
        link.node == q && return link.branch
    end
    throw(LinkingError())
end

"""
    getbranch(p::Node)::Branch

Get the `Branch` oject connecting the directed node `p` to its parent. Will throw an exception if the node does not have a parent.
"""
function getbranch(p::Node)::Branch
    hasparent(p) || throw(UndefParentError())
    return p.links[1].branch
end

"""
    brlength(p::Node, q::Node)::Float64

Get the length of the branch connecting node `p` to node `q`.
"""
brlength(p::Node, q::Node)::Float64 = getbranch(p, q).length

"""
    brlength(p::Node)::Float64

Get the length of the branch connecting node `p` to its parent.
"""
brlength(p::Node)::Float64 = getbranch(p).length

"""
    brlength!(p::Node, q::Node, v::Float64)::Nothing

Set `v` as the length of the branch connecting node `p` to node `q`.
"""
function brlength!(p::Node, q::Node, v::Float64)::Nothing
    getbranch(p, q).length = v

    return nothing
end

"""
    brlength!(p::Node, v::Float64)::Nothing

Set `v` as the length of the branch connecting the directed node `p` to its parent.
"""
function brlength!(p::Node, v::Float64)::Nothing
    getbranch(p).length = v
    
    return nothing
end

"""
    brlabel(p::Node, q::Node)::AbstractString

Get the label of the branch connecting node `p` to node `q`.
"""
brlabel(p::Node, q::Node)::AbstractString = getbranch(p, q).label

"""
    brlabel(p::Node)::AbstractString

Get the label of the branch connecting node `p` to its parent.
"""
brlabel(p::Node)::AbstractString = getbranch(p).label

"""
    brlabel!(p::Node, q::Node, v::AbstractString)::Nothing

Set the string `v` as the label of the branch connecting node `p` to node `q`.
"""
function brlabel!(p::Node, q::Node, v::AbstractString)::Nothing
    getbranch(p, q).label = v

    return nothing
end

"""
    brlabel!(p::Node, v::AbstractString)::Nothing

Set the string `v` as the label of the branch connecting node `p` to its parent.
"""
function brlabel!(p::Node, v::AbstractString)::Nothing
    getbranch(p).label = v

    return nothing
end