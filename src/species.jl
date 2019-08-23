"""
    SpeciesDirectory

A species directory serves to keep track of the names and identities of a set of species, which can be shared with other objects such as trees and data matrices.

Each species receives a unique index number of type `Int`, and optionally a name of type `String`.
"""
mutable struct SpeciesDirectory
    list::Vector{String}
    dict::Dict{String,Int}
    n::Int
end

"""
    SpeciesDirectory(;nhint=1000)

A species directory serves to keep track of the names and identities of a set of species, which can be shared with other objects such as trees and data matrices.

Each species receives a unique index number of type `Int`, and optionally a name of type `String`.

This constructor creates an empty `SpeciesDirectory` with preallocated space for `nhint` species (1000, by default). The `add!` method can be used to create new species in the directory.
"""
function SpeciesDirectory(;nhint=1000)
    list = Vector{Union{Nothing,String}}()
    dict = Dict{String,Int}()

    sizehint!(list, nhint)

    return SpeciesDirectory(list, dict, 0)
end

"""
    SpeciesDirectory(n::Int; autonames=true)

Create a species directory with `n` species.

When `autonames` is se to `true` (the default), species will be named "sp1", "sp2", "sp3", and so forth.
"""
function SpeciesDirectory(n::Int; autonames=true)
    list = autonames ? .*("sp", string.(1:n)) : fill("", n)
    dict = autonames ? Dict{String,Int}(zip(list,1:n)) : Dict{String,Int}()

    return SpeciesDirectory(list, dict, n)
end

"""
    SpeciesDirectory(names::Vector{String})

Create a `SpeciesDirectory` from the vector of unique `names`.
"""
function SpeciesDirectory(names::Vector{String})
    names = filter(x-> x ≠ "", names)
    allunique(names) || throw(NonUniqueName(String[]))
    n = length(names)
    dict = Dict{String, Int}(zip(names, 1:n))

    return SpeciesDirectory(names, dict, n)
end

function Base.show(io::IO, sppdir::SpeciesDirectory)
    n = length(sppdir)
    nshow = n < 10 ? n : 10
    println(io, "SpeciesDirectory with ", string(n), " entries:")
    for i ∈ 1:nshow
        printname = sppdir.list[i] == "" ?
            "(Unnamed)" : "\"" * sppdir.list[i] * "\""
        println(" ", string(i), ". ", printname)
    end
    nshow < n && println("⋮")

    return nothing
end

struct NonUniqueName <: Exception
    names::Vector{String}
end

function Base.showerror(io::IO, e::NonUniqueName)
    if length(e.names) == 0
        msg = "some of the names provided are not unique."
    elseif length(e.names) == 1
        msg = "the name " * e.name * " is already associated to another species."
    else
        msg = "the following names are already associated to other species: "
        for name ∈ e.names[1:end-1]
            msg *= name * ", "
        end
        msg *= e.names[end]
    end
    print(io, msg)
end

struct MissingEntry <: Exception
    msg::AbstractString
end

Base.showerror(io::IO, e::MissingEntry) = print(io, e.msg)

"""
    name(sppdir::SpeciesDirectory, i::Int)

Get the name of species with the index number `i` in the species directory `sppdir`.
"""
function name(sppdir::SpeciesDirectory, i::Int)::String
    if i ∉ sppdir
        if i > sppdir.n
            msg = "the entry for species number " * string(i) * " has not been created in this directory."
        else
            msg = "species number " * string(i) * " has been removed from this directory."
        end
        throw(MissingEntry(msg))
    end

    return sppdir.list[i]
end

name(sppdir::SpeciesDirectory) = sppdir.list

function name(sppdir::SpeciesDirectory, inds::Int...)
    return collect(map(x -> name(sppdir, x), inds))
end

function name(sppdir::SpeciesDirectory, inds::Vector{Int})
    return map(x -> name(sppdir, x), inds)
end

function name(sppdir::SpeciesDirectory, inds::AbstractRange{Int})
    return map(x -> name(sppdir, x), inds)
end

"""
    name!(sppdir::SpeciesDirectory, name::String, i::Int)

Make `str` the name of species with the index number `i` in the species directory `sppdir`.
"""
function name!(sppdir::SpeciesDirectory, str::String, i::Int)
    if i ∉ sppdir
        msg = "Species number " * string(i) * " has been removed from this directory."
        throw(MissingEntry(msg))
    end
    if haskey(sppdir.dict, str)
        throw(NonUniqueName([str]))
    end
    sppdir.list[i] = str
    sppdir.dict[str] = i

    return nothing
end

Base.length(sppdir) = sppdir.n

"""
    getindex(sppdir::SpeciesDirectory, str::String)

Get the index number of the species with the name `str` in the species directory `sppdir`.

If `str` is the zero-length string (`""`), return the indices of all the species that do not have a label. Return 0 for names that are not present in the directory.
"""
function Base.getindex(sppdir::SpeciesDirectory, str::String)
    if str == ""
        return setdiff(1:sppdir.n, values(sppdir.dict))
    else
        return try
            sppdir.dict[str]
        catch
            0
        end
    end
end

function Base.getindex(sppdir::SpeciesDirectory, names::Vector{String})
    return map(x -> getindex(sppdir, x), names)
end

function Base.getindex(sppdir::SpeciesDirectory, names::String...)
    return collect(map(x -> getindex(sppdir, x), names))
end

"""
    in(i::Int, sppdir::SpeciesDirectory)

Return true if there is a species with the index number `i` in the species directory `sppdir`.
"""
function Base.in(i::Int, sppdir::SpeciesDirectory)::Bool
    i < 1 && return false
    sppdir.n < i && return false
    return sppdir.list[i] ≠ nothing ? true : false
end

"""
    in(str::String, sppdir::SpeciesDirectory)

Return true if there is a species with the name `str` in the species directory `sppdir`
"""
Base.in(str::String, sppdir::SpeciesDirectory) = haskey(sppdir.dict, str)

"""
    add!(sppdir::SpeciesDirectory, name::String)

Create a new species in the species directory `sppdir`. Returns the index of the new species.
"""
function add!(sppdir::SpeciesDirectory, name::String)
    haskey(sppdir.dict, name) && throw(NonUniqueName([name]))
    push!(sppdir.list, name)
    sppdir.n += 1
    if name ≠ ""
        sppdir.dict[name] = sppdir.n
    end

    return sppdir.n
end

function add!(sppdir::SpeciesDirectory, names::Vector{String})
    duplicated = intersect(names, keys(sppdir.dict))
    if length(duplicated) > 0
        throw(NonUniqueName(duplicated))
    end
    newidx = (sppdir.n + 1):(sppdir.n + length(names))
    push!(sppdir.list, names...)
    filter!(x -> x ≠ "", names)
    merge!(sppdir.dict, Dict{String,Int}(zip(names,newidx)))
    sppdir.n = newidx[end]
    
    return newidx
end

add!(sppdir::SpeciesDirectory) = add!(sppdir, "")