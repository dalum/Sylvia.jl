expr(s::Sym) = (expr(Val(gethead(s)), s))

function expr(::Val{:object}, s::Sym)
    @assert gethead(s) === :object
    return firstarg(s)
end

function expr(::Val{:symbol}, s::Sym)
    @assert gethead(s) === :symbol
    return firstarg(s)
end

function expr(::Val{:call}, s::Sym)
    @assert gethead(s) === :call
    return Expr(:call, nameof(firstarg(s)), map(expr, tailargs(s))...)
end

function expr(::Val{head}, s::Sym) where head
    @assert gethead(s) === head
    return Expr(gethead(s), map(expr, getargs(s))...)
end

expr(a) = a # Catch all

expr(t::Tuple) = Expr(:tuple, map(expr, t)...)
expr(v::AbstractVector) = Expr(:vect, map(expr, v)...)
expr(A::AbstractMatrix) = Expr(:vcat, mapslices(x -> Expr(:row, map(expr, x)...), A, dims=2)...)

macro expr(x)
    return :(expr($(esc(x))))
end

getsymbols(x) = Set(Symbol[])
getsymbols(x::Sym) = getsymbols(Val(gethead(x)), x)
getsymbols(::Val, x::Sym) = mapreduce(getsymbols, union, getargs(x))
getsymbols(::Val{:symbol}, x::Sym) = Set(Symbol[firstarg(x)])
getsymbols(x::Tuple) = mapreduce(getsymbols, union, x)
getsymbols(x::AbstractArray) = mapreduce(getsymbols, union, x)

getops(x) = Set([])
getops(x::Sym) = getops(Val(gethead(x)), x)
getops(::Val, x::Sym) = mapreduce(getops, union, getargs(x))
getops(::Val{:call}, x::Sym) = union(Set([firstarg(x)]), mapreduce(getops, union, tailargs(x)))
getops(x::Tuple) = mapreduce(getops, union, x)
getops(x::AbstractArray) = mapreduce(getops, union, x)

macro λ(e)
    return :(compile($(esc(e))))
end
