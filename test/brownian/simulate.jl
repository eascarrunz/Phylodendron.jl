snouter_tree = read_newick("../data/snouters.nwk")[1]
root!(snouter_tree)

create_species!(snouter_tree)

@testset "Simulate Brownian Motion" begin
    x₀ = [1.0, 12.0, 3.4, 2.0, 12.0]
    σ² = [1.0, 2.0, 10.0, 100.0, 0.0]

    dm = simulate_bm(snouter_tree)
    @test dm isa SpeciesDataMatrix{Float64}
    @test size(dm) == (snouter_tree.n_species, 1)

    dm = simulate_bm(snouter_tree, 12)
    @test dm isa SpeciesDataMatrix{Float64}
    @test size(dm) == (snouter_tree.n_species, 12)

    dm = simulate_bm(snouter_tree; allnodes=true)
    @test dm isa Matrix{Float64}
    @test size(dm) == (snouter_tree.n_nodes, 1)

    dm = simulate_bm(snouter_tree, σ²=3.0)
    @test dm isa SpeciesDataMatrix{Float64}
    @test size(dm) == (snouter_tree.n_species, 1)

    dm = simulate_bm(snouter_tree, σ²=3.0, x₀=x₀)
    @test dm isa SpeciesDataMatrix{Float64}
    @test size(dm) == (snouter_tree.n_species, 5)

    dm = simulate_bm(snouter_tree, σ²=σ²)
    @test dm isa SpeciesDataMatrix{Float64}
    @test size(dm) == (snouter_tree.n_species, 5)
    @test dm[:,5] == zeros(10)

    dm = simulate_bm(snouter_tree, σ²=σ², allnodes=true)
    @test dm isa Matrix{Float64}
    @test size(dm) == (snouter_tree.n_nodes, 5)
    @test dm[:, 5] == zeros(snouter_tree.n_nodes)
    
    dm = simulate_bm(snouter_tree, x₀=x₀)
    @test dm isa SpeciesDataMatrix{Float64}
    @test size(dm) == (snouter_tree.n_species, 5)

    dm = simulate_bm(snouter_tree, x₀=x₀, σ²=σ²)
    @test dm isa SpeciesDataMatrix{Float64}
    @test size(dm) == (snouter_tree.n_species, 5)
end
