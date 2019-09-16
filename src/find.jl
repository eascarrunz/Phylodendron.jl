"""
	findspecies(sp, t::Tree)

Find the node containing species `sp` in tree `t`.

`sp` can be either the species number or its name in the species directory.
"""
function findspecies(sp::Int, t::Tree)
	t.dir ≠	nothing || throw(MissingSpeciesDirectory())
	if sp ∉ t.dir
		msg = "species " * string(sp) * " is not in the species directory of the tree."
		throw(MissingEntry(msg))
	end
	sp == 0 && return nothing

	trav = PreorderTraverser(t, false)
	while ! isfinished(trav)
		p = next!(trav)
		p.species == sp && return p
	end

	return nothing
end

findspecies(sp::AbstractString, t::Tree) = findspecies(t.dir[sp], t)