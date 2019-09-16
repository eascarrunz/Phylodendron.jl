function simulate_bm(t::Tree, k::Int; σ²::Float64=1.0, x₀::Float64=0.0, allnodes=false)
    simulate_bm(
        t;
        σ²=fill(σ², k),
        x₀=fill(x₀, k),
        allnodes=allnodes
        )
end

"""
    simulate_bm(t::Tree, k::Int, σ::Vector{Float64} = ones(k), x₀::Vector{Float64} = zeros(k); allnodes::Bool=false)

Simulate the evolution of continuous traits under univariate Brownian motion on a phylogenetic tree.

Creates a `SpeciesDataMatrix` with `k` independent traits, with `σ²` as the vector of diffusion coeffients of the traits (all 1.0 by default), and `x₀` as the vector of trait values at the root (all 0.0 by default).

If `allnodes` is set to `true`, it creates `Matrix` storing the simulated values of all the nodes in the tree. The order of the rows in that matrix corresponds to the preorder indices of the nodes of the tree.
"""
function simulate_bm(
    t::Tree;
    σ²::Union{Float64, Vector{Float64}} = 1.0,
    x₀::Union{Float64, Vector{Float64}} = 0.0,
    allnodes::Bool=false
    )
    ! t.rooted && @warn "The tree is unrooted. The simulation was done using the origin node as the root."

    if σ² isa Float64 && x₀ isa Float64
        σ² = [σ²]
        x₀ = [x₀]
    elseif σ² isa Float64 && x₀ isa Vector{Float64}
        σ² = fill(σ², length(x₀))
    elseif σ² isa Vector{Float64} && x₀ isa Float64
        x₀ = fill(x₀, length(σ²))
    elseif length(σ²) ≠ length(x₀)
        msg = "the vectors `σ²` and `x₀` must both have `k` number of elements."
        throw(ArgumentError(msg))
    end

    k = length(x₀)
    σ = .√(σ²)

    if allnodes
        return _simulate_bm_allnodes(t, k, σ, x₀)
    else
        return _simulate_bm_species(t, k, σ, x₀)
    end
end



function _simulate_bm_allnodes(t::Tree, k::Int, σ::Vector{Float64}, x₀::Vector{Float64})
    ! isdefined(t, :preorder) && throw(Phylodendron.MissingTreeInfo())
    x = randn(t.n_nodes, k)
    x[1, 1:k] .= x₀
    for (p, q) ∈ t.preorder[2:end] # skip the root
        x[p.idx, 1:k] .= x[q.idx, 1:k] .+ σ .* √(brlength(q, p)) .* x[p.idx, 1:k]
    end

    return x
end

function _simulate_bm_species(t::Tree, k::Int, σ::Vector{Float64}, x₀::Vector{Float64})::SpeciesDataMatrix{Float64}
    x = SpeciesDataMatrix{Float64}(t.dir, k)
    for p ∈ neighbours(t.origin)
        _simulate_bm!(x, p, t.origin, k, σ, x₀)
    end

    return x
end

function _simulate_bm!(
    x::SpeciesDataMatrix{Float64},
    p::Node,
    q::Node,
    k::Int,
    σ::Vector{Float64},
    x₀::Vector{Float64}
    )
    xₚ = x₀ .+ σ .* √(brlength(q, p)) .* randn(k)
    if p.species ∈ x.dir
        x[p.species,:] = xₚ
    end
    for r in neighbours(p)
        r == q && continue
        _simulate_bm!(x, r, p, k, σ, xₚ)
    end
end