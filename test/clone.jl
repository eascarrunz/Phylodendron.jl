t = read_newick("../data/snouters.nwk")[1]

dm = read_species_data("../data/snouter_traits.txt", Float64)
t.dir = dm.dir

map_species!(t)
map_data!(t, dm)
compute_bipartitions!(t)

ct = clone(t)

@testset "Tree cloning" begin
	@test t ≢ ct
	@test newick_string(t) == newick_string(ct)
	@test t.origin ≢ ct.origin
	@test t.rooted == ct.rooted
	root!(t)
	@test t.rooted ≠ ct.rooted
	compute_bipartitions!(t)
	@test t.bipartitions ≢ ct.bipartitions
end
