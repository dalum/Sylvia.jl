expr(s::Sym) = (expr(Val(s.head), s))

function expr(::Val{:object}, s::Sym)
    @assert s.head === :object
    return s.args[1]
end

function expr(::Val{:symbol}, s::Sym)
    @assert s.head === :symbol
    return s.args[1]
end

function expr(::Val{:call}, s::Sym)
    @assert s.head === :call
    return Expr(:call, nameof(s.args[1]), map(expr, s.args[2:end])...)
end

function expr(::Val{head}, s::Sym) where head
    @assert s.head === head
    return Expr(s.head, map(expr, s.args)...)
end

expr(a) = a # Catch all

expr(t::Tuple) = Expr(:tuple, map(expr, t)...)
expr(v::AbstractVector) = Expr(:vect, map(expr, v)...)
expr(A::AbstractMatrix) = Expr(:vcat, mapslices(x -> Expr(:row, map(expr, x)...), A, dims=2)...)

macro expr(x)
    return :(expr($(esc(x))))
end

getsymbols(x) = Set(Symbol[])
getsymbols(x::Sym) = getsymbols(Val(x.head), x)
getsymbols(::Val, x::Sym) = mapreduce(getsymbols, union, x.args)
getsymbols(::Val{:symbol}, x::Sym) = Set(Symbol[x.args[1]])
getsymbols(x::Tuple) = mapreduce(getsymbols, union, x)
getsymbols(x::AbstractArray) = mapreduce(getsymbols, union, x)

macro λ(e)
    obj = Base.eval(__module__, e)
    body = expr(obj)
    symbols = sort!(collect(getsymbols(obj)))
    return esc(Expr(:(->), Expr(:tuple, symbols...), body))
end
