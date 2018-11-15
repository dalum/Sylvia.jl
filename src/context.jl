mutable struct Context <: AbstractDict{Sym,Sym}
    parent::Union{Context,Nothing}
    data::OrderedDict{Sym,Sym}
    resolve::Bool
end
Context(parent::Union{Context,Nothing}, pairs::Pair{<:Sym,<:Sym}...) = Context(parent, OrderedDict(pairs...), true)

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

const GLOBAL_CONTEXT = Context(nothing)
const ACTIVE_CONTEXT = Ref(GLOBAL_CONTEXT)

macro __context__()
    return :(ACTIVE_CONTEXT[])
end

function query!(x::Sym, ctx::Context = ACTIVE_CONTEXT[])
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

set!(ctx::Context, x::Sym, val::Sym) = setindex!(ctx, val, x)
unset!(ctx::Context, x::Sym) = delete!(ctx, x)

##################################################
# @!
##################################################

macro !(x)
    ex = if Meta.isexpr(x, :(=))
        key, val = x.args
        :(set!(@__context__, $(esc_sym(key)), $(esc_sym(val))))
    elseif x === :clear!
        :(empty!(@__context__().data))
    else
        esc_sym(x)
    end
    return _unresolve_wrap(ex)
end

macro !(option::Symbol, x)
    ex = if option === :unset
        :(unset!(@__context__, $(esc_sym(x))))
    elseif option === :eval
        :($(esc(:eval))($(esc_sym(x))))
    elseif option === :expr
        esc_sym(x, interpolate=false)
    elseif option === :resolve
        return _resolve_wrap(esc_sym(x))
    else
        esc_sym(x)
    end
    return _unresolve_wrap(ex)
end

function _resolve_wrap(ex)
    __return__ = gensym("return")
    return quote
        if !@__context__().resolve
            $__return__ = nothing
            try
                @__context__().resolve = true
                $__return__ = $ex
            finally
                @__context__().resolve = false
                $__return__
            end
        else
            $ex
        end
    end
end

function _unresolve_wrap(ex)
    __return__ = gensym("return")
    return quote
        if @__context__().resolve
            $__return__ = nothing
            try
                @__context__().resolve = false
                $__return__ = $ex
            finally
                @__context__().resolve = true
                $__return__
            end
        else
            $ex
        end
    end
end

##################################################
# @scope
##################################################

macro scope(ex)
    return scope(:nothing, ex)
end

macro scope(option::Symbol, ex)
    return scope(option, ex)
end

function scope(option::Symbol, x)
    __return__ = gensym("return")
    ex = quote
        ACTIVE_CONTEXT[] = Context(@__context__)
        $__return__ = nothing
        try
            $__return__ = $(esc(x))
        finally
            ACTIVE_CONTEXT[] = ACTIVE_CONTEXT[].parent
            $__return__
        end
    end

    option === :suspend && return _unresolve_wrap(ex)
    return ex
end
