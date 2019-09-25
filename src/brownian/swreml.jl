#=
This is a straight-forward implementation of Felsenstein's (1981) model and algorithms for indepentent continuous characters under Brownian motion.
=#

#=
TODO: Fuse vectorised operations throughout.
=#

const LOG2π = log(2π)
const INIT_V = 1.0          # Initialisation value for `v` parameters
#=
The current `INIT_V` value is arbitrary. Instead of a constant, maybe it's possible to compute better initialisation values based on the `x` values of neighbours, but I have not explored this. Such values would only be beneficial insofar they are faster to compute than the `v` optimisation cycles that they would save.
=#

mutable struct SitewiseRELBrownianTree <: TreeModelPlugin
    partnumber::Int
    n_chars::Int
    weight::Int
    llh::Vector{Float64}
end

mutable struct SitewiseRELBrownianNode <: NodeModelPlugin
    treemodel::SitewiseRELBrownianTree
    xprune::Vector{Float64}
    llh::Vector{Float64}
end

mutable struct SitewiseRELBrownianBranch <: BranchModelPlugin
    treemodel::SitewiseRELBrownianTree
    v::Vector{Float64}
    vprune::Vector{Float64}
    δv::Vector{Float64}
end

"""
Add a restricted likelihood Brownian motion model to the tree, link it to partition `i`, and initialise all its node and branch values, if it has them. Returns the index of model in the tree's model vector.
"""
function add_sitewise_rel_brownian_model!(t::Tree, i::Int = 1, n_chars::Int = 1; usebrlength::Bool=true)
    m = SitewiseRELBrownianTree(i, n_chars, 1, fill(NaN, n_chars))
    push!(t.models, m)
    trav = PreorderTraverser(t.origin, false)
    while ! isfinished(trav)
        p, q = nextpair!(trav)
        init_model!(p, m)
        p ≠ q && init_model!(getbranch(p, q), m, usebrlength=usebrlength)
    end
    
    return length(t.models)
end

"""
Initialise the parameters of the restricted likelihood Brownian model `m` for node `p`
"""
function init_model!(p::Node, m::SitewiseRELBrownianTree)
    xprune = hasdata(p) ? p.dataviews[m.partnumber] : fill(NaN, m.n_chars)
    node_plug = SitewiseRELBrownianNode(m, xprune, fill(NaN, m.n_chars))
    push!(p.models, node_plug) 

    return nothing
end

"""
Initialise the parameters of the restricted likelihood Brownian model `m` for node `p`
"""
function init_model!(br::Branch, m::SitewiseRELBrownianTree; usebrlength::Bool=true)
    n_chars = m.n_chars
    init_v = usebrlength ? fill(br.length, n_chars) : fill(INIT_V, n_chars)
    branch_plug = SitewiseRELBrownianBranch(m, init_v, init_v, zeros(n_chars))
    push!(br.models, branch_plug)

    return nothing
end

function sitewise_rel_brownian_prune!(p::Node, q::Node, i::Int, calc_llh::Bool=false)::Nothing
    if istip(p)
        getbranch(q, p).models[i].vprune = getbranch(q, p).models[i].v
        return nothing
    end
    childrenₚ = filter(x -> x ≠ q, neighbours(p))
    @assert length(childrenₚ) == 2 "This function requires a bifurcating node."
    child₁, child₂ = childrenₚ

    br₁ = getbranch(p, child₁)
    br₂ = getbranch(p, child₂)
    brₚ = getbranch(p, q)

    x₁= child₁.models[i].xprune
    v₁ = br₁.models[i].vprune
    x₂= child₂.models[i].xprune
    v₂ = br₂.models[i].vprune
    Σv = v₁ .+ v₂

    # Following Felsenstein (1981), Eqn. 12:
    @. p.models[i].xprune = (x₁ * v₂ + x₂ * v₁) / Σv

    # Following Felsenstein (1981), Eqn. 13:
    @. brₚ.models[i].δv = v₁ * v₂ / Σv
    @. brₚ.models[i].vprune = brₚ.models[i].v + brₚ.models[i].δv

    if calc_llh
        k = p.models[i].treemodel.n_chars
        p.models[i].llh = sitewise_llh_brownian_2c(x₁, x₂, v₁, v₂, k)
    end
    
    return nothing
end

"""
Compute the restricted log-likelihood from the parameters of a pruned node with two children.
"""
function sitewise_llh_brownian_2c(
    x₁::Vector{Float64}, x₂::Vector{Float64}, # Pruned character values
    v₁::Vector{Float64}, v₂::Vector{Float64}, # Pruned branch lengths
    k::Int                    # Number of characters
    )::Vector{Float64}
    # Following Felsenstein (1981), Eqn. 9:
    return @. -0.5 * ((log(v₁ + v₂) + LOG2π) + ((x₁- x₂)^2) / (v₁ + v₂))
    # return -0.5 * ( log(Σv) + sum((x₁.- x₂).^2) / Σv)
end

"""
Compute the restricted log-likelihood from the parameters of a pruned node with three children.
"""
function sitewise_llh_brownian_3c(
    x₁::Vector{Float64}, x₂::Vector{Float64}, x₃::Vector{Float64}, # Pruned character values
    v₁::Vector{Float64}, v₂::Vector{Float64}, v₃::Vector{Float64}, # Pruned branch lengths
    k::Int                                 # Number of characters
    )::Vector{Float64}
    # Following Felsenstein (1981, Eqn. A1-1)
    Σv₁₂ = @. v₁ + v₂
    llh = @. log(Σv₁₂)
    @. llh += ((x₁- x₂)^2) / Σv₁₂
    @. llh += log(v₃ + v₁ * v₂ / Σv₁₂)

    part1 = @. (x₃ - (v₂ * x₁ + v₁ * x₂) / Σv₁₂)
    part2 = @. v₃ + v₁ * v₂ / Σv₁₂
    @. llh += (part1^2) / part2
    @. llh *= -0.5
    @. llh -= LOG2π

    return llh
end 

function sitewise_rel_brownian_prune!(p::Node, i::Int, calc_llh::Bool=false)::Nothing
    k = p.models[i].treemodel.n_chars 
    llh = calc_llh ? zeros(k) : fill(NaN, k)

    trav = PostorderTraverser(p)
    @inbounds while ! isfinished(trav)    # Prune the origin outside this loop
        q, r = nextpair!(trav)
        q == p && break
        sitewise_rel_brownian_prune!(q, r, i, calc_llh)
        istip(q) && continue
        @. llh += calc_llh ? q.models[i].llh : 0.0
    end

    if calc_llh
        childrenₚ = neighbours(p)
        if length(childrenₚ) == 3
            child₁, child₂, child₃ = childrenₚ

            br₁ = getbranch(p, child₁)
            br₂ = getbranch(p, child₂)
            br₃ = getbranch(p, child₃)
            
            x₁= child₁.models[i].xprune
            v₁ = br₁.models[i].vprune
            x₂= child₂.models[i].xprune
            v₂ = br₂.models[i].vprune
            x₃= child₃.models[i].xprune
            v₃ = br₃.models[i].vprune
            
            p.models[i].llh = sitewise_llh_brownian_3c(x₁, x₂, x₃, v₁, v₂, v₃, k)
            @. p.models[i].treemodel.llh = llh + p.models[i].llh
        elseif length(childrenₚ) == 2
            child₁, child₂ = childrenₚ

            br₁ = getbranch(p, child₁)
            br₂ = getbranch(p, child₂)
            
            x₁= child₁.models[i].xprune
            v₁ = br₁.models[i].vprune
            x₂= child₂.models[i].xprune
            v₂ = br₂.models[i].vprune
            
            p.models[i].llh = sitewise_llh_brownian_2c(x₁, x₂, v₁, v₂, k)
            @. p.models[i].treemodel.llh = llh + p.models[i].llh
        end
    end

    return nothing
end

function optimise_sitewise_brownian_v_3c!(p::Node, i::Int)
    childrenₚ = neighbours(p)
    @assert length(childrenₚ) == 3
        "This function requires an internal node of degree 3."
    child₁, child₂, child₃ = childrenₚ

    br₁ = getbranch(p, child₁)
    br₂ = getbranch(p, child₂)
    br₃ = getbranch(p, child₃)
    
    x₁= child₁.models[i].xprune
    x₂= child₂.models[i].xprune
    x₃= child₃.models[i].xprune

    k = p.models[1].treemodel.n_chars

    kv̂₃ = @. (x₃ - x₁) * (x₃ - x₂)
    kv̂₁ = @. (x₁ - x₂) * (x₁ - x₃)
    kv̂₂ = @. (x₂ - x₁) * (x₂ - x₃)

    inds_negkv̂₁ = findall(x -> x < 0.0, kv̂₁)
    inds_negkv̂₂ = findall(x -> x < 0.0, kv̂₂)
    inds_negkv̂₃ = findall(x -> x < 0.0, kv̂₃)

    # if kv̂₁ < 0.0
        kv̂₁[inds_negkv̂₁] .= 0.0
        kv̂₂[inds_negkv̂₁] = @. (x₁[inds_negkv̂₁] - x₂[inds_negkv̂₁])^2
        kv̂₃[inds_negkv̂₁] = @. (x₁[inds_negkv̂₁] - x₃[inds_negkv̂₁])^2
    # elseif kv̂₂ < 0.0
        kv̂₁[inds_negkv̂₂] = @. (x₂[inds_negkv̂₂] - x₁[inds_negkv̂₂])^2
        kv̂₂[inds_negkv̂₂] .= 0.0
        kv̂₃[inds_negkv̂₂] = @. (x₂[inds_negkv̂₂] - x₃[inds_negkv̂₂])^2
    # elseif kv̂₃ < 0.0
        kv̂₁[inds_negkv̂₃] = @. (x₃[inds_negkv̂₃] - x₁[inds_negkv̂₃])^2
        kv̂₂[inds_negkv̂₃] = @. (x₃[inds_negkv̂₃] - x₂[inds_negkv̂₃])^2
        kv̂₃[inds_negkv̂₃] .= 0.0
    # end

    br₁.models[i].vprune = @. kv̂₁ / k
    br₂.models[i].vprune = @. kv̂₂ / k
    br₃.models[i].vprune = @. kv̂₃ / k
  
    map!((x, y) -> x > y ? x : y, br₁.models[i].vprune, br₁.models[i].vprune, br₁.models[i].δv)
    map!((x, y) -> x > y ? x : y, br₂.models[i].vprune, br₂.models[i].vprune, br₂.models[i].δv)
    map!((x, y) -> x > y ? x : y, br₃.models[i].vprune, br₃.models[i].vprune, br₃.models[i].δv)

    br₁.models[i].v = @. br₁.models[i].vprune - br₁.models[i].δv
    br₂.models[i].v = @. br₂.models[i].vprune - br₂.models[i].δv
    br₃.models[i].v = @. br₃.models[i].vprune - br₃.models[i].δv
    
    return nothing
end

"""
Optimise v in a tree
"""
function optimise_sitewise_v!(t::Tree, i::Int; niter = 5)
    @assert t.models[i] isa SitewiseRELBrownianTree
    @inbounds for _ in 1:niter
        trav = PreorderTraverser(t)
        old_p = next!(trav)
        while istip(old_p)
            old_p = next!(trav)
        end    
        sitewise_rel_brownian_prune!(old_p, i)
        optimise_sitewise_brownian_v_3c!(old_p, i)
        @inbounds while ! isfinished(trav)
            p = next!(trav)
            istip(p) && continue
            #=
            The following loop works as a shortcut. Instead of prunning the entire tree anew, it only prunes the neighbours of the nodes along the path between the current node (`p`) and the node from the previous iteration (`old_p`) (Felsenstein 1981, p. 1238).

            Finding the path between the two nodes is itself relatively costly, so this is likely only an improvement in big trees.
            =#
            for q ∈ [node_path(old_p, p)... p]
                childrenq = neighbours(q)
                @assert length(childrenq) == 3 "This function requires an internal node of degree 3."
                child₁, child₂, child₃ = childrenq
                sitewise_rel_brownian_prune!(child₁, q, i)
                sitewise_rel_brownian_prune!(child₂, q, i)
                sitewise_rel_brownian_prune!(child₃, q, i)
            end
            optimise_sitewise_brownian_v_3c!(p, i)
            old_p = p
        end
    end

    return nothing
end


"""
    calc_llh(t::Tree, i::Int)

Calculate the log-likelihood of tree `t` under model `i`.

This assumes that the tree has already been pruned.
"""
function calc_sitewise_llh!(t::Tree, i::Int)::Vector{Float64}
    @assert t.models[i] isa SitewiseRELBrownianTree
    sitewise_rel_brownian_prune!(t.origin, i, true)
    return t.models[i].llh
end


"""
    phylip_llh(m::SitewiseRELBrownianTree)

Return the log-likelihood of the model `m` as computed by Phylip.

Phylip computes log-likelihoods of trees differently because it ommits a constant term from the likelihoods of every node. The term is (n - 1)/2 * ln(2π), where k is the number of characters and n the number of tips.
"""
phylip_sitewise_llh(t::Tree, model::SitewiseRELBrownianTree)::Vector{Float64} =
    @. model.llh + (t.n_tips - 1) / 2 * model.n_chars * LOG2π


