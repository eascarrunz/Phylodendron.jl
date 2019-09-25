abstract type Traverser end

"""
    PreorderTraverser(p::Node, q::Node, directed::Bool=isdirected(p))

Create a traverser object that yields the nodes of a subtree in preorder.

The target subtree includes the node `p` but excludes all the nodes that are linked to its neighbour `q`. If `p` and `q` are the same node, the entire tree is traversed.

In rooted trees, only the clade subtended by `p` will be traversed, unless the `directed` argument is set to `false`.
"""
struct PreorderTraverser <: Traverser
    stack::Deque{Tuple{Node,Node}}
    directed::Bool

    function PreorderTraverser(p::Node, q::Node, directed::Bool=isdirected(p))
        if directed && ! isdirected(p)
            throw(UndirectedError())
        end
        p == q || q ∈ neighbours(p) || throw(LinkingError())

        s = Deque{Tuple{Node, Node}}()
        push!(s, (p, q))

        return new(s, directed)
    end
end

"""
PreorderTraverser(p::Node, directed::Bool=isdirected(p))

Create a traverser object that yields the nodes of the tree in preorder.

The traversal is initiated at node `p`. 

In rooted trees, only the clade subtended by `p` will be traversed, unless the `directed` argument is set to `false`.
"""
PreorderTraverser(p::Node, directed::Bool=isdirected(p)) = PreorderTraverser(p, p, directed)

PreorderTraverser(t::Tree, directed::Bool=isdirected(t.origin)) = 
    PreorderTraverser(t.origin, t.origin, directed)

"""
    isfinished(x::Traverser)::Bool 

Return `true` if the tree traversal of `x` has been completed.
"""
@inline isfinished(x::Traverser)::Bool = isempty(x.stack)

"""
    next!(x::Traverser)::Node

Advance the tree traverser `x` and return the next node.
"""
next!(x::Traverser)::Node = nextpair!(x)[1]

"""
    nextpair!(x::PreorderTraverser)::Tuple{Node,Node}

Advance the preorder tree traverser `x` and return a tuple with the next node and its parent.
"""
@views function nextpair!(x::PreorderTraverser)::Tuple{Node,Node}
    isfinished(x) && throw(FinishedTraversalError())

    if ! x.directed
        p, parent_p = pop!(x.stack)
        @inbounds for link in p.links[end:-1:1]
            link.node ≠ parent_p && push!(x.stack, (link.node, p))
        end
    else
        p, parent_p = pop!(x.stack)
        children_p = children(p)[end:-1:1]
        @inbounds for q in children_p
            push!(x.stack, (q, p))
        end
    end

    return p, parent_p
end

"""
    preorder(p::Node, q::Node, directed::Bool=isdirected(p))::NodeVector

Return the preorder sequence of the nodes connected to `p`, excluding the subtree connected it its neighbour `q`.

With undirected nodes (in unrooted trees), it is possible to make directed traversals, which only cover the clade subtended by the node `p`, or undirected traversals that cover all nodes of the subtree as if it were rooted on `p`.
"""
function preorder(p::Node, q::Node, directed::Bool=isdirected(p))::NodeVector
    traverser = PreorderTraverser(p, q, directed)
    a = Deque{Node}()

    while ! isfinished(traverser)
        q = next!(traverser)
        push!(a, q)
    end

    return collect(a)
end

preorder(t::Tree, directed::Bool=isdirected(t.origin)) = preorder(t.origin, t.origin, directed)

"""
    preorder(p::Node, directed::Bool=isdirected(p))::NodeVector

Return the preorder sequence of the nodes connected to `p`.

With undirected nodes (in unrooted trees), it is possible to make directed traversals, which only cover the clade subtended by the node `p`, or undirected traversals that cover all nodes of the tree as if it were rooted on `p`.
"""
preorder(p::Node, directed::Bool=isdirected(p))::NodeVector = preorder(p, p, directed)

"""
    PostorderTraverser(p::Node, q::Node, directed::Bool=isdirected(p))

Create a traverser object that yields the nodes of a subtree in postorder.

The target subtree includes the node `p` but excludes all the nodes that are linked to its neighbour `q`. If `p` and `q` are the same node, the entire tree is traversed.

In rooted trees, only the clade subtended by `p` will be traversed, unless the `directed` argument is set to `false`.
"""
struct PostorderTraverser <: Traverser
    stack::Deque{Tuple{Node,Node,Bool}}
    directed::Bool

    function PostorderTraverser(p::Node, q::Node, directed::Bool=isdirected(p))
        if directed && ! isdirected(p)
            throw(UndirectedError())
        end
        p == q || q ∈ neighbours(p) || throw(LinkingError())

        s = Deque{Tuple{Node,Node,Bool}}()
        push!(s, (p, q, false))
        
        return new(s, directed)
    end
end

"""
PostorderTraverser(p::Node, directed::Bool=isdirected(p))

Create a traverser object that yields the nodes of the tree in postorder.

The traversal is initiated at node `p`. 

In rooted trees, only the clade subtended by `p` will be traversed, unless the `directed` argument is set to `false`.
"""
PostorderTraverser(p::Node, directed::Bool=isdirected(p)) = PostorderTraverser(p, p, directed)

PostorderTraverser(t::Tree, directed::Bool=isdirected(t.origin)) = 
    PostorderTraverser(t.origin, t.origin, directed)

"""
    nextpair!(x::PostorderTraverser)::Tuple{Node,Node}

Advance the postorder tree traverser `x` and return a tuple with the next node and its parent.
"""
@views function nextpair!(x::PostorderTraverser)::Tuple{Node,Node}
    isfinished(x) && throw(FinishedTraversalError())

    p, parent_p, marked = pop!(x.stack)
    if ! x.directed
        while ! marked
            push!(x.stack, (p, parent_p, true))
            for link in p.links
                link.node ≠ parent_p && push!(x.stack, (link.node, p, false))
            end

            p, parent_p, marked = pop!(x.stack)
        end
    else
        while ! marked
            push!(x.stack, (p, parent_p, true))
            children_p = children(p)
            for q in children_p
                push!(x.stack, (q, p, false))
            end

            p, parent_p, marked = pop!(x.stack)
        end
    end

    return p, parent_p
end

"""
    postorder(p::Node, q::Node, directed::Bool=isdirected(p))::NodeVector

Return the postorder sequence of the nodes connected to `p`, excluding the subtree connected to its neighour `q`.

With undirected nodes (in unrooted trees), it is possible to make directed traversals, which only cover the clade subtended by the node `p`, or undirected traversals that cover all nodes of the subtree as if it were rooted on `p`.
"""
function postorder(p::Node, q::Node, directed::Bool=isdirected(p))::NodeVector
    traverser = PostorderTraverser(p, q, directed)
    a = Deque{Node}()
    while ! isfinished(traverser)
        q = next!(traverser)
        push!(a, q)
    end

    return collect(a)
end

psotorder(t::Tree, directed::Bool=isdirected(t.origin)) = 
    postorder(t.origin, t.origin, directed)

"""
    postorder(p::Node, directed::Bool=isdirected(p))::NodeVector

Return the postorder sequence of the nodes connected to `p`.

With undirected nodes (in unrooted trees), it is possible to make directed traversals, which only cover the clade subtended by the node `p`, or undirected traversals that cover all nodes of the tree as if it were rooted on `p`.
"""
postorder(p::Node, directed::Bool=isdirected(p))::NodeVector  = postorder(p, p, directed)

"""
    ancestry(p::Node)::NodeVector

Find all the ancestors of a node up to the root of the tree.
"""
function ancestry(p::Node)::NodeVector
    p.isdirected || throw(UndirectedError())

    anc = Deque{Node}()
    while p.hasparent
        p = p.links[1].node
        push!(anc, p)
    end

    return collect(anc)
end

"""
    mrca(p::Node, q::Node)::Node

Find the most recent common ancestor of two nodes in a rooted tree.

If one of the nodes is an ancestor of the other, return the parent of the ancestral node.
"""
function mrca(p::Node, q::Node)::Node
    anc_p = ancestry(p)
    anc_q = ancestry(q)
    ! p.hasparent && throw(UndefParentError())
    ! q.hasparent && throw(UndefParentError())

    anc_p[end] == anc_q[end] || throw(LinkingError)

    # Determine the maximum number of ancestors that could be shared between p and q
    maxancs = length(anc_p) < length(anc_q) ? length(anc_p) : length(anc_q)

    # Compare ancestors of p and q, starting from the root. Stop if a different ancestor is found.
    mrca_pq = anc_p[end]  # Keep track of the last ancestor known to be shared.
    for i in 1:(maxancs-1)
        anc_p[end-i] ≠ anc_q[end-i] && break
        mrca_pq = anc_p[end-i]
    end

    return mrca_pq
end

"""
    node_path(p::Node, q::Node)::NodeVector

Find the shortest path between two nodes.
"""
function node_path(p::Node, q::Node)::NodeVector
    #=
    The current implementation is valid for rooted and unrooted trees and has a time complexity proportional to the diameter of the tree. A better implementation is possible for rooted trees.
    =#
    p == q && return Node[]
    visits = Deque{Tuple{Node,Node}}()

    trav = PreorderTraverser(p, false)
    next!(trav)  # Skip the first node, which is p
    while ! isfinished(trav)
        r, parent_r = nextpair!(trav)
        push!(visits, (r, parent_r))
        r == q && break
    end

    path = Deque{Node}()
    r, target = pop!(visits)
    while ! isempty(visits)
        r, parent_r = pop!(visits)
        if r == target
            pushfirst!(path, r)
            target = parent_r
        end
    end

    return collect(path)
end