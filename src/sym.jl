const DEFAULT_TAG = Any

mutable struct Sym{TAG}
    head::Symbol
    args::Vector{Any}

    function Sym{TAG}(head::Symbol, @nospecialize args...) where {TAG}
        return new{TAG}(head, collect(args))
    end

    function Sym{TAG}(::Val{:noargs}, head::Symbol, @nospecialize args...) where {TAG}
        return new{TAG}(head, collect(args))
    end
end

# Constructors

# Syms
Sym(x::Sym) = x
Sym{TAG}(x::Sym{TAG}) where {TAG} = x
Sym{TAG}(x::Sym) where {TAG} = Sym{TAG}(Val(:noargs), gethead(x), getargs(x)...)

# Generic
Sym(x) = Sym{tagof(x)}(x)
Sym{TAG}(x) where {TAG} = Sym{TAG}(:object, x)
Sym{TAG}(x::Type) where {TAG} = Sym{TAG}(:type, x)
Sym{TAG}(x::Symbol) where {TAG} = Sym{TAG}(:symbol, x)
Sym{TAG}(x::Function) where {TAG} = Sym{TAG}(:fn, x)

# Expressions
Sym(x::Expr) = Sym(Val(x.head), x)
Sym(::Val{head}, x::Expr) where {head} = Sym{tagof(x)}(Val(head), x)
Sym{TAG}(x::Expr) where {TAG} = convert(Sym{TAG}, Sym(x))

function Sym{TAG}(::Val{head}, x::Expr) where {TAG,head}
    @assert(x.head === head)
    args = map(Sym, filter(!symignore, x.args))
    return Sym{TAG}(Val(:noargs), head, args...)
end

function Sym(::Val{:call}, x::Expr)
    @assert x.head === :call
    args = map(Sym, filter(!symignore, x.args))
    f, args = args[1], args[2:end]
    return convert(Sym, f(args...))
end
Sym{TAG}(::Val{:call}, x::Expr) where {TAG} = convert(Sym{TAG}, Sym(Val(:call), x))

function Sym(::Val{:macrocall}, x::Expr)
    @assert x.head === :macrocall
    return Sym{DEFAULT_TAG}(Val(:noargs), :macrocall, x.args...)
end
Sym{TAG}(::Val{:macrocall}, x::Expr) where {TAG} = convert(Sym{TAG}, Sym(Val(:macrocall), x))

symignore(x) = false
symignore(::LineNumberNode) = true

# Make Syms callable

(f::Sym)(args...) = apply(f, map(arg -> convert(Sym, arg), args)...)
(f::Sym)(args::Sym...) = apply(f, args...)

##################################################
# Convenience methods
##################################################

macro S_str(str::String)
    return esc_sym(Meta.parse(str))
end

sym(xs...) = Tuple(sym(x) for x in xs)
sym(x) = Sym{DEFAULT_TAG}(x)
sym(::Type{TAG}, xs...) where {TAG} = Tuple(sym(TAG, x) for x in xs)
sym(::Type{TAG}, x) where {TAG} = Sym{TAG}(x)

macro sym(xs...)
    TAG = DEFAULT_TAG
    __return__ = Expr(:block)
    __return_tuple__ = Expr(:tuple)
    for x in xs
        if Meta.isexpr(x, :vect)
            if length(x.args) == 0
                TAG = DEFAULT_TAG
            elseif length(x.args) == 1
                TAG = esc(x.args[1])
            elseif length(x.args) > 1
                TAG = Expr(:curly, :Union, map(esc, x.args)...)
            else
                error("malformated tag: $x")
            end
            continue
        end
        @assert x isa Symbol
        x, symbol = esc(x), QuoteNode(x)
        push!(__return__.args, :($x = sym($TAG, $symbol)))
        push!(__return_tuple__.args, x)
    end
    push!(__return__.args, __return_tuple__)
    return __return__
end

##################################################
# Macro tools
##################################################

esc_sym(x; kwargs...) = Expr(:call, Sym, esc(x))
function esc_sym(x::Expr; interpolate=true, kwargs...)
    ex = interpolate ? Expr(:quote, unblock_interpolate(x; interpolate=interpolate, kwargs...)) : QuoteNode(x)
    return Expr(:call, Sym, ex)
end

unblock_interpolate(x; kwargs...) = x
unblock_interpolate(x::Symbol; interpolate=true, kwargs...) = interpolate ? Expr(:$, x) : x
function unblock_interpolate(x::QuoteNode; interpolate=true, kwargs...)
    x = Expr(:call, Sym, x)
    return interpolate ? Expr(:$, x) : x
end

function unblock_interpolate(x::Expr; kwargs...)
    return unblock_interpolate(Val(x.head), x; kwargs...)
end

function unblock_interpolate(::Val{head}, x::Expr; kwargs...) where {head}
    @assert x.head === head
    return striplines(unblock(Expr(head, map(arg -> unblock_interpolate(arg; kwargs...), x.args)...)))
end

function unblock_interpolate(::Val{:quote}, x::Expr; interpolate=true, kwargs...)
    @assert x.head === :quote
    return interpolate ? Expr(:$, x) : x
end

function unblock_interpolate(::Val{:(=)}, x::Expr; kwargs...)
    @assert x.head === :(=)
    return Expr(:(=), x.args[1], unblock_interpolate(x.args[2]; kwargs...))
end

function unblock_interpolate(::Val{:ref}, x::Expr; kwargs...)
    @assert x.head === :ref
    return Expr(:ref, map(arg -> unblock_interpolate(arg; kwargs...), x.args)...)
end

function unblock_interpolate(::Val{:call}, x::Expr; interpolate=true, kwargs...)
    @assert x.head === :call
    x.args = map(arg -> unblock_interpolate(arg; interpolate=false, kwargs...), x.args)
    if interpolate
        ex = :(applicable($(x.args...)) ? $x : Core._expr(:call, $(x.args...)))
        return Expr(:$, ex)
    else
        return x
    end
end

function unblock_interpolate(::Val{:curly}, x::Expr; interpolate=true, kwargs...)
    @assert x.head === :curly
    return interpolate ? Expr(:$, x) : x
end

function unblock_interpolate(::Val{:macrocall}, x::Expr; interpolate=true, kwargs...)
    @assert x.head === :macrocall
    return interpolate ? Expr(:$, x) : x
end

function unblock_interpolate(::Val{:(::)}, x::Expr; interpolate=true, type_assert=false, kwargs...)
    @assert x.head === :(::)
    if !type_assert
        x = unblock_interpolate(
            Expr(:call, sym, x.args[2], x.args[1]);
            interpolate=interpolate,
            type_assert=type_assert,
            kwargs...
        )
        return x
    end
    x.args = map(
        arg -> unblock_interpolate(
            arg;
            interpolate=interpolate,
            type_assert=type_assert,
            kwargs...),
        x.args
    )
    return interpolate ? Expr(:$, x) : x
end

##################################################
# Comparison
##################################################

Base.isequal(x::Sym, y::Sym) = false
function Base.isequal(x::Sym{TAG}, y::Sym{TAG}) where {TAG}
    return gethead(x) === gethead(y) && isequal(getargs(x), getargs(y))
end

##################################################
# Base extensions
##################################################

Base.hash(x::Sym, h::UInt) = hash((gethead(x), getargs(x)), h)
Base.copy(x::Sym{TAG}) where {TAG} = Sym{TAG}(gethead(x), copy(getargs(x))...)
Base.deepcopy(x::Sym{TAG}) where {TAG} = Sym{TAG}(gethead(x), deepcopy(getargs(x))...)
Base.iterate(x::Sym) = (x[1], 2)
Base.iterate(x::Sym, i) = length(x) + 1 === i ? nothing : (x[i], i + 1)

##################################################
# Utilities
##################################################

isatomic(x::Sym) = hashead(x, (:symbol, :fn, :function, :(->), :type, :object))

@inline _typeof(x::Sym)::Sym{Type} = Sym(typeof)(x)

@inline tagof(x::Sym{TAG}) where {TAG} = TAG
@inline tagof(x::T) where {T} = T
@inline tagof(x::QuoteNode) = typeof(x.value)
@inline tagof(x::Symbol) = DEFAULT_TAG
@inline tagof(x::Expr) = tagof(Val(x.head), x)
@inline tagof(::Val, x::Expr) = DEFAULT_TAG
@inline tagof(::Val{:function}, x::Expr) = Function
@inline tagof(::Val{:(->)}, x::Expr) = Function

@inline gethead(x) = getfield(x, :head)
@inline sethead!(x, val) = (setfield!(x, :head, val); x)
@inline hashead(x, head::Symbol) = gethead(x) === head
@inline hashead(x, heads::Union{Tuple,AbstractVector,AbstractSet}) = any(head -> gethead(x) === head, heads)
@inline hashead(heads) = (x::Sym) -> hashead(x, heads)

@inline getargs(x) = getfield(x, :args)
@inline getargs(x, idx) = getfield(x, :args)[idx]
@inline getargs(x, ::Nothing) = Any[]
@inline setargs!(x, val) = (setfield!(x, :args, val); x)
@inline firstarg(x) = first(getargs(x))
@inline tailargs(x) = view(getargs(x), 2:length(getargs(x)))
