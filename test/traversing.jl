include("trees/tree1.jl")

@testset "Unrooted tree" begin
    @testset "Preorder" begin
        tree = Tree(a)
        @test preorder(d, e) == [d, c, b, a, n, o, p , q, r, s, t]
        @test preorder(e, d) == [e, f,  g, h, i, j, k, l, m]
        @test_throws Phylodendron.LinkingError preorder(f, c)
        @test preorder(f) == [f, e, d, c, b, a, n, o, p, q, r, s, t, i, j, k, l, m, g, h]
        @test preorder(a) == [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t]
        @test preorder(a, b) == [a]
        @test_throws Phylodendron.LinkingError preorder(a, c)
        @test_throws Phylodendron.UndirectedError preorder(a, true)
        
        trav = PreorderTraverser(tree)

        @test next!(trav) == a
        @test next!(trav) == b
        @test nextpair!(trav) == (c, b)
        @test nextpair!(trav) == (d, c)
        @test isfinished(trav) == false

        for i in 1:16
            next!(trav)
        end

        @test isfinished(trav) == true
        @test_throws Phylodendron.FinishedTraversalError next!(trav)
        @test_throws Phylodendron.FinishedTraversalError nextpair!(trav)
    end
    @testset "Postorder" begin
        @test postorder(d, e) == [t, s, r, q, p, o, n, a, b, c, d]
        @test postorder(e, d) == [m, l, k, j, i, h, g, f, e]
        @test_throws Phylodendron.LinkingError postorder(d, r)
        @test postorder(f) == [h, g, m, l, k, j, i, t, s, r, q, p, o, n, a, b, c, d, e, f]
        @test postorder(a) == [t, s, r, q, p, o, n, m, l, k, j, i, h, g, f, e, d, c, b, a]
        @test_throws Phylodendron.UndirectedError postorder(a, true)

        trav = PostorderTraverser(tree)

        @test next!(trav) == t
        @test next!(trav) == s
        @test nextpair!(trav) == (r, n)
        @test nextpair!(trav) == (q, o)
        @test isfinished(trav) == false

        for i in 1:16
            next!(trav)
        end

        @test isfinished(trav) == true
        @test_throws Phylodendron.FinishedTraversalError next!(trav)
        @test_throws Phylodendron.FinishedTraversalError nextpair!(trav)
    end
    @testset "Node paths" begin
        @test node_path(a, g) == [b, c, d, e, f]
        @test node_path(g, a) == [f, e, d, c, b]
        @test node_path(s, c) == [r, n]
        @test node_path(c, s) == [n, r]
        @test node_path(b, d) == [c]
        @test node_path(d, b) == [c]
        @test node_path(h, h) == []
        @test node_path(f, h) == []
    end
    @testset "Ancestry" begin
        @test_throws Phylodendron.UndirectedError ancestry(a)
    end
    @testset "Most recent common ancestors" begin
        @test_throws Phylodendron.UndirectedError mrca(a, g)
    end
end

# Root the tree on A
trav = PreorderTraverser(a)
x = next!(trav)
x.isdirected = true
while ! isfinished(trav)
    x = next!(trav)
    x.isdirected = true
    x.hasparent = true
end

@testset "Rooted tree" begin
    @testset "Preorder" begin
        @test preorder(f) == [f, g, h]
        @test preorder(a) == [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t]
        @test preorder(f, false) == [f, e, d, c, b, a, n, o, p, q, r, s, t, i, j, k, l, m, g, h]
        @test preorder(a, false) == [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t]
        
        trav = PreorderTraverser(a)

        @test next!(trav) == a
        @test next!(trav) == b
        @test nextpair!(trav) == (c, b)
        @test nextpair!(trav) == (d, c)
        @test isfinished(trav) == false

        for i in 1:16
            next!(trav)
        end

        @test isfinished(trav) == true
        @test_throws Phylodendron.FinishedTraversalError next!(trav)
        @test_throws Phylodendron.FinishedTraversalError nextpair!(trav)
    end
    @testset "Postorder" begin
        @test postorder(f) == [h, g, f]
        @test postorder(a) == [t, s, r, q, p, o, n, m, l, k, j, i, h, g, f, e, d, c, b, a]
        @test postorder(f, false) == [h, g, m, l, k, j, i, t, s, r, q, p, o, n, a, b, c, d, e, f]
        @test postorder(a, false) == [t, s, r, q, p, o, n, m, l, k, j, i, h, g, f, e, d, c ,b, a]

        trav = PostorderTraverser(a)

        @test next!(trav) == t
        @test next!(trav) == s
        @test nextpair!(trav) == (r, n)
        @test nextpair!(trav) == (q, o)
        @test isfinished(trav) == false

        for i in 1:16
            next!(trav)
        end

        @test isfinished(trav) == true
        @test_throws Phylodendron.FinishedTraversalError next!(trav)
        @test_throws Phylodendron.FinishedTraversalError nextpair!(trav)
    end
    @testset "Node paths" begin
        @test node_path(a, g) == [b, c, d, e, f]
        @test node_path(g, a) == [f, e, d, c, b]
        @test node_path(s, c) == [r, n]
        @test node_path(c, s) == [n, r]
        @test node_path(b, d) == [c]
        @test node_path(d, b) == [c]
        @test node_path(h, h) == []
        @test node_path(f, h) == []
    end
    @testset "Ancestry" begin
        @test ancestry(a) == []
        @test ancestry(g) == [f, e, d, c, b, a]
        @test ancestry(b) == [a]
        @test ancestry(q) == [o, n, c, b, a]
    end
    @testset "Most recent common ancestors" begin
        @test_throws Phylodendron.UndefParentError mrca(a, g)
        @test mrca(s, c) == b
        @test mrca(b, d) == a
        @test mrca(t, t) == r
        @test mrca(g, h) == f
        @test mrca(h, g) == f
        @test mrca(m, n) == c
        @test mrca(n, m) == c
        @test mrca(k, g) == e
        @test mrca(g, k) == e
    end
end