@testset "Find species in a tree" begin
	t = read_newick("../data/snouters.nwk")[1]

	@test_throws Phylodendron.MissingSpeciesDirectory findspecies(2, t)

	t.dir = SpeciesDirectory(t)
	map_species!(t)

	x = findspecies(2, t)
	@test x.species == 2
	@test x.label == "Otopteryx"

	x = findspecies("Stella", t)
	@test x.species == 5
	@test x.label == "Stella"

	x = findspecies(8, t)
	@test x.species == 8
	@test x.label == "Eldenopsis"

	x.species = 0

	@test findspecies(8, t) == nothing

	@test_throws Phylodendron.MissingEntry findspecies(12, t)

	@test_throws Phylodendron.MissingEntry findspecies("Nebuchadnezzar", t)
end