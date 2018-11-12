struct Wild{TAG} end

tagof(x::Sym{Wild{TAG}}) where {TAG} = TAG

const SymOrWild{T} = Union{Sym{Wild{T}}, Sym{T}}
