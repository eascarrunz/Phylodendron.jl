function _clone(br::Branch)
	cbr = Branch()
	cbr.length = br.length
	cbr.label = br.label
	cbr.bipart = br.bipart

	return cbr
end

function _clone(p::Node)
	cp = Node()
	cp.isdirected = p.isdirected
	cp.hasparent = p.hasparent
	cp.istip = p.istip
	cp.label = p.label
	cp.dataviews = p.dataviews
	cp.species = p.species
	cp.idx = p.idx

	return cp
end

function _clone(p::Node, q::Node)
	cp = _clone(p)
	for r in neighbours(p)
		r == q && continue
		cr = _clone(r, p)
		cbr = _clone(getbranch(p, r))
		link!(cp, cr, cbr)
	end

	return cp
end

"""
	clone(t::Tree)

Create a duplicate of tree `t`.

The new tree shares the same species directory as tree `t`, but all the other properties of the tree, nodes, and branches are copied rather than referenced. Models are not copied.
"""
function clone(t::Tree)
	corigin = _clone(t.origin)
	for p in neighbours(t.origin)
		cp = _clone(p, t.origin)
		cbr = _clone(getbranch(t.origin, p))
		link!(corigin, cp, cbr)
	end
	ct = Tree(corigin)
	ct.rooted = t.rooted
	ct.label = t.label
	ct.dir = t.dir
	ct.autoupdate = t.autoupdate
	ct.bipartitions = t.bipartitions
	update!(ct)

	return ct
end