"""
    graft!(p::Node, q::Node, r::Node)::Node

Graft a subtree onto another tree.

Link node `p` to a new node insterted between nodes `q` and `r`. Return the newly created node. 

    ○——○  ○  ->  ○——̩○——○
    q  r  p      q  ̍○  r
                    p

Warning: This function does not preserve the information (length, label, etc.) of the branch between `q` and `r`.
"""
function graft!(p::Node, q::Node, r::Node)::Node
    s = Node()
    if ! isdirected(q)
        # Unroot the graft tree if the receiver tree is unrooted
        ! isdirected(p) || unroot!(p)
    else
        # Root the graft tree in p if the receiver tree is rooted
        isdirected(p) || root!(p)

        q, r = descent_order(q, r)
    end

    unlink!(q, r)
    link!(q, s)
    link!(s, p)
    link!(s, r)

    return s
end

"""
    snip!(p::Node, q::Node, r::Node; rootsafe::Bool=true)::Nothing

Unlink node `p` from `q` and `r`, and link `q` to `r`. Like so:

    ○——○——○  =>  ○——○  ○
    q  p  r      q  r  p

If the original tree was rooted, the escinded subtree will be rerooted on `p`. When `rootsafe` is true, snipping the root will throw an exception. Otherwise, the tree will be rerooted on `q`.

Warning: This the length of the new branch between `q` and `r` will be the sum of the lengths of the branches between `q` and `p` and between `p` and `r`, but all the other information (labels, extras, etc.) of the old branches will be lost.
"""
function snip!(p::Node, q::Node, r::Node; rootsafe::Bool=true)::Nothing
    if isdirected(p) && ! hasparent(p)
        rootsafe ? throw(RootError()) : root!(q)
    end

    idx_q2p = findfirst(x -> x.node == p, q.links)
    br_qp = q.links[idx_q2p].branch
    idx_r2p = findfirst(x -> x.node == p, r.links)
    br_rp = r.links[idx_r2p].branch

    br_qr = Branch(br_qp.length + br_rp.length)

    q.links[idx_q2p] = Link(r, br_qr)
    r.links[idx_r2p] = Link(q, br_qr)

    deleteat!(p.links, findfirst(x -> x.node == q, p.links))
    deleteat!(p.links, findfirst(x -> x.node == r, p.links))

    isdirected(p) && root!(p)

    return nothing
end

"""
    collapse_nonsplitting!(t::Tree; skiporigin::Bool=true)

Collapse the non-splitting internal nodes in tree `t`.

By default `skiporigin` is set to `true` so that the origin node are not affected. If `skiporigin` is set to `false` and the origin node is collapsed, the first splitting internal node found in preorder will be designated as the new origin of the tree.
"""
function collapse_nonsplitting!(t::Tree; skiporigin::Bool=true)::Nothing
    trav = PreorderTraverser(t.origin)
    neworigin = t.origin
    targets = Deque{Node}()
    while ! isfinished(trav)
        p = next!(trav)
        if p == t.origin
            (t.rooted || skiporigin) && continue
        end
        if n_neighbours(p) == 2
            push!(targets, p)
        elseif ! istip(p)
            neworigin = neworigin == t.origin ? p : neworigin
        end
    end

    for p in targets
        t.origin = p == t.origin ? neworigin : t.origin
        q, r = neighbours(p)
        snip!(p, q, r)
    end

    t.rooted && root!(t)

    t.autoupdate && update!(t)

    return nothing
end