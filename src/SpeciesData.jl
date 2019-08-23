struct SpeciesDataMatrix{T}
    data::Matrix{T}
    dir::SpeciesDirectory

    function SpeciesDataMatrix{T}(
        data::Matrix{T}, 
        sppdir::SpeciesDirectory
        ) where T
        n = length(sppdir)
        if n ≠ size(data)[1]
            msg = "the number of rows in the matrix should match the number of species given."
            throw(ArgumentError(msg))
        end

        return new{T}(data, sppdir)
    end
end

function SpeciesDataMatrix{T}(
    data::Matrix{T}, 
    sppdir::SpeciesDirectory, 
    names::Vector{String}
    ) where T

    p = sortperm(sppdir[names])

    return SpeciesDataMatrix{T}(data[p,:], sppdir)
end

function SpeciesDataMatrix{T}(dir::SpeciesDirectory, k::Int) where T
    x = Matrix{T}(undef, length(dir), k)
    return SpeciesDataMatrix{T}(x, dir)
end

function SpeciesDataMatrix{T}(value::T, dir::SpeciesDirectory, k::Int) where T
    x = Matrix{T}(undef, length(dir), k)
    fill!(x, value)
    return SpeciesDataMatrix{T}(x, dir)
end

Base.size(dm::SpeciesDataMatrix) = size(dm.data)

# getindex methods
Base.getindex(dm::SpeciesDataMatrix, inds...) = getindex(dm.data, inds...)

Base.getindex(dm::SpeciesDataMatrix, name::String) = dm.data[dm.dir[name], :]

Base.getindex(dm::SpeciesDataMatrix, name::String, inds...) =
    dm.data[dm.dir[name], inds...]

Base.getindex(dm::SpeciesDataMatrix, names::Vector{String}) = 
    dm.data[dm.dir[names], :]

Base.getindex(dm::SpeciesDataMatrix, names::Vector{String}, inds...) =
    dm.data[dm.dir[names], inds...]

# view methods
Base.view(dm::SpeciesDataMatrix, inds...) = view(dm.data, inds...)

Base.view(dm::SpeciesDataMatrix, name::String) = @view dm.data[dm.dir[name], :]

Base.view(dm::SpeciesDataMatrix, name::String, inds...) =
    @view dm.data[dm.dir[name], inds...]

Base.view(dm::SpeciesDataMatrix, names::Vector{String}) = 
    @view dm.data[dm.dir[names], :]

Base.view(dm::SpeciesDataMatrix, names::Vector{String}, inds...) =
    @view dm.data[dm.dir[names], inds...]

# index methods
Base.firstindex(dm::SpeciesDataMatrix) = 1

Base.firstindex(dm::SpeciesDataMatrix, d) = firstindex(dm.data, d)

Base.lastindex(dm::SpeciesDataMatrix) = prod(size(dm))

Base.lastindex(dm::SpeciesDataMatrix, d) = lastindex(dm.data, d)

function Base.setindex!(
    dm::SpeciesDataMatrix{T},
    v::Union{T, Array{T}},
    inds...
    ) where T
    
    setindex!(dm.data, v, inds...)
end

function Base.setindex!(
    dm::SpeciesDataMatrix{T},
    v::Union{T, Array{T}},
    name::String,
    inds...
    ) where T
    
    setindex!(dm.data, v, dm.dir[name], inds...)
end

function Base.setindex!(
    dm::SpeciesDataMatrix{T},
    v::Union{T, Array{T}},
    names::Vector{String},
    inds...
    ) where T
    
    setindex!(dm.data, v, dm.dir[names], inds...)
end

function Base.setindex!(
    dm::SpeciesDataMatrix{T},
    v::Union{T, Array{T}},
    name::String
    ) where T

    dm.data[dm.dir[name],:] = v
end

# function Base.setindex!(
#     dm::SpeciesDataMatrix{T},
#     v::Union{T, Array{T}},
#     names::Vector{String}
#     ) where T
    
#     dm.data[dm.dir[names],:] = v
# end

function Base.summary(io::IO, dm::SpeciesDataMatrix)
    dims = string.(size(dm))
    dims = dims[1] * "x" * dims[2]
    msg =  dims * " SpeciesDataMatrix{" * 
        string(eltype(dm.data)) * "}"
    print(io, msg)

    return nothing
end

function Base.show(io::IO, dm::SpeciesDataMatrix)
    println(io, summary(dm))
    k = size(dm)[2]
    header = ["Species" collect(1:k)...]
    aln = [:l,fill(:r, k)...]
    pretty_table(io, [dm.dir.list dm.data], header; alignment=aln)

    return nothing
end

function Base.show(io::IO, dm::SpeciesDataMatrix{Float64}; digits::Int=4)
    println(io, summary(dm))
    k = size(dm)[2]
    header = ["Species" collect(1:k)...]
    aln = [:l,fill(:r, k)...]
    pretty_table(
        io, 
        [dm.dir.list dm.data], 
        header; 
        alignment=aln, 
        formatter=ft_printf("%5."*string(digits)*"f", collect(2:k+1))
        )

    return nothing
end

"""
    write(io::IO, x::SpeciesDataMatrix)
    write(f::String, x::SpeciesDataMatrix; append=false)

Write a species data matrix to a file or I/O stream in a plaintext tabular format.

Columns are delimited by white space. Species names are written in the first column. Use `append=true` to write at the end of the file instead of overwriting it.
"""
function Base.write(io::IO, x::SpeciesDataMatrix)
    pretty_table(
        io, 
        [x.dir.list x.data], 
        borderless; 
        noheader=true, 
        alignment=:l
        );

    return nothing
end

function Base.write(f::String, x::SpeciesDataMatrix; append=false)
    open(f; write=true, append=append) do io
        write(io, x)
    end;

    return nothing
end

"""
    write_phylip(io::IO, x::SpeciesDataMatrix; namelength=0)
    write_phylip(filename::String, x::SpeciesDataMatrix; namelength=0, append=false)

Write a `SpeciesDataMatrix` to a I/O stream or file in the non-interleaved Phylip file format.

By default, with the argument `namelength=0`, it writes files in a relaxed version of the Phylip format in which the names of the species are not fixed. To enforce fixed name lengths, set `namelength` to the desired name length (10 characters is Phylip's default). Thus names longer than `namelength` will be truncated.
"""
function write_phylip(io::IO, x::SpeciesDataMatrix; namelength=0)
    dims = string.(size(x))
    if namelength == 0
        maxlength = maximum(length.(x.dir.list))
        printnames = rpad.(x.dir.list, maxlength+1)
    else
        printnames = map(xx -> length(xx) > namelength ? xx[1:namelength] : xx, x.dir.list)
        printnames = rpad.(printnames, namelength)
    end
    println(io, dims[1], " ", dims[2])
    n, k = size(x.data)
    for i in 1:n
        print(io, printnames[i])
        for j in 1:k-1
            print(io, x.data[i, j], " ")
        end
        print(io, x.data[i, k], "\n")
    end

    return nothing
end

function write_phylip(filename::String, x::SpeciesDataMatrix; namelength=0, append=false)
    open(filename; write=true, append=append) do io
        write_phylip(io, x, namelength=namelength)
    end;

    return nothing
end

"""
    read_species_data(filename::String, T::Type)
    read_species_data(io::IO, T::Type)
    read_species_data(filename::String, T::Type, dir::SpeciesDirectory; addspecies=false)
    read_species_data(io::IO, T::Type, dir::SpeciesDirectory; addspecies=false)

Read in tabular species data from a file or I/O stream and return a `SpeciesDataMatrix` with data of type `T`.

This parses data in a simple tabular format with white space-delimited columns. The first column contains the species names and the following columns contain all the diferent variables (traits, characters, or other kind of data). The `SpeciesDataMatrix` produced will have the data type specified by `T`.

The `SpeciesDirectory` associated to the output `SpeciesDataMatrix` can be given by `dir`. If none is given, a new `SpeciesDirectory` will be created from the species names in the data file or I/O stream. If a `SpeciesDirectory` is given and the data file or I/O stream contains species names not present in the directory, the arugment `addspecies` can be set to `true` to add the new species to the directory or else the function will throw an error.
"""
function read_species_data(filename::String, T::Type, dir::SpeciesDirectory; addspecies=false)
    open(filename, "r") do io
        read_species_data(io, T, dir; addspecies=addspecies)
    end
end

function read_species_data(filename::String, T::Type)
    open(filename, "r") do io
        read_species_data(io, T)
    end
end

function read_species_data(io::IO, T::Type, dir::SpeciesDirectory; addspecies=false)
    inmat = readdlm(io)
    innames = string.(inmat[:,1])
    data = convert(Matrix{T}, inmat[:,2:end])
    newspp = setdiff(innames, dir.list)
    if addspecies
        add!(dir, newspp)
    else
        length(newspp) ≠ 0 && throw(MissingEntry("The file contains species missing from the species directory."))
    end

    return SpeciesDataMatrix{T}(data, dir, innames)
end

function read_species_data(io::IO, T::Type)
    inmat = readdlm(io)
    innames = string.(inmat[:,1])
    data = convert(Matrix{T}, inmat[:,2:end])
    dir = SpeciesDirectory(innames)

    return SpeciesDataMatrix{T}(data, dir)
end
