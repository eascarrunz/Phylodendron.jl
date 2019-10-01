"""
    patch_models!(p::Node; branches=true, neighbours=true, nodeargs, brargs)

Inspect the neighbours and branches of node `p` and initialise in them the same models assigned to `p`, when necessary.

Useful after topological manipulations that created new nodes or branches in the tree. Neighbours and branches can be skipped if unnecessary. `nodeargs` and `brargs` are optional named tuples that are passed on as keyword arguments to the model plugin initialisers of nodes and branches, respectively.
"""
function patch_models!(
    p::Node; 
    skipbranches::Bool=false, 
    skipneighbours::Bool=false, 
    nodeargs::NamedTuple=NamedTuple(),
    brargs::NamedTuple=NamedTuple()
    )::Nothing
    for q in neighbours(p)
        for m in p.models
            if ! skipneighbours
                length(q.models) > 0 || init_model!(q, m.treemodel; nodeargs...)
            end
            if ! skipbranches
                br = getbranch(p, q)
                length(br.models) > 0 || init_model!(br, m.treemodel; brargs...)
            end
        end
    end

    return nothing
end