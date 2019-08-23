@testset "Grafting and snipping" begin
    a = Node("A")
    b = Node("B")
    c = Node("C")
    d = Node("D")
    e = Node("E")
    f = Node("F")
    g = Node("G")
    h = Node("H")
    i = Node("I")

    # Create receiver butterfly
    link!(a, b)
    link!(b, c)
    link!(b, d)
    link!(d, e)
    link!(d, f)

    # Create 3-node graft
    link!(g, h)
    link!(h, i)

    @testset "Unrooted trees" begin
        # Graft h between b and d
        x = graft!(h, b, d)

        @test [link.node for link in x.links] == [b, h, d]
        @test [link.node for link in b.links] == [a, c, x]
        @test [link.node for link in d.links] == [x, e, f]

        snip!(x, b, d)

        @test [link.node for link in x.links] == [h]
        @test [link.node for link in b.links] == [a, c, d]
        @test [link.node for link in d.links] == [b, e, f]
    end

    @testset "Rooted receiver tree" begin
        a = Node("A")
        b = Node("B")
        c = Node("C")
        d = Node("D")
        e = Node("E")
        f = Node("F")
        g = Node("G")
        h = Node("H")
        i = Node("I")

        # Create receiver butterfly
        link!(a, b)
        link!(b, c)
        link!(b, d)
        link!(d, e)
        link!(d, f)

        # Root the tree in B
        a.isdirected, a.hasparent = true, true
        b.isdirected, b.hasparent = true, false
        c.isdirected, c.hasparent = true, true
        d.isdirected, d.hasparent = true, true
        e.isdirected, e.hasparent = true, true
        f.isdirected, f.hasparent = true, true
        

        # Create 3-node graft
        link!(g, h)
        link!(h, i)
        @testset "Receiver br. in descent order" begin
            # Graft h between b and d
            x = graft!(h, b, d)

            @test [link.node for link in x.links] == [b, h, d]
            @test [link.node for link in b.links] == [a, c, x]
            @test [link.node for link in d.links] == [x, e, f]

            @test b.isdirected
            @test d.isdirected
            @test x.isdirected
            @test g.isdirected * h.isdirected * i.isdirected

            snip!(x, b, d)

            @test [link.node for link in x.links] == [h]
            @test [link.node for link in b.links] == [a, c, d]
            @test [link.node for link in d.links] == [b, e, f]
            @test ! hasparent(x)
        end

        a = Node("A")
        b = Node("B")
        c = Node("C")
        d = Node("D")
        e = Node("E")
        f = Node("F")
        g = Node("G")
        h = Node("H")
        i = Node("I")

        # Create receiver butterfly
        link!(a, b)
        link!(b, c)
        link!(b, d)
        link!(d, e)
        link!(d, f)

        # Create 3-node graft
        link!(g, h)
        link!(h, i)
        @testset "Receiver br. in ascent order" begin
            # Root the tree in B
            a.isdirected, a.hasparent = true, true
            b.isdirected, b.hasparent = true, false
            c.isdirected, c.hasparent = true, true
            d.isdirected, d.hasparent = true, true
            e.isdirected, e.hasparent = true, true
            f.isdirected, f.hasparent = true, true

            # Graft h between b and d
            x = graft!(h, d, b)

            @test [link.node for link in x.links] == [b, h, d]
            @test [link.node for link in b.links] == [a, c, x]
            @test [link.node for link in d.links] == [x, e, f]

            @test b.isdirected
            @test d.isdirected
            @test x.isdirected
            @test g.isdirected * h.isdirected * i.isdirected

            snip!(x, d, b)
            label!(x, "X")

            @test [link.node for link in x.links] == [h]
            @test [link.node for link in b.links] == [a, c, d]
            @test [link.node for link in d.links] == [b, e, f]
            @test ! hasparent(x)
        end
    end
end

@testset "Collape non-splitting nodes" begin
    include("trees/tree1.jl")
    collapse_nonsplitting!(tree)
    @test preorder(tree.origin) == [b, a, c, e, f, g, h, i, k, l, m, n, o, p, q, r, s, t]
    include("trees/tree1.jl")
    collapse_nonsplitting!(tree; skiporigin=false)
    @test preorder(tree.origin) == [c, a, e, f, g, h, i, k, l, m, n, o, p, q, r, s, t]
    include("trees/tree1.jl")
    root!(tree)
    collapse_nonsplitting!(tree)
    @test preorder(tree.origin) == [b, a, c, e, f, g, h, i, k, l, m, n, o, p, q, r, s, t]
    include("trees/tree1.jl")
    root!(tree)
    collapse_nonsplitting!(tree; skiporigin=false)
    @test preorder(tree.origin) == [b, a, c, e, f, g, h, i, k, l, m, n, o, p, q, r, s, t]
end