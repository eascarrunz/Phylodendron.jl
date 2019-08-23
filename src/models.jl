#=
`ModelPlugin`s are objects associated to trees (`TreeModelPlugin`), nodes (`NodeModelPlugin`), and branches (`BranchModelPlugin`) that hold values of statistical models. Specific models can be implemented by creating concrete subtypes of the `TreeModelPlugin`, `NodeModelPlugin`, and `BranchModelPlugin` abstract types.

`ModelPlugin` objects are meant to be implemented as a simple hierarchy, where `TreeModelPlugin` is the master object associated to a unique `NodeModelPlugin` object and a `BranchModelPlugin` object in each node and branch of the tree. `Tree`, `Node`, and `Branch` objects contain a `models` field that is a vector of their corresponding model plugin type. `NodeModelPlugin` and `BranchModelPlugin` objects must have the same index within that vector as their corresponding `TreeModelPlugin` in the `Tree` object. 

Model implementations must follow the following rules:

1. Concrete subtypes of `NodeModelPlugin` and `BranchModelPlugin` must contain a `treemodel` field to link to their corresponding `TreeModelPlugin` object.

2. `init_model!` methods must be implemented to construct and initalise `NodeModelPlugin` and `BranchModelPlugin` objects.

3. The `init_model!` methods must have a signature of the following form:

    init_model!(::<Node|Branch>, ::<TreeModelPlugin subtype>; <keyword args>)
=#

abstract type ModelPlugin end
abstract type TreeModelPlugin <: ModelPlugin end
abstract type NodeModelPlugin <: ModelPlugin end
abstract type BranchModelPlugin <: ModelPlugin end

function Base.show(io::IO, m::ModelPlugin)
    print(io, typeof(m))

    return nothing
end



# """
#     remove_model!(t::Tree, i)

# Remove model the model with index `i` from tree `t`.

# The indices of models higher than `i` will be shifted one place.
# """
# function remove_model!(t::Tree, i)
#     trav = PreorderTraverser(t)
#     p = next!(trav)
#     deleteat!(p.models, i)
#     while ! isfinished(trav)
#         p, q = next!(trav)
#         deleteat!(p.models, i)
#         deleteat!(getbranch(q, p).models, i)
#     end
#     deleteat!(t.models, i)

#     return nothing
# end