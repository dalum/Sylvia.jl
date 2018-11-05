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

collectsort(x::Set{Sym}; kwargs...) = sort!(collect(x), by=string; kwargs...)

getsymbols(x) = map(firstarg, collectsort(getsyms(x)))

getsyms(x) = Set(Sym[])
getsyms(x::Sym) = getsyms(Val(gethead(x)), x)
getsyms(::Val, x::Sym) = mapreduce(getsyms, union, getargs(x))
getsyms(::Val{:symbol}, x::Sym) = Set(Sym[x])
getsyms(x::Tuple) = mapreduce(getsyms, union, x)
getsyms(x::AbstractArray) = mapreduce(getsyms, union, x)

getops(x) = Set([])
getops(x::Sym) = getops(Val(gethead(x)), x)
getops(::Val, x::Sym) = mapreduce(getops, union, getargs(x))
getops(::Val{:call}, x::Sym) = union(Set([firstarg(x)]), mapreduce(getops, union, tailargs(x)))
getops(x::Tuple) = mapreduce(getops, union, x)
getops(x::AbstractArray) = mapreduce(getops, union, x)

macro λ(e, locals...)
    locals = map(x -> (x.head = :kw; x), locals)
    return :(lower($(esc(e)), $(map(esc, locals)...)))
end
