struct Link{T}
    node::T
    branch::Branch
end

function Base.show(io::IO, link::Link)
    print(io, "Link to ", link.node)
end