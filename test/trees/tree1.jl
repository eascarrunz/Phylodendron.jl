# Define labelled nodes from A to T
a = Node("A")
b = Node("B")
c = Node("C")
d = Node("D")
e = Node("E")
f = Node("F")
g = Node("G")
h = Node("H")
i = Node("I")
j = Node("J")
k = Node("K")
l = Node("L")
m = Node("M")
n = Node("N")
o = Node("O")
p = Node("P")
q = Node("Q")
r = Node("R")
s = Node("S")
t = Node("T")

# Link them
link!(a, b)
link!(b, c)
link!(c, d)
link!(d, e)
link!(e, f)
link!(f, g)
link!(f, h)
link!(e, i)
link!(i, j)
link!(j, k)
link!(i, l)
link!(i, m)
link!(c, n)
link!(n, o)
link!(o, p)
link!(o, q)
link!(n, r)
link!(r, s)
link!(r, t)

#= The resulting tree should have the following Newick string from A:
    "((((((G,H)F,((K)J,L,M)I)E)D,((P,Q)O,(S,T)R)N)C)B)A;"
=#

tree = Tree(b)

#= Assign branch lengths to the tree. =#
brlengths = [
    4.465957012470789,
    32.620624765198855,
    3.3650512429729265,
    7.263546792740656,
    10.193537222701895,
    28.38523219145209,
    4.956537575274135,
    11.855818691462021,
    1.9066195090479867,
    10.627409065542043,
    16.331078235033235,
    14.711619982982215,
    28.28461325395832,
    7.41317192325869,  
    11.35796124012394,
    0.6669348982306939,
    7.594073912870435,
    22.386191336343458,
    0.6063155522048979
 ]

for i in 1:19
    brlength!(tree.preorder[1+i]..., brlengths[i])
end