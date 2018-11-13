Core.eval(m::Module, x::Sym) = Core.eval(m, expr(x))

expr(x::Sym; kwargs...) = (expr(Val(gethead(x)), x; kwargs...))

function expr(::Val{:object}, x::Sym; kwargs...)
    @assert gethead(x) === :object
    return firstarg(x)
end

function expr(::Val{:symbol}, x::Sym; annotate=false, kwargs...)
    @assert gethead(x) === :symbol
    if annotate
        return :($(firstarg(x))::$(tagof(x)))
    else
        return firstarg(x)
    end
end

function expr(::Val{:type}, x::Sym; kwargs...)
    @assert gethead(x) === :type
    return firstarg(x)
end

function expr(::Val{:fn}, x::Sym; kwargs...)
    @assert gethead(x) === :fn
    return nameof(firstarg(x))
end

function expr(::Val{:call}, x::Sym; kwargs...)
    @assert gethead(x) === :call
    return Expr(:call, map(arg -> expr(arg; kwargs...), getargs(x))...)
end

function expr(::Val{:function}, x::Sym; kwargs...)
    @assert gethead(x) === :function
    fn, body = getargs(x)
    return Expr(:function, expr(fn, annotate=true; kwargs...), expr(body; kwargs...))
end

function expr(::Val{:macrocall}, x::Sym; kwargs...)
    @assert gethead(x) === :macrocall
    args = getargs(x)
    return Expr(:macrocall, map(arg -> expr(arg; kwargs...), args)...)
end

function expr(::Val{head}, x::Sym; kwargs...) where head
    @assert gethead(x) === head
    return Expr(gethead(x), map(arg -> expr(arg; kwargs...), getargs(x))...)
end

expr(a; kwargs...) = a # Catch all

expr(t::Tuple; kwargs...) = Expr(:tuple, map(arg -> expr(arg; kwargs...), t)...)
expr(v::AbstractVector; kwargs...) = Expr(:vect, map(arg -> expr(arg; kwargs...), v)...)
expr(A::AbstractMatrix; kwargs...) = Expr(:vcat, mapslices(x -> Expr(:row, map(arg -> expr(arg; kwargs...), x)...), A, dims=2)...)

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
