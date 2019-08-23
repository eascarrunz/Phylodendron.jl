mutable struct Branch
    length::Float64
    label::AbstractString
    extras::Dict{Symbol,Any}
    models::Vector{BranchModelPlugin}

    Branch() = new(NaN, "", Dict{Symbol,Any}(), BranchModelPlugin[])
end

function Branch(v::Float64)
    br = Branch()
    br.length = v
    
    return br
end