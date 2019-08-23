@testset "Undirected (b,(d,(f,g)e)c)a" begin
    a = Node()
    b = Node()
    c = Node()
    d = Node()
    e = Node()
    f = Node()
    g = Node()

    link!(a, b)
    link!(a, c)
    link!(c, d)
    link!(c, e)
    link!(e, f)
    link!(e, g)

    @testset "Directedness" begin
        @test ! isdirected(a)
    end
    @testset "Tips" begin
        @test ! istip(a)
        @test istip(b)
        @test ! istip(c)
        @test istip(d)
        @test ! istip(e)
        @test istip(f)
        @test istip(g)    
    end
    @testset "Parenthood" begin
        @test_throws Phylodendron.UndirectedError hasparent(a)
        @test_throws Phylodendron.UndirectedError hasparent(b)
        @test_throws Phylodendron.UndirectedError parent(a)
        @test_throws Phylodendron.UndirectedError parent(b)
    end
    @testset "Neighbourhood" begin
        @test neighbours(a) == [b, c]
        @test n_neighbours(a) == 2
        @test neighbours(b) == [a]
        @test n_neighbours(b) == 1
        @test neighbours(c) == [a, d, e]
        @test n_neighbours(c) == 3
    end
    @testset "Children" begin
        @test_throws Phylodendron.UndirectedError children(a)
        @test_throws Phylodendron.UndirectedError n_children(a)
        @test_throws Phylodendron.UndirectedError children(b)
        @test_throws Phylodendron.UndirectedError n_children(b)
        @test_throws Phylodendron.UndirectedError children(c)
        @test_throws Phylodendron.UndirectedError n_children(c)
    end
    @testset "Labels" begin
        @test a.label == ""

        label!(a, "a")

        @test a.label == "a"
        @test label(a) == "a"
    end
    @testset "Get branch" begin
        @test getbranch(a, b) == a.links[1].branch
        @test getbranch(b, a) == a.links[1].branch
        @test getbranch(a, c) == a.links[2].branch
        @test getbranch(c, a) == a.links[2].branch
        @test getbranch(c, e) == e.links[1].branch
        @test getbranch(e, c) == e.links[1].branch
        @test getbranch(e, f) == f.links[1].branch
        @test getbranch(f, e) == f.links[1].branch
        @test_throws Phylodendron.LinkingError getbranch(a, f)
        @test_throws Phylodendron.LinkingError getbranch(c, g)
        @test_throws Phylodendron.UndirectedError getbranch(a)
        @test_throws Phylodendron.UndirectedError getbranch(e)
    end
    @testset "Branch lengths" begin
        @test isnan(brlength(a, b))
        @test_throws Phylodendron.UndirectedError brlength(a)

        brlength!(a, b, 12.3)
        @test_throws Phylodendron.UndirectedError brlength!(a, 12.3)
        @test brlength(a, b) == 12.3
    end
    @testset "Branch labels" begin
        @test brlabel(a, b) == ""
        @test_throws Phylodendron.UndirectedError brlabel(a)

        brlabel!(a, b, "ab")
        @test_throws Phylodendron.UndirectedError brlabel!(a, "ab")
        @test brlabel(a, b) == "ab"
    end
    @testset "Subtree sizes" begin
        @test subtree_size(c, a) == 5
        @test subtree_size(a, c) == 2
        @test subtree_size(e, c) == 3
        @test subtree_size(e, f) == 6
        @test_throws ArgumentError subtree_size(e, e)
        @test_throws ArgumentError subtree_size(e, b)
    end
end
@testset "Directed (b,(d,(f,g)e)c)a" begin
    a = Node()
    b = Node()
    c = Node()
    d = Node()
    e = Node()
    f = Node()
    g = Node()

    a.isdirected = b.isdirected = c.isdirected = d.isdirected = e.isdirected = f.isdirected = g.isdirected = true

    link!(a, b)
    link!(a, c)
    link!(c, d)
    link!(c, e)
    link!(e, f)
    link!(e, g)

    @testset "Directedness" begin
        @test isdirected(a)
    end
    @testset "Parenthood" begin
        @test hasparent(a) == false
        @test hasparent(b) == true
        @test hasparent(c) == true
        @test_throws Phylodendron.UndefParentError parent(a)
        @test parent(b) == a
        @test parent(c) == a
    end
    @testset "Neighbourhood" begin
        @test neighbours(a) == [b, c]
        @test n_neighbours(a) == 2
        @test neighbours(b) == [a]
        @test n_neighbours(b) == 1
        @test neighbours(c) == [a, d, e]
        @test n_neighbours(c) == 3
    end
    @testset "Children" begin
        @test children(a) == [b, c]
        @test n_children(a) == 2
        @test children(b) == Node[]
        @test n_children(b) == 0
        @test children(c) == [d, e]
        @test n_children(c) == 2
    end
    @testset "Labels" begin
        @test a.label == ""

        label!(a, "a")

        @test a.label == "a"
        @test label(a) == "a"
    end
    @testset "Get branch" begin
        @test getbranch(a, b) == a.links[1].branch
        @test getbranch(b, a) == a.links[1].branch
        @test getbranch(a, c) == a.links[2].branch
        @test getbranch(c, a) == a.links[2].branch
        @test getbranch(c, e) == e.links[1].branch
        @test getbranch(e, c) == e.links[1].branch
        @test getbranch(e, f) == f.links[1].branch
        @test getbranch(f, e) == f.links[1].branch
        @test_throws Phylodendron.LinkingError getbranch(a, f)
        @test_throws Phylodendron.LinkingError getbranch(c, g)
        @test_throws Phylodendron.UndefParentError getbranch(a)
        @test getbranch(b) == b.links[1].branch
        @test getbranch(c) == c.links[1].branch
        @test getbranch(d) == d.links[1].branch
        @test getbranch(e) == e.links[1].branch
        @test getbranch(f) == f.links[1].branch
        @test getbranch(g) == g.links[1].branch
    end
    @testset "Branch lengths" begin
        @test isnan(brlength(a, b))
        @test isnan(brlength(b))

        brlength!(b, 12.3)

        @test brlength(b) == 12.3
    end
    @testset "Branch labels" begin
        @test brlabel(a, b) == ""
        @test_throws Phylodendron.UndefParentError brlabel(a)

        brlabel!(b, "ab")

        @test brlabel(b) == "ab"
        @test brlabel(a, b) == "ab"
    end
    @testset "Subtree sizes" begin
        @test subtree_size(a) == 7
        @test subtree_size(c, a) == 5
        @test subtree_size(c) == 5
        @test subtree_size(e) == 3
        @test subtree_size(f) == 1
    end
end