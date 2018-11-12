mutable struct Context <: AbstractDict{Sym,Sym}
    data::OrderedDict{Sym,Sym}
    resolve::Bool
end
Context(pairs::Pair{<:Sym,<:Sym}...) = Context(OrderedDict(pairs...), true)

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

const GLOBAL_CONTEXT_STACK = Context[Context()]

macro __CONTEXT__()
    return :(GLOBAL_CONTEXT_STACK[end])
end

function query!(x::Sym)
    for ctx in reverse(GLOBAL_CONTEXT_STACK)
        ctx.resolve || return x
        _query!(x, ctx)
    end
    return x
end

function _query!(x::Sym, ctx::Context)
    for (key, val) in Iterators.reverse(ctx)
        m = match(x, key)
        if ismatch(m)
            substitute!(x, val, filter(y -> !(y isa Bool), m)...)
        end
    end
    return x
end

set!(ctx::Context, x, val) = set!(ctx, Sym(x), Sym(val))
set!(ctx::Context, x, val::Sym) = set!(ctx, Sym(x), val)
set!(ctx::Context, x::Sym, val) = set!(ctx, x, Sym(val))
set!(ctx::Context, x::SymOrWild{T}, val::SymOrWild{<:T}) where {T} = setindex!(ctx, val, x)
macro set!(ex::Expr)
    @assert Meta.isexpr(ex, :call) && ex.args[1] === :(=>)
    x, val = ex.args[2:end]
    return quote
        if @__CONTEXT__().resolve
            @__CONTEXT__().resolve = false
            set!(@__CONTEXT__, $(esc(x)), $(esc(val)))
            @__CONTEXT__().resolve = true
        else
            set!(@__CONTEXT__, $(esc(x)), $(esc(val)))
        end
    end
end

unset!(ctx::Context, x) = delete!(ctx, Sym(x))
unset!(ctx::Context, x::Sym) = delete!(ctx, x)
macro unset!(x)
    __return__ = gensym("return")
    return quote
        if @__CONTEXT__().resolve
            @__CONTEXT__().resolve = false
            $__return__ = unset!(@__CONTEXT__, $(esc(x)))
            @__CONTEXT__().resolve = true
            $__return__
        else
            unset!(@__CONTEXT__, $(esc(x)))
        end
    end
end

macro scope(ex)
    retsym = gensym("return")
    return quote
        push!(GLOBAL_CONTEXT_STACK, Context())
        $retsym = $(esc(ex))
        pop!(GLOBAL_CONTEXT_STACK)
        $retsym
    end
end
