using Test
using Phylodendron
nwk = "(Gorilla_gorilla,((Paranthropus_boisei,(Homo_sapiens)Homo_erectus),(Pan_troglodytes,Pan_paniscus)Pan)Hominini)Homininae;"
g_gorilla = Node("Gorilla_gorilla")
homininae = Node("Homininae")
hominini = Node("Hominini")
pan = Node("Pan")
p_paniscus = Node("Pan_paniscus")
p_troglodytes = Node("Pan_troglodytes")
homo = Node("Homo")
h_sapiens = Node("Homo_sapiens")
h_habilis = Node("Homo_habilis")

homininae = parse_newick(nwk)


link!(homininae, g_gorilla)
link!(homininae, hominini)
link!(hominini, homo)
link!(homo, h_sapiens)
link!(homo, h_habilis)
link!(hominini, pan)
link!(pan, p_troglodytes)
link!(pan, p_paniscus)

# root!(e)

preorder(homininae)

root!(homininae)

preorder(homininae)
postorder(e)

traverser = PreorderTraverser(e)
while ! isfinished(traverser)
    print(next!(traverser))
end


root!(e)

children(d)