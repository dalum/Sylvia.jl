struct Wild{TAG} end

tagof(x::Sym{Wild{TAG}}) where {TAG} = TAG

const SymOrWild{T} = Union{Sym{Wild{T}}, Sym{T}}

wild(x::Symbol) = wild(sym(x))
wild(TAG::Type, x::Symbol) = wild(sym(TAG, x))
wild(x::Sym{TAG}) where {TAG} = Sym{Wild{TAG}}(gethead(x), getargs(x)...)
