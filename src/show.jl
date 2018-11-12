function Base.show(io::IO, x::T) where {T <: Sym}
    e = expr(x)
    print(io, sprint(print, e, context=io))
end
