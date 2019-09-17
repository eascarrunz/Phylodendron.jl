function update_bipartition!(p::Node, q::Node, n::Int)
	br = getbranch(p, q)
	v = zeros(n)
	if hasspecies(p)
		v[p.species] = true
	end
	for r in neighbours(p)
		r == q && continue
		v .|= getbranch(p, r).bipart.v
	end
	br.bipart = Bipartition(v)

	return nothing
end

"""
	compute_bipartitions!(t::Tree)

Compute the species bipartition vectors in all the branches of tree `t`. 
"""
function compute_bipartitions!(t::Tree)
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
		br.bipart = Bipartition(v)
		push!(bplist, br.bipart)
	end
	t.bipartitions = Set(collect(bplist))

	return nothing
end

"""
	istrivial(bp::Bipartition)

A bipartition is trivial if it separates just one species from the rest.
"""
function istrivial(bp::Bipartition)::Bool
	i = length(bp.v)
	s = sum(bp.v)
	return (s == i - 1 || s == 1)
end

"""
	isinformative(bp::Bipartition)

A bipartition is informative if it separates at least one species from the rest.

Uninformative bipartitions are not even bipartitions proper, as they don't define disjoint sets of species.
"""
isinformative(bp::Bipartition)::Bool = sum(bp.v) > 0

"""
	are_compatible(bp1::Bipartition, bp2::Bipartition)

Return true if bipartitions `bp1` and `bp2` can be present in the same tree.
"""
function are_compatible(bp1::Bipartition, bp2::Bipartition)
	cv1 = .! bp1.v
	cv2 = .! bp2.v

	(bp1.v == bp1.v .| bp2.v) && return true
	(bp1.v == bp1.v .| cv2) && return true
	(cv1 == cv1 .| bp2.v) && return true
	(cv1 == cv1 .| cv2) && return true

	return false
end

are_conflicting(bp1::Bipartition, bp2::Bipartition) = ! are_compatible(bp1, bp2)
