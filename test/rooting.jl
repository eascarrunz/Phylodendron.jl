include("trees/tree1.jl")

@testset "Root from node A" begin
    root!(a)

    @testset "Directedness and parenthood" begin
        @test isdirected(a)
        @test ! hasparent(a)

        trav = PreorderTraverser(a)
        next!(trav)
        while ! isfinished(trav)
            x = next!(trav)
            @test isdirected(x)
            @test hasparent(x)
        end
    end
    @testset "Node order" begin
        @test preorder(a) == [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t]
    end
    @testset "Find root from any node" begin
        @test getroot(a) == a
        @test getroot(f) == a
        @test getroot(n) == a
        @test getroot(r) == a
        @test getroot(d) == a
        @test getroot(i) == a
    end
end

@testset "Root from node D" begin
    root!(d)

    @testset "Directedness and parenthood" begin
        @test isdirected(d)
        @test ! hasparent(d)

        trav = PreorderTraverser(d)
        next!(trav)
        while ! isfinished(trav)
            x = next!(trav)
            @test isdirected(x)
            @test hasparent(x)
        end
    end
    @testset "Node order" begin
        @test preorder(d) == [d, c, b, a, n, o, p, q, r, s, t, e, f, g, h, i, j, k, l, m]
    end
    @testset "Find root from any node" begin
        @test getroot(a) == d
        @test getroot(f) == d
        @test getroot(n) == d
        @test getroot(r) == d
        @test getroot(d) == d
        @test getroot(i) == d
    end
end

@testset "Root from node I" begin
    root!(i)

    @testset "Directedness and parenthood" begin
        @test isdirected(i)
        @test ! hasparent(i)

        trav = PreorderTraverser(i)
        next!(trav)
        while ! isfinished(trav)
            x = next!(trav)
            @test isdirected(x)
            @test hasparent(x)
        end
    end
    @testset "Node order" begin
        @test preorder(i) == [i, e, d, c, b, a, n, o, p, q, r, s, t, f, g, h, j, k, l, m]
    end
    @testset "Find root from any node" begin
        @test getroot(a) == i
        @test getroot(f) == i
        @test getroot(n) == i
        @test getroot(r) == i
        @test getroot(d) == i
        @test getroot(i) == i
    end
end

@testset "Unrooting" begin
    unroot!(d)

    @testset "Directedness and parenthood" begin

        trav = PreorderTraverser(a)
        while ! isfinished(trav)
            x = next!(trav)
            @test ! isdirected(x)
            @test_throws Phylodendron.UndirectedError hasparent(x)
        end
    end
    @testset "Find root from any node" begin
        @test_throws Phylodendron.UndirectedError getroot(a)
    end
end

@testset "Rooting with an outgroup" begin
    y = as_outgroup!(a)

    @testset "Directedness and parenthood" begin
        @test isdirected(y)
        @test ! hasparent(y)

        trav = PreorderTraverser(y)
        next!(trav)
        while ! isfinished(trav)
            x = next!(trav)
            @test isdirected(x)
            @test hasparent(x)
        end
    end
    @testset "Node order" begin
        @test preorder(y) == [y, a, b, c, d, e, i, j, k, l, m, f, g, h, n, o, p, q, r, s, t]
    end
    @testset "Find root from any node" begin
        @test getroot(a) == y
        @test getroot(f) == y
        @test getroot(n) == y
        @test getroot(r) == y
        @test getroot(d) == y
        @test getroot(i) == y
    end
end