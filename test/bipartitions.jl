include("trees/tree1.jl")
tree.origin = a
tree.dir = SpeciesDirectory(tree)
map_species!(tree)

v = BitArray([
0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
0 0 0 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0;
0 0 0 0 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0;
0 0 0 0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0;
0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0;
0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0;
0 0 0 0 0 0 0 0 1 1 1 1 1 0 0 0 0 0 0 0;
0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0;
0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0;
0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0;
0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0;
0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1;
0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0 0;
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0;
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0;
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1;
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0;
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
])

inds_trivial = [1, 6, 7, 10, 11, 12, 15, 16, 18, 19]

@testset "Bipartitions" begin
	compute_bipartitions!(tree)

	counter = 0::Int
	trav = PreorderTraverser(tree)
	while ! isfinished(trav)
		p, q = nextpair!(trav)
		p == q && continue
		counter += 1
		br = getbranch(p, q)
		@test br.bipart.v == v[counter, :]
		@test br.bipart ∈ tree.bipartitions
		@test isinformative(br.bipart)
		@test istrivial(br.bipart) == (counter ∈ inds_trivial)

		for bp in tree.bipartitions
			@test are_compatible(br.bipart, bp)
		end
	end
end
