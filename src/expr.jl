Core.eval(m::Module, x::Sym) = Core.eval(m, expr(x))

expr(x::Sym) = (expr(Val(gethead(x)), x))

function expr(::Val{:object}, x::Sym)
    @assert gethead(x) === :object
    return firstarg(x)
end

function expr(::Val{:symbol}, x::Sym)
    @assert gethead(x) === :symbol
    return firstarg(x)
end

function expr(::Val{:type}, x::Sym)
    @assert gethead(x) === :type
    return firstarg(x)
end

function expr(::Val{:function}, x::Sym)
    @assert gethead(x) === :function
    return nameof(firstarg(x))
end

function expr(::Val{:call}, x::Sym)
    @assert gethead(x) === :call
    return Expr(:call, map(expr, getargs(x))...)
end

function expr(::Val{head}, x::Sym) where head
    @assert gethead(x) === head
    return Expr(gethead(x), map(expr, getargs(x))...)
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

# For when `@locals` gets merged into master:
# macro λ(e)
#     return :(lower($(esc(e)); Base.@locals()...))
# end
