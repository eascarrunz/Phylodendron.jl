using Phylodendron, Test

# Log-likelihoods computed with CONTML v.3.697
const PHYLIP_LLH10_FIXEDV = [-312.15623, -325.60200, -398.92051, -402.39157,  -349.98059, -360.64568, -337.82326, -333.82258, -400.47962, -355.65602,  -355.84234, -424.58151, -515.78724, -293.74049, -339.84624, -381.18391,  -379.47811, -376.40088, -393.54261, -388.27998]

const PHYLIP_LLH10_OPTIMV = [-305.50324, -314.05864, -390.75273, -392.25834, -343.83104, -350.54099, -331.28116, -328.90663, -394.83418, -348.31738, -345.37985, -415.79769, -511.84351, -287.28517, -324.36885, -371.87104, -372.21548, -370.83349, -384.88450, -373.86180]

const PHYLIP_LLH100_FIXEDV = [-44809.16973, -40499.44717, -41319.73037, -44542.89087, -42338.81107, -40776.87186, -41931.32389, -42835.18100, -39880.52898, -42623.71041, -41372.73617, -40651.48608, -41135.45014, -45395.92431, -39853.66646, -42778.15140, -42239.04861, -42363.34038, -41493.78189, -42643.56128];
const PHYLIP_LLH100_OPTIMV = [-44713.38100, NaN, NaN, NaN, -44591.60639, -44017.60804, -41853.19162, -42738.49130, -39781.59299, NaN, -41032.71300, NaN, -41109.82521, -45840.89653, -41129.41272, NaN, NaN, NaN, NaN, NaN];

@testset "10 tips" begin
    for i ∈ 1:20
        finfix = string(i, pad=2)
        dm = read_species_data("data/generated/dm10_"*finfix*".txt", Float64);
        t = read_newick("data/generated/t10_"*finfix*".nwk")[1]
        t.dir = dm.dir
        map_species!(t)
        map_data!(t, dm)
        add_rel_brownian_model!(t, 1, 50; usebrlength=true)
        llh_fixedv = calc_llh!(t, 1)

        @test ≈(phylip_llh(t, t.models[1]), PHYLIP_LLH10_FIXEDV[i], rtol=1e-5)
        collapse_nonsplitting!(t, skiporigin=false)
        patch_models(t.origin)
        @test calc_llh!(t, 1) ≈ llh_fixedv

        add_rel_brownian_model!(t, 1, 50; usebrlength=false)
        optimise_v!(t, 2, niter=4)
        llh_optimv = calc_llh!(t, 2)
        @test llh_optimv ≥ llh_fixedv
        if ! isnan(PHYLIP_LLH100_OPTIMV[i])
            # @test ≈(phylip_llh(t, t.models[2]), PHYLIP_LLH10_OPTIMV[i], rtol=1e-5)
            println(llh_fixedv, ", ", llh_optimv, " ", phylip_llh(t, t.models[2]), " ", PHYLIP_LLH10_OPTIMV[i])
            println(any(map(x->x.models[2].v < 0.0, branches(t))))
        end
    end
end


# dm = read_species_data("data/generated/dm1000_01.txt", Float64);
# t = read_newick("data/generated/t1000_01.nwk")[1]
# collapse_nonsplitting!(t, skiporigin=false)
# t.dir = dm.dir
# map_species!(t)
# map_data!(t, dm)

# trialε = [exp10.(0:-1:-16)..., 0]
# llh = Vector{Float64}(undef, 18)

# for i in 1:18
#     add_rel_brownian_model!(t, 1, 5000; usebrlength=false)
#     optimise_v!(t, 1, niter=5, ε=trialε[i])
#     llh[i] = calc_llh!(t, i)
# end

# push!(llh, calc_llh!(t, 18))

# add_rel_brownian_model!(t, 1, 5000; usebrlength=true)
# calc_llh!(t, 18)


# add_rel_brownian_model!(t, 1, 5000; usebrlength=false)
# calc_llh!(t, 1)

# patch_models(t.origin)
# calc_llh!(t, 1)
# optimise_v!(t, 1, niter=4)
# calc_llh!(t, 1)

# @testset "10 species" begin
#     dm10files = "data/generated/dm10_".*string.(1:20, pad=2).*".txt"
#     t10 = read_newick("data/generated/t10.nwk")
#     phylip_llh_tree_lengths = [-312.15623, -325.60200]
#     for i in 1:20
#         dm = read_species_data(dm10files[i], Float64)
#         t = t10[i]
#         t.dir = dm.dir
#         map_species!(t)
#         map_data!(t, dm)
#         @testset "Use tree lengths" begin
#             add_rel_brownian_model!(t, 1, 50, usebrlength=true)

#         end
#     end
# end