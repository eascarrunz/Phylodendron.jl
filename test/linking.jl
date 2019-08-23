a = Node()
b = Node()
c = Node()
d = Node()

@testset "Linking undirected nodes" begin
    @testset "(b)a" begin
        link!(a, b)

        # Number of links in `a`
        @test length(a.links) == 1
        # Number of links in `b`
        @test length(b.links) == 1
        # `a` linking to `b`
        @test a.links[1].node == b
        # `b` linking to `a`
        @test b.links[1].node == a
        # Links to `a` and `b` have the same branch
        @test a.links[1].branch == b.links[1].branch
    end

    
    @testset "(b,c)a" begin
        link!(a, c)

        # Number of links in `a`
        @test length(a.links) == 2
        # Number of links in `c`
        @test length(c.links) == 1
        # `a`'s second link is to `c`
        @test a.links[2].node == c
        # `c` linking to `a`
        @test c.links[1].node == a
        # Links to `a` and `c` have the same branch
        @test a.links[2].branch == c.links[1].branch
    end

    @testset "((b,c)a)d" begin
        link!(d, a)

        # Number of links in `a`
        @test length(a.links) == 3
        # Number of links in `d`
        @test length(c.links) == 1
        # `a`'s first link is to `d`
        @test a.links[1].node == d
        # `a`'s second link is to `b`
        @test a.links[2].node == b
        # `a`'s third link is to `c`
        @test a.links[3].node == c
        # `d` linking to `a`
        @test d.links[1].node == a
        # Links to `a` and `d` have the same branch
        @test a.links[1].branch == d.links[1].branch
        # Neighbour vector of `a`
        @test neighbours(a) == [d, b, c]
    end
end

@testset "Unlinking undirected nodes" begin
    @testset "Unlink `d`" begin
        unlink!(d, a)

        # `d` has no neighbours
        @test length(d.links) == 0
        # Order of links in neighbour vector of `a`
        @test neighbours(a) == [b, c]

        # Again testing commutativity of `unlink!`
        link!(d, a)
        unlink!(a, d)

        # `d` has no neighbours
        @test length(d.links) == 0
        # Order of links in neighbour vector of `a`
        @test neighbours(a) == [b, c]
    end
end

a = Node()
b = Node()
c = Node()
d = Node()

a.isdirected = true
b.isdirected = true
c.isdirected = true
d.isdirected = true

@testset "Linking directed nodes" begin
    @testset "(b)a" begin
        link!(a, b)

        # `a` does not have a parent
        @test ! a.hasparent
        # `b` has a parent
        @test b.hasparent
        # `a` is the parent of `b`
        @test b.links[1].node == a
        # Children of `a`
        @test a.links[1].node == b
        # Children of `b`
        @test b.links[2:end] == Link[]
    end

    @testset "(b,c)a" begin
        link!(a, c)

        # `a` does not have a parent
        @test ! a.hasparent
        # `c` has a parent
        @test c.hasparent
        # `b` and `c` are siblings
        @test b.links[1].node == c.links[1].node == a
        # Children of `a`
        @test [link.node for link in a.links] == [b, c]
    end

    @testset "((b,c)a)d" begin
        link!(d, a)

        # `a` has a parent
        @test a.hasparent
        # `d` does not have a parent
        @test ! d.hasparent
        # Parent of `a`
        @test a.links[1].node == d
        # Neighbours of `a`
        @test [link.node for link in a.links] == [d, b, c]
    end
end

@testset "Unlinking directed nodes" begin
    unlink!(d, a)

    # `a` has no parent
    @test ! a.hasparent
    # `d` has no neighbours
    @test [link.node for link in d.links] == Node[]
    # Neighbour vector of `a`
    @test [link.node for link in a.links] == [b, c]
end

d = Node()
@testset "Linking undirected nodes to directed nodes" begin
    link!(d, a)

    # `d` is directed
    @test d.isdirected
    # `a` is directed
    @test a.isdirected
    # `a` has a parent
    @test a.hasparent
    # `d` has no parent
    @test ! d.hasparent
    # `d` is linked to `a`
    @test d.links[1].node == a
    # `d` is the parent of `a`
    @test a.links[1].node == d
end

include("trees/tree1.jl")
@testset "Node tuples in ascent and descent order" begin
    root!(d)
    @testset "Ascent order" begin
        @test ascent_order(b, c) == (b, c)
        @test ascent_order(c, b) == (b, c)
        @test ascent_order(s, r) == (s, r)
        @test ascent_order(r, s) == (s, r)
        @test_throws Phylodendron.LinkingError ascent_order(q, n)
    end
    @testset "Descent order" begin
        @test descent_order(b, c) == (c, b)
        @test descent_order(c, b) == (c, b)
        @test descent_order(s, r) == (r, s)
        @test descent_order(r, s) == (r, s)
        @test_throws Phylodendron.LinkingError descent_order(q, n)
    end
end