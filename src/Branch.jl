mutable struct Branch
    length::Float64
    label::AbstractString
    models::Vector{BranchModelPlugin}
    bipart::Bipartition

    Branch() = new(NaN, "", BranchModelPlugin[])
end

function Branch(v::Float64)
    br = Branch()
    br.length = v
    
    return br
end