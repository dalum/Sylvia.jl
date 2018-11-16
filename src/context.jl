mutable struct Context <: AbstractDict{Sym,Sym}
    parent::Union{Context,Nothing}
    data::OrderedDict{Sym,Sym}
    resolve_stack::Vector{Bool}
end
Context() = Context(nothing, OrderedDict{Sym,Sym}(), [true])
Context(parent::Union{Context,Nothing}, pairs::Pair{<:Sym,<:Sym}...) = Context(parent, OrderedDict(pairs...), [true])

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

resolving(ctx::Context) = ctx.resolve_stack[end]



const GLOBAL_CONTEXT = Context()
# Create a new context for user rules
const __ACTIVE_CONTEXT__ = Ref(Context(GLOBAL_CONTEXT))

macro __context__()
    return :(__ACTIVE_CONTEXT__[])
end

function query!(x::Sym, ctx::Context = __ACTIVE_CONTEXT__[])
    resolving(ctx) || return x

    for (key, val) in Iterators.reverse(ctx)
        m = match(x, key)
        if ismatch(m)
            substitute!(x, val, filter(y -> !(y isa Bool), m)...)
        end
    end

    ctx.parent === nothing || query!(x, ctx.parent)

    return x
end

set!(ctx::Context, x::Sym, val::Sym) = (setindex!(ctx, val, x); ctx)
unset!(ctx::Context, x::Sym) = (delete!(ctx, x); ctx)

##################################################
# @!
##################################################

macro !(args...)
    return _exec_dispatch(args...)
end

const TOKENS = (:clear!, :context, :set, :unset)

function _exec_dispatch(args...)
    x = nothing
    token = :pass
    options = Dict{Symbol,Bool}()

    N = length(args)
    for i in 1:N
        if args[i] in TOKENS
            token = args[i]
            x = i < N ? args[i + 1] : nothing
            break
        elseif i == N
            x = args[i]
        else
            options[args[i]] = true
        end
    end

    return _exec(x, token; options...)
end

function _exec(x, token::Symbol=:pass; options...)
    x = if token === :clear!
        if x === nothing
            :(empty!(@__context__().data))
        else
            error("expression following `clear!`: $x is not `nothing`")
        end
    elseif token === :context
        if x === nothing
            :(@__context__())
        else
            error("expression following `context`: $x is not `nothing`")
        end
    elseif token === :set
        if Meta.isexpr(x, :(=))
            key, val = x.args
            :(set!(
                @__context__,
                $(esc_sym(key)),
                $(esc_sym(val)))
              )
        else
            error("malformed `set` expression: missing `=`: $x")
        end
    elseif token === :unset
        :(unset!(@__context__, $(esc_sym(x))))
    else
        esc_sym(x)
    end

    x = get(options, :eval, false) ? :($(esc(:eval))($x)) : x
    x = get(options, :expr, false) ? :(expr($x)) : x
    x = get(options, :resolve, false) ? _resolve_wrap(x) : _unresolve_wrap(x)
    return x
end

function _resolve_wrap(ex)
    __return__ = gensym("return")
    return quote
        push!(@__context__().resolve_stack, true)
        $__return__ = nothing
        try
            $__return__ = $ex
        finally
            pop!(@__context__().resolve_stack)
            $__return__
        end
    end
end

function _unresolve_wrap(ex)
    __return__ = gensym("return")
    return quote
        push!(@__context__().resolve_stack, false)
        $__return__ = nothing
        try
            $__return__ = $ex
        finally
            pop!(@__context__().resolve_stack)
            $__return__
        end
    end
end

##################################################
# @scope
##################################################

macro scope(ex)
    return scope(nothing, ex)
end

macro scope(name, ex)
    return scope(name, ex)
end

function scope(name, x)
    __return__ = gensym("return")
    if name !== nothing
        prev = gensym("prev")
        newctx = :(($prev = __ACTIVE_CONTEXT__[]; $(esc(name))))
        oldctx = prev
    else
        newctx = :(Context(@__context__))
        oldctx = :(__ACTIVE_CONTEXT__[].parent)
    end

    ex = quote
        __ACTIVE_CONTEXT__[] = $newctx
        $__return__ = nothing
        try
            $__return__ = $(esc(x))
        finally
            __ACTIVE_CONTEXT__[] = $oldctx
            $__return__
        end
    end

    return ex
end
