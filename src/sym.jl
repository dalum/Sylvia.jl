mutable struct Sym{TAG}
    head::Symbol
    args::Vector{Any}

    function Sym{TAG}(head::Symbol, @nospecialize args...) where {TAG}
        return new{TAG}(head, collect(args))
    end
end

Sym(x) = Sym{tagof(x)}(x)
Sym(x::Expr, m::Module = Base) = Sym{tagof(x)}(x, m)
Sym{TAG}(x) where {TAG} = Sym{TAG}(:object, x)
Sym{TAG}(x::Type) where {TAG} = Sym{TAG}(:type, x)
Sym{TAG}(x::Symbol) where {TAG} = Sym{TAG}(:symbol, x)
Sym{TAG}(x::Function) where {TAG} = Sym{TAG}(:function, x)
Sym{TAG}(e::Expr, m::Module = Base) where {TAG} = Sym{TAG}(Val(e.head), e, m)

function Sym{TAG}(::Val{head}, e::Expr, m::Module) where {TAG,head}
    @assert(e.head === head)
    return Sym{TAG}(head, map(Sym, filter(!symignore, e.args))...)
end

function Sym{TAG}(::Val{:call}, e::Expr, m::Module) where {TAG}
    @assert e.head === :call
    args = copy(e.args)
    args[1] = Sym(Core.eval(m, args[1]))
    for i in 2:length(args)
        args[i] = Sym(args[i])
    end
    return apply(args...)
end

function Sym{T}(::Val{:(::)}, e::Expr, m::Module) where {T}
    @assert e.head === :(::)
    arg = e.args[1]
    @assert arg isa Symbol
    TAG = Core.eval(m, e.args[2])
    return Sym{TAG}(arg)
end

(f::Sym)(args...) = apply(f, map(arg -> convert(Sym, arg), args)...)
(f::Sym)(args::Sym...) = apply(f, args...)

symignore(x) = false
symignore(::LineNumberNode) = true

##################################################
# Convenience methods
##################################################

macro S_str(str::String)
    e = Meta.parse(str)
    if e isa Expr
        return Sym(e, __module__)
    else
        return Sym(e)
    end
end

macro S_str(str::String, tag::String)
    e = Meta.parse(str)
    TAG = Core.eval(__module__, Meta.parse(tag))
    if e isa Expr
        return Sym{TAG}(e, __module__)
    else
        return Sym{TAG}(e)
    end
end

symbols(TAG::Type, xs::Symbol...) = Tuple(Sym{TAG}(x) for x in xs)

macro symbols(TAG, xs::Symbol...)
    ret = Expr(:block)
    tup = Expr(:tuple)
    for x in xs
        push!(ret.args, Expr(:(=), esc(x), :(Sym{$(esc(TAG))}($(QuoteNode(x))))))
        push!(tup.args, esc(x))
    end
    push!(ret.args, tup)
    return ret
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
