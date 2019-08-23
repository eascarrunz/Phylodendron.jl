"""
    extra(obj::Union{Node,Branch,Tree}, key::Symbol)::Any

Return the key matching arugment `key` if one exists in the "extras" dictionary of the object `obj`.

Throws an error if the key is not found in the dictionary.
"""
extra(obj::Union{Node,Branch,Tree}, key::Symbol)::Any = obj.extras[key]

"""
    getextra(obj::Union{Node,Branch,Tree}, key::Symbol, default::Any)::Any

Return the key matching arugment `key` if one exists in the dictionary of the object `obj`, otherwise return `default`.
"""
function getextra(obj::Union{Node,Branch,Tree}, key::Symbol, default::Any)
    return try obj[key] catch default end
end

"""
    extra!(obj::Union{Node,Branch,Tree}, key::Symbol, v::Any)::Nothing

Set the value `v` for the key `key` in the "extras" dictionary of `obj`.
"""
function extra!(obj::Union{Node,Branch,Tree}, key::Symbol, v::Any)::Nothing
    obj[key] = v

    return nothing
end