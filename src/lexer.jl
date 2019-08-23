struct Token
    name::Symbol
    value::Any

    # Constructor that preprocesses `:string` tokens
    # TODO: Do the preprocessing elsewhere, this is too specific!
    function Token(name::Symbol, str::String)
        name == :string ? value = strip(str, ['"', '\'', ' ', '\n']) : value = str
        value = String(value)
        new(name, value)
    end
end

mutable struct Lexer
    input::String
    next_token::Union{Nothing, Token}
    tokendefs::Vector{Tuple{Symbol,Regex}}
end

"""
Return the current token in the lexer without taking it out from the lexer.
"""
function peektoken(lxr::Lexer)::Union{Token,Nothing}
    lxr.next_token != nothing && return lxr.next_token
    length(lxr.input) == 0 && return nothing
    m = nothing

    for (defname, defregex) in lxr.tokendefs
        m = match(defregex, lxr.input)
        if m != nothing
            lxr.next_token = Token(defname, convert(String, m.match))
            return lxr.next_token
        end
    end

    error("Invalid token received")
end

"""
Take out the current token in the lexer and return it
"""
function next!(lxr::Lexer)::Token
    token = lxr.next_token

    if token == nothing
        token = peektoken(lxr)
    end
    if token == nothing
        return nothing
    else
        lxr.input = lxr.input[length(token.value) + 1 : end]
        lxr.next_token = nothing
    end

    return token
end

function readtoken!(lxr::Lexer, name::Symbol)::Token
    token = peektoken(lxr)
    if token.name ≠ name
        error("Expected a `$(name)` token, but received a `$(token.name)` token. String: $(lxr.input)")
    end
    next!(lxr)

    return token
end

function skiptoken!(lxr::Lexer, name::Symbol)::Lexer
    while peektoken(lxr).name == name
        readtoken!(lxr, name)
    end

    return lxr
end