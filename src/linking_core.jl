"""
    link!(p::Node, q::Node, br::Branch = Branch())::Nothing

Link nodes `p` and `q` with branch `br`. If the nodes are undirected, the first link of `q` will be set to `p`, so that `p` becomes the parent of `q` if `q` is supposed to have a parent. If either node is directed, both nodes will become directed. Returns `nothing`.
"""
function link!(p::Node, q::Node, br::Branch = Branch())::Nothing
    link_p = Link{Node}(p, br)
    link_q = Link{Node}(q, br)
    #=
    By default the nodes are linked as if `p` were a parent and `q` the child, meaning that the link to `p` is going to be set as the first link in `q`, and the link to `q` is going to be set as the last link in `p`. Of course, the order of the links is irrelevant if the nodes are undirected.
    
    If `q` is directed and already has a parent, `q` will be set as the parent of `p`, so the link to `p` is set as the last link in `q`, and the link to `q` is set to be the first link in `p`.
    =#
    if isdirected(q)
        p.isdirected = q.isdirected = true
        if hasparent(q)
            push!(q.links, link_p)
            pushfirst!(p.links, link_q)
            p.hasparent = true

            return nothing
        else
            q.hasparent = true
        end
    end
    q.isdirected = isdirected(p)
    push!(p.links, link_q)      # Make sure `q` has index > 1 (child of `p`)
    pushfirst!(q.links, link_p) # Make sure `p` has index == 1 (parent of `q`)
    #=
    TODO: Don't use `pushfirst!`

    `pushfirst!` was a bad idea because it's slow. `Node` should have a `parent::Int` field with the index of the parent link in the links vector (or 0 for undirected nodes). This will require major surgery.
    =#
    q.hasparent = isdirected(p) ? true : false

    return nothing
end


"""
    unlink!(p::Node, q::Node)::Nothing

Unlink nodes `p` and `q`. If one of the nodes is the parent of the other, the unlinked child node will be set as parentless. Returns `nothing`.
"""
function unlink!(p::Node, q::Node)::Nothing
    if isdirected(p) && hasparent(p) && parent(p) == q
            p.hasparent = false
            deleteat!(p.links, 1)
            deleteat!(q.links, findfirst(x -> x.node == p, q.links))
    elseif isdirected(q) && hasparent(q) && parent(q) == p
            q.hasparent = false
            deleteat!(q.links, 1)
            deleteat!(p.links, findfirst(x -> x.node == q, p.links))
    else
        deleteat!(p.links, findfirst(x -> x.node == q, p.links))
        deleteat!(q.links, findfirst(x -> x.node == p, q.links))
    end

    return nothing
end

"""
    descent_order(p::Node, q::Node)::Tuple{Node,Node}

Given two linked directed nodes, return a tuple with the parent and child nodes in that order.
"""
function descent_order(p::Node, q::Node)::Tuple{Node,Node}
    ! p.isdirected || ! q.isdirected && throw(UndirectedError())
    q.hasparent && q.links[1].node == p && return (p, q)
    p.hasparent && p.links[1].node == q && return (q, p)
    throw(LinkingError())
end

"""
    ascent_order(p::Node, q::Node)::Tuple{Node,Node}

Given two linked directed nodes, return a tuple with the child and parent nodes in that order.
"""
function ascent_order(p::Node, q::Node)::Tuple{Node,Node}
    ! p.isdirected || ! q.isdirected && throw(UndirectedError())
    q.hasparent && q.links[1].node == p && return (q, p)
    p.hasparent && p.links[1].node == q && return (p, q)
    throw(LinkingError())
end