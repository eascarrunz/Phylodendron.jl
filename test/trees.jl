include("trees/tree1.jl")
tr = Tree(b)

@testset "Tree initialisation" begin
    @test tr.origin == b
    @test ! tr.rooted
    @test tr.label == ""
    @test tr.autoupdate
    @test tr.n_tips == 10
    @test tr.n_nodes == 20
    @test tr.n_species == 0
    @test tr.preorder == [(b,b),(a,b),(c,b),(d,c),(e,d),(f,e),(g,f),(h,f),(i,e),(j,i),(k,j),(l,i),(m,i),(n,c),(o,n),(p,o),(q,o),(r,n),(s,r),(t,r)]
    @test isempty(tr.models)
end

#== Add a few species ==#

spp = ["A", "G", "H", "I", "K", "L", "M", "P", "Q", "S", "T"]
dir = SpeciesDirectory(spp)
tr.dir = dir
for (foo, bar) ∈ tr.preorder
    matchlabel!(foo, dir)
end


@testset "Mapping species" begin
    @test a.species == 1
    @test b.species == 0
    @test g.species == 2
    @test h.species == 3
    @test i.species == 4  # Internal node
    @test k.species == 5
    @test l.species == 6
end

#= Remove the subtree (S,T)R =#

unlink!(n, r)

@testset "Updating" begin
    @test tr.n_species == 0
    @test tr.n_tips == 10
    @test tr.n_nodes == 20

    update!(tr)

    @test tr.n_tips == 8
    @test tr.n_nodes == 17
    @test tr.n_species == 9
    @test s ∉ tr.preorder
    @test t ∉ tr.preorder
    @test r ∉ tr.preorder
end

@testset "Rooting and unrooting" begin
    root!(k)  # Using the incorrect rooting function, does not update Tree.origin

    @test tr.origin == b
    @test ! tr.rooted

    update!(tr)

    @test tr.origin == k
    @test tr.rooted

    root!(tr, h) # Using the correct rooting function

    @test tr.origin == h
    @test tr.rooted

    unroot!(tr)

    @test tr.origin == h
    @test ! tr.rooted
end

include("trees/tree1.jl")
@testset "Species creation and mapping" begin
    dir = SpeciesDirectory(tree)
    @test dir.list == ["B", "A", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"]

    map_species!(tree, dir)
    @test a.species == 2
    @test c.species == 3
    @test e.species == 5
    @test g.species == 7
    @test k.species == 11
    @test p.species == 16
    @test t.species == 20

    dir = SpeciesDirectory(tree; tipsonly=true)
    @test dir.list == ["A", "G", "H", "K", "L", "M", "P", "Q", "S", "T"]

    map_species!(tree, dir)
    @test a.species == 1
    @test c.species == 0
    @test e.species == 0
    @test g.species == 2
    @test k.species == 4
    @test p.species == 7
    @test t.species == 10

    create_species!(tree; tipsonly=false)
    @test tree.dir.list == ["B", "A", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"]
    @test a.species == 2
    @test c.species == 3
    @test e.species == 5
    @test g.species == 7
    @test k.species == 11
    @test p.species == 16
    @test t.species == 20

    create_species!(tree; tipsonly=true)
    @test tree.dir.list == ["A", "G", "H", "K", "L", "M", "P", "Q", "S", "T"]
    @test a.species == 1
    @test c.species == 0
    @test e.species == 0
    @test g.species == 2
    @test k.species == 4
    @test p.species == 7
    @test t.species == 10

    @test species(tree) == collect(1:10)
end

@testset "Get tips and labels" begin
    @test tips(tree) == [a, g, h, k, l, m, p, q, s, t]
    @test tiplabels(tree) == ["A", "G", "H", "K", "L", "M", "P", "Q", "S", "T"]
    @test nodelabels(tree) == ["B", "A", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"]
end

