struct Wild{TAG} end

tagof(x::Sym{Wild}) = DEFAULT_TAG
tagof(x::Sym{Wild{TAG}}) where {TAG} = TAG

iswild(x) = false
iswild(x::Sym{<:Wild}) = true
