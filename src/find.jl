"""
	findspecies(sp, t::Tree)

Find the node containing species `sp` in tree `t`.

`sp` can be either the species number or its name in the species directory.
"""
function findspecies(sp::Int, t::Tree)
	t.dir ≠	nothing || throw(MissingSpeciesDirectory())
	sp ∉ t.dir && throw(MissingEntry("species ", sp, " is not in the species directory of the tree."))

	trav = PreorderTraversal(t, directed=false)
	while ! isfinished(trav)
		p = next!(trav)
		p.species == sp && return p
	end

	return nothing
end

findspecies(sp::AbstractString, t::Tree) = findspecies(t.dir[sp], t)