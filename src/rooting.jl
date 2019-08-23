"""
    root!(p::Node)::Nothing

Make `p` the root of the tree to which it belongs.
"""
function root!(p::Node)::Nothing
    p.isdirected = true
    p.hasparent = false

    trav = PreorderTraverser(p, false)
    next!(trav)
    while ! isfinished(trav)
        q, r = nextpair!(trav)
        br_rq = getbranch(r, q)
        q.hasparent = false
        unlink!(r, q)
        r.isdirected = true
        link!(r, q, br_rq)
    end

    return nothing
end

"""
    unroot!(p::Node)::Nothing

Unroot the tree to which node `p` belongs.
"""
function unroot!(p::Node)::Nothing
    p.isdirected = false
    p.hasparent = false

    trav = PreorderTraverser(p, false)
    next!(trav)
    while ! isfinished(trav)
        q = next!(trav)
        q.hasparent = false
        q.isdirected = false
    end

    return nothing
end

"""
    root!(t::Tree, p::Node)::Nothing

Root tree `t` on node `p`. Return nothing.
"""
function root!(t::Tree, p::Node)::Nothing
    root!(p)
    t.origin = p
    t.rooted = true
    
    return nothing
end

"""
    root!(t::Tree)::Nothing

Root tree `t` on its current origin node. Return nothing.
"""
root!(t::Tree) = root!(t, t.origin)

"""
    unroot!(t::Tree)::Nothing

Unroot tree `t`. Return nothing.
"""
function unroot!(t::Tree)::Nothing
    unroot!(t.origin)
    t.rooted = false

    return nothing
end

"""
    getroot(p::Node)::Node

Return the root node of the tree to which node `p` belongs.
"""
function getroot(p::Node)::Node
    isdirected(p) || throw(UndirectedError())
    ! hasparent(p) && return p

    q = parent(p)
    while hasparent(q)
        q = parent(q)
    end

    return q
end

function as_outgroup!(p::Node, br_prop::Float64=0.5)::Node
    @assert n_neighbours(p) == 1 "Cannot use an internal node as the outgroup."
    q = p.links[1].node
    br_pq = p.links[1].branch

    unlink!(p, q)
    
    brlength_rp = br_pq.length * br_prop
    br_pq.length = br_pq.length - brlength_rp
    r = Node()
    link!(r, p, Branch(brlength_rp))
    link!(r, q, br_pq)

    root!(r)

    return r
end