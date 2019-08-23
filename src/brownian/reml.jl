#=
This is a striaghtforward implementation of Felsenstein's (1981) model and algorithms for indepentent continuous characters under Brownian motion.
=#

const LOG2π = log(2π)
const INIT_V = 1.0          # Initialisation value for `v` parameters
#=
The current `INIT_V` value is arbitrary. Instead of a constant, maybe it's possible to compute better initialisation values based on the `x` values of neighbours, but I have not explored this. Such values would only be beneficial insofar they are faster to compute than the `v` optimisation cycles that they would save.
=#

mutable struct RELBrownianTree <: TreeModelPlugin
    partnumber::Int
    n_chars::Int
    weight::Int
    llh::Float64
end

mutable struct RELBrownianNode <: NodeModelPlugin
    treemodel::RELBrownianTree
    xprune::Vector{Float64}
    llh::Float64
end

mutable struct RELBrownianBranch <: BranchModelPlugin
    treemodel::RELBrownianTree
    v::Float64
    vprune::Float64
    δv::Float64
end

"""
Add a restricted likelihood Brownian motion model to the tree, link it to partition `i`, and initialise all its node and branch values, if it has them. Returns the index of model in the tree's model vector.
"""
function add_rel_brownian_model!(t::Tree, i::Int = 1, n_chars::Int = 1; usebrlength::Bool=true)
    m = RELBrownianTree(i, n_chars, 1, NaN)
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
function init_model!(p::Node, m::RELBrownianTree)
    xprune = hasdata(p) ? p.dataviews[m.partnumber] : fill(NaN, m.n_chars)
    node_plug = RELBrownianNode(m, xprune, NaN)
    push!(p.models, node_plug) 

    return nothing
end

"""
Initialise the parameters of the restricted likelihood Brownian model `m` for node `p`
"""
function init_model!(br::Branch, m::RELBrownianTree; usebrlength::Bool=true)
    init_v = usebrlength ? br.length : INIT_V
    branch_plug = RELBrownianBranch(m, init_v, init_v, 0.0)
    push!(br.models, branch_plug)

    return nothing
end

function rel_brownian_prune!(p::Node, q::Node, i::Int, calc_llh::Bool=false)::Nothing
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
    Σv = v₁ + v₂

    # Following Felsenstein (1981), Eqn. 12:
    p.models[i].xprune .= (x₁ * v₂ .+ x₂ * v₁) / Σv

    # Following Felsenstein (1981), Eqn. 13:
    brₚ.models[i].δv = v₁ * v₂ / Σv
    brₚ.models[i].vprune = brₚ.models[i].v + brₚ.models[i].δv

    if calc_llh
        k = p.models[i].treemodel.n_chars
        p.models[i].llh = llh_brownian_2c(x₁, x₂, v₁, v₂, k)
    end
    
    return nothing
end

"""
Compute the restricted log-likelihood from the parameters of a pruned node with two children.
"""
function llh_brownian_2c(
    x₁::Vector{Float64}, x₂::Vector{Float64}, # Pruned character values
    v₁::Float64, v₂::Float64, # Pruned branch lengths
    k::Int                    # Number of characters
    )::Float64
    # Following Felsenstein (1981), Eqn. 9:
    return -0.5 * (k * (log(v₁ + v₂) + LOG2π) + sum((x₁.- x₂).^2) / (v₁ + v₂))
    # return -0.5 * (k * log(Σv) + sum((x₁.- x₂).^2) / Σv)
end

"""
Compute the restricted log-likelihood from the parameters of a pruned node with three children.
"""
function llh_brownian_3c(
    x₁::Vector{Float64}, x₂::Vector{Float64}, x₃::Vector{Float64}, # Pruned character values
    v₁::Float64, v₂::Float64, v₃::Float64, # Pruned branch lengths
    k::Int                                 # Number of characters
    )::Float64
    # Following Felsenstein (1981, Eqn. A1-1)
    Σv₁₂ = v₁ + v₂
    llh = k * log(Σv₁₂)
    llh += sum((x₁.- x₂).^2) / Σv₁₂
    llh += k * log(v₃ + v₁ * v₂ / Σv₁₂)

    part1 = (x₃ .- (v₂ .* x₁ + v₁ * x₂) ./ Σv₁₂)
    part2 = v₃ + v₁ * v₂ / Σv₁₂
    llh += sum(part1.^2) / part2
    llh *= -0.5
    llh -= k * LOG2π

    return llh
end 

function rel_brownian_prune!(p::Node, i::Int, calc_llh::Bool=false)::Nothing
    llh = calc_llh ? 0.0 : NaN

    trav = PostorderTraverser(p)
    while ! isfinished(trav)    # Prune the origin outside this loop
        q, r = nextpair!(trav)
        q == p && break
        rel_brownian_prune!(q, r, i, calc_llh)
        istip(q) && continue
        llh += calc_llh ? q.models[i].llh : 0.0
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

            k = p.models[i].treemodel.n_chars 
            
            p.models[i].llh = llh_brownian_3c(x₁, x₂, x₃, v₁, v₂, v₃, k)
            p.models[i].treemodel.llh = llh + p.models[i].llh
        elseif length(childrenₚ) == 2
            child₁, child₂ = childrenₚ

            br₁ = getbranch(p, child₁)
            br₂ = getbranch(p, child₂)
            
            x₁= child₁.models[i].xprune
            v₁ = br₁.models[i].vprune
            x₂= child₂.models[i].xprune
            v₂ = br₂.models[i].vprune

            k = p.models[i].treemodel.n_chars 
            
            p.models[i].llh = llh_brownian_2c(x₁, x₂, v₁, v₂, k)
            p.models[i].treemodel.llh = llh + p.models[i].llh
        end
    end

    return nothing
end

function optimise_brownian_v_3c!(p::Node, i::Int)
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

    kv̂₁ = sum((x₁ .- x₂) .* (x₁ .- x₃))
    kv̂₂ = sum((x₂ .- x₁) .* (x₂ .- x₃))
    kv̂₃ = sum((x₃ .- x₁) .* (x₃ .- x₂))

    if kv̂₁ < 0.0
        kv̂₁ = 0.0
        kv̂₂ = sum((x₁ .- x₂).^2)
        kv̂₃ = sum((x₁ .- x₃).^2)
    elseif kv̂₂ < 0.0
        kv̂₁ = sum((x₂ .- x₁).^2)
        kv̂₂ = 0.0
        kv̂₃ = sum((x₂ .- x₃).^2)
    elseif kv̂₃ < 0.0
        kv̂₁ = sum((x₃ .- x₁).^2)
        kv̂₂ = sum((x₃ .- x₂).^2)
        kv̂₃ = 0.0
    end

    br₁.models[i].vprune = kv̂₁ / k
    br₂.models[i].vprune = kv̂₂ / k
    br₃.models[i].vprune = kv̂₃ / k

    br₁.models[i].vprune = br₁.models[i].vprune > br₁.models[i].δv ? 
        br₁.models[i].vprune : br₁.models[i].δv
    br₂.models[i].vprune = br₂.models[i].vprune > br₂.models[i].δv ? 
        br₂.models[i].vprune : br₂.models[i].δv
    br₃.models[i].vprune = br₃.models[i].vprune > br₃.models[i].δv ? 
        br₃.models[i].vprune : br₃.models[i].δv

    br₁.models[i].v = br₁.models[i].vprune - br₁.models[i].δv
    br₂.models[i].v = br₂.models[i].vprune - br₂.models[i].δv
    br₃.models[i].v = br₃.models[i].vprune - br₃.models[i].δv
    
    return nothing
end

"""
Optimise v in a tree
"""
function optimise_v!(t::Tree, i::Int; niter = 5)
    @assert t.models[i] isa RELBrownianTree
    for foo in 1:niter
        trav = PreorderTraverser(t)
        old_p = next!(trav)
        while istip(old_p)
            old_p = next!(trav)
        end    
        rel_brownian_prune!(old_p, i)
        optimise_brownian_v_3c!(old_p, i)
        while ! isfinished(trav)
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
                rel_brownian_prune!(child₁, q, i)
                rel_brownian_prune!(child₂, q, i)
                rel_brownian_prune!(child₃, q, i)
            end
            optimise_brownian_v_3c!(p, i)
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
function calc_llh!(t::Tree, i::Int)::Float64
    @assert t.models[i] isa RELBrownianTree
    rel_brownian_prune!(t.origin, i, true)
    return t.models[i].llh
end


"""
    phylip_llh(m::RELBrownianTree)

Return the log-likelihood of the model `m` as computed by Phylip.

Phylip computes log-likelihoods of trees differently because it ommits a constant term from the likelihoods of every node. The term is (n - 1)/2 * k * ln(2π), where k is the number of characters and n the number of tips.
"""
phylip_llh(t::Tree, model::RELBrownianTree)::Float64 =
    model.llh + (t.n_tips - 1) / 2 * model.n_chars * LOG2π


