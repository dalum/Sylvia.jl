mutable struct Sym{TAG}
    head::Symbol
    args::Vector{Any}

    function Sym{TAG}(head::Symbol, @nospecialize args...) where {TAG}
        return new{TAG}(head, collect(args))
    end
end

# Constructors

# Syms
Sym(x::Sym) = x
Sym{TAG}(x::Sym{TAG}) where {TAG} = x
Sym{TAG}(x::Sym) where {TAG} = Sym{TAG}(gethead(x), getargs(x)...)

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
    return Sym{TAG}(head, map(Sym, filter(!symignore, x.args))...)
end

function Sym(::Val{:call}, x::Expr)
    @assert x.head === :call
    args = map(Sym, filter(!symignore, x.args))
    f, args = args[1], args[2:end]
    return convert(Sym, f(args...))
end
Sym{TAG}(::Val{:call}, x::Expr) where {TAG} = convert(Sym{TAG}, Sym(Val(:call), x))

function Sym(::Val{:(::)}, x::Expr)
    @assert x.head === :(::)
    arg, TAG = x.args
    return Sym{TAG}(arg)
end
Sym{TAG}(::Val{:(::)}, x::Expr) where {TAG} = convert(Sym{TAG}, Sym(Val(:(::)), x))

function Sym(::Val{:function}, x::Expr)
    @assert x.head === :function
    fn, body = x.args
    return Sym{Function}(:function, Sym(fn), Sym(body))
end
Sym{TAG}(::Val{:function}, x::Expr) where {TAG} = convert(Sym{TAG}, Sym(Val(:function), x))

function Sym(::Val{:macrocall}, x::Expr)
    @assert x.head === :macrocall
    return Sym{Any}(:macrocall, x.args...)
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
sym(x) = Sym{Number}(x)
sym(TAG::Type, xs...) = Tuple(sym(TAG, x) for x in xs)
sym(TAG::Type, x) = Sym{TAG}(x)

macro sym(xs::Symbol...)
    symbols = map(QuoteNode, xs)
    xs = map(esc, xs)
    if length(xs) > 1
        return :(($(xs...),) = sym($(symbols...)))
    else
        return :($(xs...) = sym($(symbols...)))
    end
end

macro sym(TAG::Expr, xs::Symbol...)
    @assert TAG.head === :(::)
    TAG, x = TAG.args
    xs = (x, xs...)
    symbols = map(QuoteNode, xs)
    xs = map(esc, xs)
    if length(xs) > 1
        return :(($(xs...),) = sym($(esc(TAG)), $(symbols...)))
    else
        return :($(xs...) = sym($(esc(TAG)), $(symbols...)))
    end
end

##################################################
# Macro tools
##################################################

esc_sym(x) = Expr(:call, :Sym, esc(x))
function esc_sym(x::Expr)
    return Expr(:call, :Sym, Expr(:quote, unblock_interpolate(x)))
end

unblock_interpolate(x) = x
unblock_interpolate(x::Symbol) = Expr(:$, x)

function unblock_interpolate(x::Expr)
    return unblock_interpolate(Val(x.head), x)
end

function unblock_interpolate(::Val{head}, x::Expr) where {head}
    @assert x.head === head
    return unblock(Expr(head, map(unblock_interpolate, x.args)...))
end

function unblock_interpolate(::Val{:call}, x::Expr)
    @assert x.head === :call
    return Expr(
        :$,
        :(applicable($(x.args...)) ? $x : Core._expr(:call, $(x.args...)))
    )
end

function unblock_interpolate(::Val{:curly}, x::Expr)
    @assert x.head === :curly
    return Expr(:$, x)
end

function unblock_interpolate(::Val{:macrocall}, x::Expr)
    @assert x.head === :macrocall
    return Expr(:$, x)
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

isatomic(x::Sym) = hashead(x, (:symbol, :function, :type, :object))

@inline tagof(x::Sym{TAG}) where {TAG} = TAG
@inline tagof(x::T) where {T} = T
@inline tagof(x::QuoteNode) = typeof(x.value)
@inline tagof(x::Symbol) = Any
@inline tagof(x::Expr) = Any

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
