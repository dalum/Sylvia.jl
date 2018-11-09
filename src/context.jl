mutable struct Context <: AbstractDict{Sym,Any}
    data::OrderedDict{Sym,Any}
    resolve::Bool
end
Context(pairs::Pair{<:Sym,<:Any}...) = Context(OrderedDict(pairs...), true)

Base.length(ctx::Context) = length(ctx.data)
Base.iterate(ctx::Context) = length(ctx) > 0 ? (keys(ctx)[1] => values(ctx)[1], 2) : nothing
Base.iterate(ctx::Context, x) = x <= length(ctx) ? (keys(ctx)[x] => values(ctx)[x], x + 1) : nothing
Base.getindex(ctx::Context, key) = getindex(ctx.data, key)
Base.setindex!(ctx::Context, val, key) = setindex!(ctx.data, val, key)
Base.delete!(ctx::Context, key) = delete!(ctx.data, key)

Base.keys(ctx::Context) = reverse(collect(keys(ctx.data)))
Base.values(ctx::Context) = reverse(collect(values(ctx.data)))

const GLOBAL_CONTEXT_STACK = Context[Context()]

macro __CONTEXT__()
    return :(GLOBAL_CONTEXT_STACK[end])
end

function query(x::Sym)
    for ctx in reverse(GLOBAL_CONTEXT_STACK)
        r = query(ctx, x)
        ismissing(r) || return r
    end
    return missing
end
function query(ctx::Context, x::Sym)::Union{typeof(x), Missing}
    if ctx.resolve
        for (key, val) in ctx
            m = match(x, key)
            if ismatch(m)
                return substitute(val, filter(y -> !(y isa Bool), m)...)
            end
        end
    end
    return missing
end

set!(ctx::Context, x::Sym{T}, val::Union{Sym{T}, T}) where {T} = setindex!(ctx, val, x)
macro set!(ex::Expr)
    @assert Meta.isexpr(ex, :call) && ex.args[1] === :(=>)
    x, val = ex.args[2:end]
    return quote
        @__CONTEXT__().resolve = false
        set!(@__CONTEXT__, $(esc(x)), $(esc(val)))
        @__CONTEXT__().resolve = true
    end
end

unset!(ctx::Context, x::Sym) = delete!(ctx, x)
macro unset!(x)
    return quote
        @__CONTEXT__().resolve = false
        unset!(@__CONTEXT__, $(esc(x)))
        @__CONTEXT__().resolve = true
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
