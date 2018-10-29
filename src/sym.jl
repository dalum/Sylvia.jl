struct Sym{TAG}
    head::Symbol
    args::Tuple

    function Sym{TAG}(head::Symbol, args::Tuple) where {TAG}
        return new{TAG}(head, args)
    end
    function Sym{TAG}(head::Symbol, @nospecialize args...) where {TAG}
        return new{TAG}(head, args)
    end
end

Sym(x) = Sym{tagof(x)}(x)
Sym(x::Expr, m::Module = Base) = Sym{tagof(x)}(x, m)

Sym{TAG}(x) where {TAG} = Sym{TAG}(:object, x)
Sym{TAG}(x::T) where {TAG,T<:Number} = Sym{T}(:number, x)
Sym{TAG}(s::Symbol) where {TAG} = Sym{TAG}(:symbol, s)
Sym{TAG}(e::Expr, m::Module = Base) where {TAG} = Sym{TAG}(Val(e.head), e, m)

function Sym{TAG}(::Val{head}, e::Expr, m::Module) where {TAG,head}
    @assert(e.head === head)
    return Sym{TAG}(head, map(Sym, filter(!symignore, e.args))...)
end

function Sym{TAG}(::Val{:call}, e::Expr, m::Module) where {TAG}
    @assert e.head === :call
    args = copy(e.args)
    args[1] = Core.eval(m, args[1])
    for i in 2:length(args)
        args[i] = Sym(args[i])
    end
    return Sym{TAG}(:call, args...)
end

function Sym{T}(::Val{:(::)}, e::Expr, m::Module) where {T}
    @assert e.head === :(::)
    arg = e.args[1]
    @assert arg isa Symbol
    TAG = Core.eval(m, e.args[2])
    return Sym{TAG}(arg)
end

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

macro symbols(TAG::Symbol, xs::Symbol...)
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
# Utilities
##################################################

tagof(x::Sym{TAG}) where {TAG} = TAG
tagof(x::T) where {T} = T
tagof(x::Symbol) = Any
tagof(x::Expr) = Any
