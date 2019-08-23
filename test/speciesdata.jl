m = [01 02 03 04 05 06;
     19 20 21 22 23 24;
     07 08 09 10 11 12;
     13 14 15 16 17 18;
     25 26 27 28 29 30]

dir = SpeciesDirectory(5)

spp = ["sp1", "sp4", "sp2", "sp3", "sp5"]
dm = SpeciesDataMatrix{Int}(m, dir, spp)

@testset "SpeciesDataMatrix constructor" begin
    dm = SpeciesDataMatrix{Int}(m, dir, spp)
    m2 = [01 02 03 04 05 06;
          07 08 09 10 11 12;
          13 14 15 16 17 18;
          19 20 21 22 23 24;
          25 26 27 28 29 30]

    @test dm.data == m2

    add!(dir, "sp6")

    @test_throws ArgumentError SpeciesDataMatrix{Int}(m, dir)

    dm = SpeciesDataMatrix{Float64}(dir, 12)
    @test size(dm.data) == (6, 12)

    dm = SpeciesDataMatrix{Float64}(12.3, dir, 12)
    @test size(dm.data) == (6, 12)
    @test dm.data[3, 3] == 12.3
end

m = [01 02 03 04 05 06;
     19 20 21 22 23 24;
     07 08 09 10 11 12;
     13 14 15 16 17 18;
     25 26 27 28 29 30]

dir = SpeciesDirectory(5)

spp = ["sp1", "sp4", "sp2", "sp3", "sp5"]
dm = SpeciesDataMatrix{Int}(m, dir, spp)

@testset "getindex and setindex!" begin
    @test size(dm) == (5, 6)
    @test firstindex(dm) == 1
    @test firstindex(dm, 1) == 1
    @test lastindex(dm) == 30
    @test lastindex(dm, 2) == 6
    @test dm[3, 5] == 17
    @test dm["sp4"] == [19, 20, 21, 22, 23, 24]
    @test dm[["sp1", "sp2"]] == [01 02 03 04 05 06;
        07 08 09 10 11 12]
    @test dm[["sp1", "sp2"], 1:3] == [01 02 03;
        07 08 09]
    @test dm["sp4", 3] == 21
    @test dm["sp4", 2:end] == [20, 21, 22, 23, 24]
    dm["sp2"] = [0, 0, 0, 0, 0, 0]
    @test dm["sp2"] == [0, 0, 0, 0, 0, 0]
    dm[1, 4] = 0
    @test dm[1, 4] == 0
    dm["sp4", 1:3] = [0, 0, 0]
    @test dm["sp4", 1:3] == [0, 0, 0]
    dm[["sp4", "sp5"], 1:3] = [33 33 33; 11 11 11]
    @test dm[["sp4", "sp5"], 1:3] == [33 33 33; 11 11 11]
    dm["sp5"] = [2, 2, 2, 2, 2, 2]
    @test dm["sp5"] == [2, 2, 2, 2, 2, 2]
end

@testset "I/O" begin
    write("tmp.txt", dm)

    dm2 = read_species_data("tmp.txt", Int)

    @test dm.dir.list == dm2.dir.list
    @test dm.data == dm2.data

    dm3 = read_species_data("tmp.txt", Int, dir)
    @test dm.dir.dict == dm3.dir.dict

    rm("tmp.txt")
end
