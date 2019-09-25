using DelimitedFiles

list = readdlm("../data/list.txt"; header=true)[1]
i = 1
#=
Table in which each row contains a tree file name, a data matrix file name, the log-likelihood with the branch lengths fixed, and the log-likelihood with the optimised branch lengths.

The log-likelihoods were computed with CONTML v.3.697
=#

@testset "Sitewise likelihoods" begin
    for i ∈ 1:20
        ft, fdm = list[i, 1:2]
        dm = read_species_data("../data/generated/"*fdm, Float64);
        n, k = size(dm)
        t = read_newick("../data/generated/"*ft)[1]
        collapse_nonsplitting!(t; skiporigin=false)
        t.dir = dm.dir
        map_species!(t)
        
        partwise_llh = Vector{Float64}(undef, k);
        for j ∈ 1:k
            tmpm = reshape(dm[:, j], n, 1)
            tmpdm = SpeciesDataMatrix{Float64}(tmpm, dm.dir)
            map_data!(t, tmpdm)
			add_rel_brownian_model!(t, j, 1);
			optimise_v!(t, j);
            partwise_llh[j] = calc_llh!(t, j)
        end

        map_data!(t, dm)
        add_sitewise_rel_brownian_model!(t, k+1, k)
        optimise_sitewise_v!(t, k+1)
        sitewise_llh = calc_sitewise_llh!(t, k+1)

       @test partwise_llh == sitewise_llh
    end
end
