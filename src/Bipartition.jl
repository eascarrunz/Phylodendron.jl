using Phylodendron

abstract type Bipartition end

"""
Bit vector representing how a branch separates two exclusive sets of species in a tree. Rooted tree bipartitions uniquely characterise branches relative to the position of the root or tree origin.
"""
struct DirectedBipartition <: Bipartition
	v::BitVector
end

"""
Bit vector representing how a branch separates two exclusive sets of species in a tree. Unrooted tree bipartitions uniquely characterise branches invariantly to the position of the root or tree origin.
"""
struct UndirectedBipartition <: Bipartition
	v::BitVector

	function UndirectedBipartition(v::BitVector)
		v = v[1] ? .!v : v
		new(v)
	end
end

"""
	string(bp::Bipartition)

Give the string representation of biparpatition `bp`.
"""
Base.string(bp::Bipartition) = mapreduce(x -> x ? "■" : "□", *, bp.v)

function Base.show(io::IO, bp::Bipartition)
	summary(io, bp)
	println(string(bp))

	return nothing
end

