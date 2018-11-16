Core.eval(m::Module, x::Sym) = Core.eval(m, expr(x))

expr(x::Sym; kwargs...) = expr(Val(gethead(x)), x; kwargs...)

function expr(::Val{:object}, x::Sym; kwargs...)
    @assert gethead(x) === :object
    return expr(firstarg(x); kwargs...)
end

function expr(::Val{:symbol}, x::Sym{TAG}; annotate=false, type_annotate=false, kwargs...) where {TAG}
    @assert gethead(x) === :symbol
    ex = expr(firstarg(x); kwargs...)
    if annotate || (type_annotate && TAG !== Any)
        return :($ex::$TAG)
    else
        return ex
    end
end

function expr(::Val{:type}, x::Sym; kwargs...)
    @assert gethead(x) === :type
    return expr(firstarg(x); kwargs...)
end

function expr(::Val{:fn}, x::Sym; qualified_names=false, kwargs...)
    @assert gethead(x) === :fn
    fn = expr(firstarg(x); kwargs...)
    if qualified_names
        return Expr(:., parentmodule(fn), QuoteNode(nameof(fn)))
    else
        return nameof(fn)
    end
end

function expr(::Val{:function}, x::Sym; kwargs...)
    @assert gethead(x) === :function
    fn, body = getargs(x)
    return Expr(:function, expr(fn, type_annotate=true; kwargs...), expr(body; kwargs...))
end

function expr(::Val{:struct}, x::Sym; kwargs...)
    @assert gethead(x) === :struct
    return Expr(
        :struct,
        map(arg -> expr(arg; kwargs...), getargs(x)[1:2])...,
        map(arg -> expr(arg, type_annotate=true; kwargs...), getargs(x)[3:end])...
    )
end

function expr(::Val{:(=)}, x::Sym; kwargs...)
    @assert gethead(x) === :(=)
    lhs, rhs = getargs(x)
    return Expr(:(=), expr(lhs, type_annotate=true; kwargs...), expr(rhs; kwargs...))
end

function expr(::Val{:(->)}, x::Sym; kwargs...)
    @assert gethead(x) === :(->)
    fn, body = getargs(x)
    return Expr(:(->), expr(fn, type_annotate=true; kwargs...), expr(body; kwargs...))
end

function expr(::Val{head}, x::Sym{TAG}; annotate=false, kwargs...) where {TAG,head}
    @assert gethead(x) === head
    ex = Expr(gethead(x), map(arg -> expr(arg; annotate=annotate, kwargs...), getargs(x))...)
    if annotate
        return :($ex::$TAG)
    else
        return ex
    end
end

@inline expr(a; kwargs...) = a # Catch all

expr(t::Tuple; kwargs...) = Expr(:tuple, map(arg -> expr(arg; kwargs...), t)...)
expr(v::AbstractVector; kwargs...) = Expr(:vect, map(arg -> expr(arg; kwargs...), v)...)
expr(A::AbstractMatrix; kwargs...) = Expr(:vcat, mapslices(x -> Expr(:row, map(arg -> expr(arg; kwargs...), x)...), A, dims=2)...)

block(xs...) = Expr(:block, xs...)

getsymbols(x) = map(firstarg, getsyms(x))

getsyms(x) = Sym[]
getsyms(x::Sym) = getsyms(Val(gethead(x)), x)
getsyms(::Val, x::Sym) = mapreduce(getsyms, union, getargs(x))
getsyms(::Val{:symbol}, x::Sym) = Sym[x]
getsyms(x::Tuple) = mapreduce(getsyms, union, x)
getsyms(x::AbstractArray) = mapreduce(getsyms, union, x)

getops(x) = []
getops(x::Sym) = getops(Val(gethead(x)), x)
getops(::Val, x::Sym) = mapreduce(getops, union, getargs(x))
getops(::Val{:call}, x::Sym) = union([firstarg(x)], mapreduce(getops, union, tailargs(x)))
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
