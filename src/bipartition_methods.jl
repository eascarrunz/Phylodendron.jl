function update_bipartition!(p::Node, q::Node, n::Int; directed=isdirected(p))
	br = getbranch(p, q)
	v = zeros(n)
	if hasspecies(p)
		v[p.species] = true
	end
	for r in neighbours(p)
		r == q && continue
		v .|= getbranch(p, r).bipart.v
	end
	br.bipart = rooted ? DirectedBipartition(v) : UndirectedBipartition(v)
end

function compute_bipartitions!(t::Tree; directed=t.rooted)
	trav = PostorderTraverser(t)
	n = length(t.dir)
	bplist = Deque{Bipartition}()
	while ! isfinished(trav)
		p, q = nextpair!(trav)
		p == q && break
		br = getbranch(q, p)
		v = falses(n)
		if hasspecies(p)
			v[p.species] = true
		end
		if ! istip(p)
			for r in neighbours(p)
				r == q && continue
				v .|= getbranch(p, r).bipart.v
			end
		end
		br.bipart = directed ? DirectedBipartition(v) : UndirectedBipartition(v)
		push!(bplist, br.bipart)
	end
	t.bipartitions = Set(collect(bplist))

	return nothing
end

"""
	istrivial(bp::Bipartition)

A bipartition is trivial if it separates just one species (or none) from the rest.
"""
istrivial(bp::Bipartition)::Bool = sum(bp.v) > 1

"""
	isinformative(bp::Bipartition)

A bipartition is informative if it separates at least one species from the rest.

Uninformative bipartitions are not even bipartitions proper, as they don't define disjoint sets of species. Branches of subtrees without any species in their nodes have uninformative bipartitions.
"""
isinformative(bp::Bipartition)::Bool = sum(bp.v) > 0

"""
	are_compatible(bp1::Bipartition, bp2::Bipartition)

Return true if bipartitions `bp1` and `bp2` can be present in the same tree.

Compatibility between bipartitions depends on whether they are directed: if an undirected bipartition is compatible with a directed bipartition, it is also compatible with the complement of that directed bipartition. A directed bipartition is never compatible with its complement. Undirected bipartitions have no complement.
"""
function are_compatible(bp1::Bipartition, bp2::Bipartition)
	v3 = bp1.v .| bp2.v

	return (v3 == bp1.v || v3 == bp2.v)
end

function are_compatible(bp1::DirectedBipartition, bp2::UndirectedBipartition)
	v1 = bp1.v[1] ? .! bp1.v : bp1.v
	v3 = v1 .| bp2.v

	return (v3 == v1 || v3 == bp2.v)
end

are_compatible(bp1::UndirectedBipartition, bp2::DirectedBipartition) =
	are_compatible(bp2, bp1)

are_conflicting(bp1::Bipartition, bp2::Bipartition) = ! are_compatible(bp1, bp2)
