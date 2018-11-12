mutable struct Context <: AbstractDict{Sym,Sym}
    parent::Union{Context,Nothing}
    data::OrderedDict{Sym,Sym}
    resolve::Bool
end
Context(parent::Union{Context,Nothing}, pairs::Pair{<:Sym,<:Sym}...) = Context(parent, OrderedDict(pairs...), true)
Context(pairs::Pair{<:Sym,<:Sym}...) = Context(nothing, pairs...)

Base.length(ctx::Context) = length(ctx.data)
Base.iterate(ctx::Context) = iterate(ctx.data)
Base.iterate(ctx::Context, x) = iterate(ctx.data, x)
Base.getindex(ctx::Context, key) = getindex(ctx.data, key)
Base.setindex!(ctx::Context, val, key) = setindex!(ctx.data, val, key)
Base.delete!(ctx::Context, key) = (delete!(ctx.data, key); ctx)

Base.iterate(r::Base.Iterators.Reverse{Context}) = Base.iterate(r::Base.Iterators.Reverse{Context}, 1)
function Base.iterate(r::Base.Iterators.Reverse{Context}, x)
    ctx = r.itr
    l = length(ctx)
    l + 1 - x > 0 || return nothing
    res = iterate(ctx, l + 1 - x)
    res === nothing && return nothing
    return (res[1], x + 1)
end

const GLOBAL_CONTEXT = Context()
const ACTIVE_CONTEXT = Ref(GLOBAL_CONTEXT)

macro __context__()
    return :(ACTIVE_CONTEXT[])
end

function query!(x::Sym, ctx=ACTIVE_CONTEXT[])
    ctx.resolve || return x

    for (key, val) in Iterators.reverse(ctx)
        m = match(x, key)
        if ismatch(m)
            substitute!(x, val, filter(y -> !(y isa Bool), m)...)
        end
    end

    ctx.parent === nothing || query!(x, ctx.parent)
    return x
end

set!(ctx::Context, x, val) = set!(ctx, Sym(x), Sym(val))
set!(ctx::Context, x, val::Sym) = set!(ctx, Sym(x), val)
set!(ctx::Context, x::Sym, val) = set!(ctx, x, Sym(val))
set!(ctx::Context, x::SymOrWild{T}, val::SymOrWild{<:T}) where {T} = setindex!(ctx, val, x)
macro set!(ex::Expr)
    @assert Meta.isexpr(ex, :call) && ex.args[1] === :(=>)
    x, val = ex.args[2:end]
    expr = :(set!(@__context__, $(esc(x)), $(esc(val))))

    if @__context__().resolve
        __return__ = gensym("return")
        return quote
            @__context__().resolve = false
            $__return__ = $expr
            @__context__().resolve = true
            $__return__
        end
    end
    return expr
end

unset!(ctx::Context, x) = delete!(ctx, Sym(x))
unset!(ctx::Context, x::Sym) = delete!(ctx, x)
macro unset!(x)
    expr = :(unset!(@__context__, $(esc(x))))

    if @__context__().resolve
        __return__ = gensym("return")
        return quote
            @__context__().resolve = false
            $__return__ = $expr
            @__context__().resolve = true
            $__return__
        end
    end
    return expr
end

macro scope(ex)
    return scope(:nothing, ex)
end

macro scope(option::Symbol, ex)
    return scope(option, ex)
end

function scope(option::Symbol, ex)
    __return__ = gensym("return")
    __context__ = gensym("context")
    expr = quote
        let
            $__context__ = Context(@__context__)
            ACTIVE_CONTEXT[] = $__context__
            $__return__ = $(esc(ex))
            ACTIVE_CONTEXT[] = $__context__.parent
            $__return__
        end
    end

    if @__context__().resolve && option === :suspend
        __return__ = gensym("return")
        return quote
            @__context__().resolve = false
            $__return__ = $expr
            @__context__().resolve = true
            $__return__
        end
    end
    return expr
end
