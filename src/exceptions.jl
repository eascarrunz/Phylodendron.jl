struct LinkingError <: Exception end
Base.showerror(io::IO, e::LinkingError) = print(io, "the nodes are not linked correctly.")

struct UndefParentError <: Exception end
Base.showerror(io::IO, e::UndefParentError) = print(io, "the node does not have a parent.")

struct UndirectedError <: Exception end
Base.showerror(io::IO, e::UndirectedError) = print(io, "the node is undirected, it cannot have a parent or children.")

struct MissingTreeInfo <: Exception end
Base.showerror(io::IO, e::MissingTreeInfo) = print(io, "this function requires information that is missing from the tree metadata. Please use `update!` to add this information to the tree.")

struct InvalidNewick <: Exception end
Base.showerror(io::IO, e::InvalidNewick) = print(io, "the Newick string cannot is invalid or not supported.")

struct MissingSpeciesDirectory <: Exception end
Base.showerror(io::IO, e::MissingSpeciesDirectory) = print(io, "the tree is not associated to a species directory.")

struct WrongTopology <: Exception
	msg::String
end
Base.showerror(io::IO, e::WrongTopology) = print(io, e.msg)

struct FinishedTraversalError <: Exception end

struct RootError <: Exception end