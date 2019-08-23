#==
    READING NEWICK STRINGS
==#

# TODO: Implement support for Newick comments in the format `[&...]`

const nullnode = Node()

#= Define token names & ther RegEx patterns.
Note that it is important the order in which the token definitions are given. The regexes for :number and :string will have matches in common, but the lexer will always process a :number token because it accepts the first match found in the token definition vector.
=#
const NEWICK_TOKENDEFS = [
    (:number,       r"^[+-]?\d+(\.\d+)?([eE][+-]?\d+)?"),
    (:colon,        r"^[\s\n]*:[\s\n]*"),
    (:semicolon,    r"^[\s\n]*;[\s\n]*"),
    (:comma,        r"^[\s\n]*,[\s\n]*"),
    (:rparen,       r"^[\s\n]*\)[\s\n]*"),
    (:lparen,       r"^[\s\n]*\([\s\n]*"),
    (:comment,      r"\[\[^\]]*\]"),
    (:string,       r"^((\"[^\"]+\")|('[^']+')|([^,:(); \r\t\n\[\]]+))"),
    (:whitespace,   r"^[\s\n\r]+")
    ]

function parsefork!(lxr::Lexer, p::Node)::Nothing
    skiptoken!(lxr, :comment)
    next_token = peektoken(lxr)
    if next_token.name == :lparen
        parseinternal!(lxr, p)
    else
        parsetip!(lxr, p)
    end
    next_token = peektoken(lxr)
    skiptoken!(lxr, :comment)
    while next_token.name == :comma
        readtoken!(lxr, :comma)
        skiptoken!(lxr, :comment)
        next_token = peektoken(lxr)
        if next_token.name == :lparen
            parseinternal!(lxr, p)
        else
            parsetip!(lxr, p)
        end
        skiptoken!(lxr, :comment)
        next_token = peektoken(lxr)
    end

    return nothing
end

function parseinternal!(lxr::Lexer, p::Node)::Node
    readtoken!(lxr, :lparen)
    skiptoken!(lxr, :comment)
    next_token = peektoken(lxr)
    q = Node()
    p ≠ nullnode && link!(p, q)
    parsefork!(lxr, q)
    readtoken!(lxr, :rparen)
    skiptoken!(lxr, :comment)
    skiptoken!(lxr, :comment)
    next_token = peektoken(lxr)
    if next_token.name ∈ (:string, :number)
        q.label = next_token.value
        readtoken!(lxr, next_token.name)
        next_token = peektoken(lxr)
    end
    skiptoken!(lxr, :comment)
    if next_token.name == :colon
        p == nullnode && @error "Branch lengths at the root node are not supported."
        readtoken!(lxr, :colon)
        skiptoken!(lxr, :comment)
        next_token = readtoken!(lxr, :number)
        brlength!(p, q, parse(Float64, next_token.value))
    end

    return q
end

function parsetip!(lxr::Lexer, p::Node)::Node
    q = Node()
    next_token = peektoken(lxr)
    p ≠ nullnode && link!(p, q)

    if next_token.name ∈ (:string, :number)
        q.label = next_token.value
        next_token = readtoken!(lxr, next_token.name)
    end
    skiptoken!(lxr, :comment)
    next_token = peektoken(lxr)
    if next_token.name == :colon
        p == nullnode && @error "Branch lengths at the root node are not supported."
        readtoken!(lxr, :colon)
        skiptoken!(lxr, :comment)
        next_token = readtoken!(lxr, :number)
        brlength!(p, q, parse(Float64, next_token.value))
    end
    skiptoken!(lxr, :comment)

    return q
end

function parse_newick(str::String)
    lxr = Lexer(str, nothing, NEWICK_TOKENDEFS)
    skiptoken!(lxr, :comment)
    next_token = peektoken(lxr)
    if next_token.name == :lparen
        p = parseinternal!(lxr, nullnode)
    end
    readtoken!(lxr, :semicolon)

    return p
end

function parse_newick!(lxr::Lexer)
    skiptoken!(lxr, :comment)
    next_token = peektoken(lxr)
    if next_token.name == :lparen
        p = parseinternal!(lxr, nullnode)
    end
    readtoken!(lxr, :semicolon)

    return p
end

"""
    read_newick(filename::AbstractString; nhint::Int=1000, fullinit::Bool=true)

Read trees in Newick format from a file.

Performance with large files can be improved by adjusting the `nhint` value to the approximate number of trees in the file (1000 by default), and by setting `fullinit` to `false` to avoid the initialisation of non-essential tree fields.
"""
function read_newick(filename::AbstractString; nhint::Int=1000, fullinit::Bool=true)::Vector{Tree}
    file = open(filename)
    intrees = Vector{Tree}(undef, nhint)
    treecount = 0
    notree = false
    while ! eof(file)
        instring = ""
        i = ' '
        while i ≠ ';'
            if eof(file)
                notree = occursin(r"^[\s\n\r]*$", instring)
                notree || @error "End of file reached before end of Newick string."
                break
            end
            i = read(file, Char)
            instring *= i
        end
        notree && break
        lxr = Lexer(instring, nothing, NEWICK_TOKENDEFS)
        tree_i = Tree(parse_newick!(lxr); fullinit=fullinit)
        treecount += 1
        if treecount <= nhint
            intrees[treecount] = tree_i
        else
            push!(intrees, tree_i)
        end
    end
    close(file)

    treecount < 1 && @error "No trees were found in the file."

    return intrees[1:treecount]
end

#==
    WRITING NEWICK STRINGS
==#

"""
Generate the Newick substring (not capped by \";\") of a non-origin `Node`. This function is intended to be always called from `_newick_string_origin`.
"""
function _newick_substring(p::Node, parent_p::Node)::String
    outstring = ""
    child_counter = 0
    for q in neighbours(p)
        q == parent_p && continue
        child_counter += 1
        outstring *= child_counter > 1 ? "," : ""
        outstring *= _newick_substring(q, p)
    end

    outstring = child_counter > 0 ? "(" * outstring * ")" : ""
    label_p = label(p)
    # TODO: Check that the label string does not break Newick and add quote marks or underscores if necessary.
    outstring *= label_p
    br_p = brlength(parent_p, p)
    outstring *= isnan(br_p) ? "" : string(":", br_p)

    return outstring
end

"""
Generate the Newick substring (not capped by \";\") of the origin `Node`.
"""
function _newick_substring_origin(p::Node)::String
    outstring = ""
    child_counter = 0
    children_p = isdirected(p) ? children(p) : neighbours(p)
    for q in children_p
        child_counter += 1
        outstring *= child_counter > 1 ? "," : ""
        outstring *= _newick_substring(q, p)
    end

    outstring = child_counter > 0 ? "(" * outstring * ")" : ""
    label_p = label(p)
    # TODO: Check that the label string does not break Newick and add quote marks or underscores if necessary.
    outstring *= label_p

    return outstring
end

"""
    newick_string(p::Node)::String

Return the Newick representation string of the tree subtended by node `p`.

If `p` belongs to a rooted tree, the function will return only the Newick string corresponding to the subtree subtended by `p`. With unrooted trees, the full Newick string is given, with the tree "pseudo-rooted" in `p`.
"""
newick_string(p::Node)::String = _newick_substring_origin(p) * ";"

"""
    newick_string(p::Node)::String

Return the Newick representation of tree `t`.
"""
newick_string(t::Tree)::String = _newick_substring_origin(t.origin) * ";"

"""
    write_newick(filename::AbstractString, t::Union{Tree,TreeVector}; append::Bool=false)

Write the Newick representation of a tree or a vector of trees to a file.

Set `append` to `true` to add the tree(s) at the end instead of overwriting the contents of the file.
"""
function write_newick(filename::AbstractString, t::Union{Tree,TreeVector}; append::Bool=false)
    open(filename, append ? "a" : "w") do f
        write_newick(f, t)
    end

    return nothing
end

function write_newick(io::IO, t::Tree)
    print(io, newick_string(t), "\n")

    return nothing
end

function write_newick(io::IO, t::TreeVector)
    for tt in t
        print(io, newick_string(tt), "\n")
    end

    return nothing
end

write_newick(t::Tree) = newick_string(t)

write_newick(t::Vector{Tree}) = newick_string.(t)