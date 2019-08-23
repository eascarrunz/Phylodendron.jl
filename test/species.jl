@testset "Constructor with auto species" begin
    sppdir = SpeciesDirectory(5)

    @testset "Check directory objects" begin
        @test sppdir.list == ["sp1", "sp2", "sp3", "sp4", "sp5"]
        @test sppdir.dict["sp1"] == 1
        @test sppdir.dict["sp2"] == 2
        @test sppdir.dict["sp3"] == 3
        @test sppdir.dict["sp4"] == 4
        @test sppdir.dict["sp5"] == 5
    end
    add!(sppdir, "sp6")
    add!(sppdir, "")
    add!(sppdir)
    add!(sppdir, ["sp9", "sp10"])
    @testset "Add new species" begin
        @test length(sppdir.list) == 10
        @test sppdir.list[6] == "sp6"
        @test sppdir.list[7] == ""
        @test sppdir.list[8] == ""
        @test sppdir.list[9] == "sp9"
        @test sppdir.list[10] == "sp10"
        @test_throws Phylodendron.NonUniqueName add!(sppdir, "sp6")
        @test_throws Phylodendron.NonUniqueName add!(sppdir, ["sp9", "sp10"])
    end
    @testset "Checks, indexes, and names" begin
        @test 3 ∈ sppdir
        @test 12 ∉ sppdir
        @test sppdir["sp1"] == 1
        @test sppdir["sp6"] == 6
        @test sppdir["sp1", "sp6"] == [1, 6]
        @test sppdir[["sp1", "sp6"]] == [1, 6]
        @test sppdir[""] == [7, 8]
        @test sppdir["sp1", ""] == [1, [7, 8]]
        @test sppdir["foobar"] == 0
        @test name(sppdir, 5) == "sp5"
        @test name(sppdir, 7) == ""
        @test name(sppdir, 1, 3) == ["sp1", "sp3"]
        @test name(sppdir, 1:3) == ["sp1", "sp2", "sp3"]
        @test name(sppdir, [2, 1, 3]) == ["sp2", "sp1", "sp3"]
        @test name(sppdir) == 
            ["sp1","sp2", "sp3", "sp4", "sp5", "sp6", "", "", "sp9", "sp10"]
        @test_throws Phylodendron.MissingEntry name(sppdir, 12)
        @test_throws Phylodendron.NonUniqueName name!(sppdir, "sp1", 4)
        name!(sppdir, "foo", 4)
        name!(sppdir, "sp7", 7)
        @test name(sppdir, 4) == "foo"
        @test name(sppdir, 7) == "sp7"
    end
end

@testset "Empty directory constructor" begin
    dir = SpeciesDirectory(;nhint=5)

    @test length(dir) == 0
    add!(dir, "foo")
    @test length(dir) == 1
end

