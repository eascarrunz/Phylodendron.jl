using Phylodendron, Test
using DelimitedFiles

list = readdlm("../data/list.txt"; header=true)[1]
#=
Table in which each row contains a tree file name, a data matrix file name, the log-likelihood with the branch lengths fixed, and the log-likelihood with the optimised branch lengths.

The log-likelihoods were computed with CONTML v.3.697
=#

@testset "Reference likelihoods" begin
    for i ∈ 1:size(list, 1)
        ft, fdm, ref_llh_fixedv, ref_llh_optimv = list[i, :]
        dm = read_species_data("../data/generated/"*fdm, Float64);
        k = size(dm, 2)
        t = read_newick("../data/generated/"*ft)[1]
        t.dir = dm.dir
        map_species!(t)
        map_data!(t, dm)
        add_rel_brownian_model!(t, 1, k; usebrlength=true)
        llh_fixedv = calc_llh!(t, 1)

        @test ≈(phylip_llh(t, t.models[1]), ref_llh_fixedv, rtol=1e-5)
        collapse_nonsplitting!(t, skiporigin=false)
        patch_models!(t.origin)
        @test calc_llh!(t, 1) ≈ llh_fixedv

        add_rel_brownian_model!(t, 1, k; usebrlength=false)
        optimise_v!(t, 2, niter=4)
        llh_optimv = calc_llh!(t, 2)
        @test llh_optimv ≥ llh_fixedv
        if ! isnan(ref_llh_optimv)
            @test ≈(phylip_llh(t, t.models[2]), ref_llh_optimv, rtol=1)
        end
    end
end
