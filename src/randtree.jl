"""
    randtree(n::Int, rooted::Bool = false, labels=string.(1:n); fullinit=true)

Create a binary tree by the random addition of `n` tips.

Set `fullinit` to `false` to prevent the initialisation of the non-essential fields of the tree object.
"""
function randtree(n::Int, rooted::Bool = false, labels=string.(1:n); fullinit=true)
    origin = Node()
    if rooted
        if n > 2
            origin.isdirected = true
            nodes = [origin, Node(labels[1]), Node(labels[2])]
            link!(origin, nodes[2])
            link!(origin, nodes[3])

            for i in 3:n
                p = Node(labels[i])
                q = rand(nodes)
                r = rand(neighbours(q))

                s = graft!(p, q, r)

                push!(nodes, r, s)
            end
        end
    else
        if n > 3
            nodes = [origin, Node(labels[1]), Node(labels[2]), Node(labels[3])]
            link!(origin, nodes[2])
            link!(origin, nodes[3])
            link!(origin, nodes[4])

            for i in 4:n
                p = Node(labels[i])
                q = rand(nodes)
                r = rand(neighbours(q))

                s = graft!(p, q, r)

                push!(nodes, r, s)
            end
        end
    end

    return Tree(origin; fullinit=fullinit)
end