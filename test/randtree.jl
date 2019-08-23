@testset "Tree 1, unrooted 128 tips" begin
    n = 5
    tree = randtree(n)
    nodes = preorder(tree.origin)

    @test length(nodes) == 2*n - 2
    monolink = 0
    trilink = 0
        
    for p in nodes
        n_neighbours_p = n_neighbours(p)
        monolink += n_neighbours_p == 1 ? 1 : 0
        trilink += n_neighbours_p == 3 ? 1 : 0
    end

    @test monolink == n
    @test trilink == n - 2
end

@testset "Tree 2, rooted 128 tips" begin
    n = 5
    tree = randtree(n, true)
    nodes = preorder(tree.origin)

    @test n_neighbours(tree.origin) == 2
    @test length(nodes) == 2*n - 1
    monolink = 0
    trilink = 0
        
    for p in nodes
        n_neighbours_p = n_neighbours(p)
        monolink += n_neighbours_p == 1 ? 1 : 0
        trilink += n_neighbours_p == 3 ? 1 : 0
    end

    @test monolink == n
    @test trilink == n - 2
end