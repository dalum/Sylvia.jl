module Sylvia

export @S_str, @rule, @symbols, @λ

const BASE_FUNCTION_SYMBOLS =
    (:+, :-, :!, :exp, :log, :sqrt, :inv,
     :cos, :sin, :tan, :sec, :csc, :cot, :cosh, :sinh, :tanh, :sech, :csch, :coth,
     :acos, :asin, :atan, :asec, :acsc, :acot, :acosh, :asinh, :atanh, :asech, :acsch, :acoth)

const SymbolOrExpr = Union{Symbol,Expr}

struct Symbolic{T,HASH}
    data::T
end
Symbolic{T}(data) where {T} = Symbolic{T,hash(data)}(data)
Symbolic(data::T) where {T} = Symbolic{T,hash(data)}(data)
Symbolic(data::T, h::UInt) where {T} = Symbolic{T,h}(data)

macro S_str(str::String)
    Symbolic(Meta.parse(str))
end

macro symbols(xs...)
    ret = Expr(:block)
    tup = Expr(:tuple)
    for x in xs
        @assert x isa Symbol
        push!(ret.args, Expr(:(=), esc(x), :(Symbolic($(QuoteNode(x))))))
        push!(tup.args, esc(x))
    end
    push!(ret.args, tup)
    return ret
end

Base.show(io::IO, x::Symbolic) = print(io, "$(showify(x))")
Base.hash(::Symbolic{T,HASH}) where {T,HASH} = HASH

value(x) = x
value(x::Symbolic) = x.data

getsymbols(x::Symbolic) = getsymbols(value(x))
getsymbols(::Number) = Set(Symbol[])
getsymbols(x::Symbol) = Set(Symbol[x])
getsymbols(A::AbstractArray) = mapreduce(getsymbols, union, A)
getsymbols(x::Expr) = getsymbols(Val{x.head}, x.args)
getsymbols(::Type{<:Val}, args) = mapreduce(getsymbols, union, args)
getsymbols(::Type{Val{:call}}, args) = mapreduce(getsymbols, union, args[2:end])

expressify(a) = a # Catch all
expressify(a::Expr) = Expr(a.head, expressify.(a.args)...)
expressify(a::Symbolic) = expressify(value(a))
expressify(v::AbstractVector) = Expr(:vect, expressify.(v)...)
expressify(A::AbstractMatrix) = Expr(:vcat, mapslices(x -> Expr(:row, expressify.(x)...), A, dims=2)...)

showify(a) = a # Catch all
showify(a::Expr) = Expr(a.head, showify.(a.args)...)
showify(a::Symbolic) = showify(value(a))

macro λ(expr)
    body = expressify(Base.eval(__module__, expr))
    symbols = sort(collect(getsymbols(body)))
    return esc(Expr(:(->), Expr(:tuple, symbols...), body))
end

##################################################
# Promotion/conversion
##################################################

Base.convert(::Type{Symbolic}, a::Symbolic) = a
Base.convert(::Type{Symbolic{T}}, a::Symbolic) where {T} = Symbolic{T}(value(a))
Base.convert(::Type{Symbolic{T,HASH}}, a::Symbolic) where {T,HASH} = Symbolic{T,HASH}(value(a))

Base.convert(::Type{Symbolic}, a) = Symbolic(a)
Base.convert(::Type{Symbolic{T}}, a) where {T} = Symbolic{T}(a)
Base.convert(::Type{Symbolic{T,HASH}}, a) where {T,HASH} = Symbolic{T,HASH}(a)

Base.convert(::Type{AbstractArray{Symbolic{T,HASH}}}, A::AbstractArray) where {T,HASH} = Base.convert(AbstractArray{Symbolic}, A)

Base.promote_rule(::Type{Symbolic{T,HASH}}, ::Type{Any}) where {T,HASH} = Symbolic
function Base.promote_rule(::Type{Symbolic{T,HASH}}, ::Type{S}) where {T,HASH,S}
    Q = promote_type(T,S)
    return isconcretetype(Q) ? Symbolic{Q} : Symbolic
end

##################################################
# Rules and assumptions
##################################################

macro rule(expr::Expr)
    return rule(expr)
end

function rule(expr)
    head, args = expr.head, expr.args
    @assert head === :(-->)
    lhs, rhs = args
    @assert lhs isa Expr && lhs.head === :call
    MODULE_= @__MODULE__
    unique_symbols = Set()
    new_lhs = Expr(:where, lhs)
    fnsymbol = lhs.args[1]
    if lhs.args[1] in BASE_FUNCTION_SYMBOLS
        fnsymbol = Expr(:., :Base, QuoteNode(fnsymbol))
    end
    lhs.args[1] = esc(fnsymbol)
    for i in 2:length(lhs.args)
        if lhs.args[i] isa Expr && lhs.args[i].head === :(...)
            symbol = Symbol(lhs.args[i].args[1])
            T = Symbol("T#$symbol")
            lhs.args[i].args[1] = Expr(:(::), esc(Symbol(symbol, "s")), T)
        elseif lhs.args[i] isa Symbol || lhs.args[i] isa Number
            symbol = lhs.args[i]
            T = Symbol("T#$symbol")
            if !(symbol in unique_symbols)
                if symbol isa Number
                    lhs.args[i] = Expr(:(::), T)
                    push!(new_lhs.args, Expr(:(<:), T, Expr(:call, :_typeof, Expr(:call, :Symbolic, esc(symbol)))))
                else
                    lhs.args[i] = Expr(:(::), esc(symbol), T)
                    push!(new_lhs.args, Expr(:(<:), T, Expr(:call, :_typeof, esc(symbol))))
                end
                push!(unique_symbols, symbol)
            else
                lhs.args[i] = Expr(:(::), T)
            end
        end
    end
    unique!(new_lhs.args)
    return Expr(:(=), new_lhs, Expr(:block, Expr(:meta, :inline), esc(rhs)))
end

@inline _typeof(x) = Base.typeof(x)

##################################################
# Expression manipulations
##################################################

split(op, x::Symbolic)::Vector{Symbolic} = [x]
function split(op, x::Symbolic{Expr})::Vector{Symbolic}
    val = value(x)
    if val.head == :call && val.args[1] == op
        return val.args[2:end]
    end
    return [x]
end

join(op, xs) = join(op, xs, hash((hash(eval(:(Base.$op))), hash.(xs)...)))
function join(op, xs, h)
    return Symbolic(Expr(:call, op, xs...), h)
end

##################################################
# Wildcards
##################################################

const Wildcard{T} = Symbolic{T,UInt(0)}
Wildcard() = Wildcard{Any}(Symbol("#Any#"))
Wildcard{Symbol}() = Wildcard{Symbol}(Symbol("#Symbol#"))
Wildcard{SymbolOrExpr}() = Wildcard{SymbolOrExpr}(Symbol("#SymbolOrExpr#"))
Wildcard{T}() where {T<:Number} = Wildcard{T}(one(T))

showify(::Wildcard{T}) where {T<:Number} = Symbol("#$T#")

@inline _typeof(::Wildcard{T}) where {T} = Symbolic{<:T}

##################################################
# Base
##################################################

# One-arg operators
for op in (:+, :-, :!, :exp, :log, :sqrt, :inv,
           :cos, :sin, :tan, :sec, :csc, :cot, :cosh, :sinh, :tanh, :sech, :csch, :coth,
           :acos, :asin, :atan, :asec, :acsc, :acot, :acosh, :asinh, :atanh, :asech, :acsch, :acoth)
    name, opsymbol = :(Base.$op), QuoteNode(op)
    @eval function $name(a::Symbolic)
        return join($opsymbol, (a,))
    end
    @eval function $name(a::Wildcard)
        return join($opsymbol, (a,))
    end
end

# Two-arg operators
for op in (:-, :/, :\, ://, :^, :÷, :(==), :&, :|)
    name, opsymbol = :(Base.$op), QuoteNode(op)
    @eval $name(a::Symbolic, b) = $name(promote(a, b)...)
    @eval $name(a, b::Symbolic) = $name(promote(a, b)...)
    @eval function $name(a::Symbolic, b::Symbolic)
        return join($opsymbol, (a, b))
    end
    @eval function $name(a::Wildcard, b::Wildcard)
        return join($opsymbol, (a, b))
    end
end

# Multi-arg operators
for op in (:+, :*)
    name, opsymbol = :(Base.$op), QuoteNode(op)
    @eval $name(a::Symbolic, b) = $name(promote(a, b)...)
    @eval $name(a, b::Symbolic) = $name(promote(a, b)...)
    @eval function $name(a::Symbolic, b::Symbolic)
        xs = vcat(split($opsymbol, a), split($opsymbol, b))
        return join($opsymbol, xs)
    end
    @eval function $name(a::Wildcard, b::Wildcard)
        xs = vcat(split($opsymbol, a), split($opsymbol, b))
        return join($opsymbol, xs)
    end
end

##################################################
# Zeros and ones
##################################################

const Zero{T} = Symbolic{T,hash(0)}
Zero{Symbol}(x) = Zero{Bool}(x)
Zero{Expr}(x) = Zero{Bool}(x)
Zero() = Zero{Bool}(0)
Zero(T) = Zero{T}(0)
Zero(T, S) = Zero{promote_type(T, S)}(0)
Zero(T, S, Qs...) = Zero{promote_type(T, S, Qs...)}(0)

const One{T} = Symbolic{T,hash(1)}
One{Symbol}(x) = One{Bool}(x)
One{Expr}(x) = One{Bool}(x)
One() = One{Bool}(1)
One(T) = One{T}(1)
One(T, S) = One{promote_type(T, S)}(1)
One(T, S, Qs...) = One{promote_type(T, S, Qs...)}(1)

showify(::Zero) = Symbol("0")
showify(::One) = Symbol("1")

@inline Base.zero(::Symbolic) = Zero()
@inline Base.zero(::Symbolic{T}) where {T<:Number} = Zero{T}()
@inline Base.zero(::Type{<:Symbolic}) = Zero()
@inline Base.zero(::Type{<:Symbolic{T}}) where {T<:Number} = Zero{T}()

@inline Base.one(::Symbolic) = One()
@inline Base.one(::Symbolic{T}) where {T<:Number} = One{T}()
@inline Base.one(::Type{<:Symbolic}) = One()
@inline Base.one(::Type{<:Symbolic{T}}) where {T<:Number} = One{T}()

@inline Base.oneunit(::Symbolic) = One()
@inline Base.oneunit(::Symbolic{T}) where {T<:Number} = One{T}()
@inline Base.oneunit(::Type{<:Symbolic}) = One()
@inline Base.oneunit(::Type{<:Symbolic{T}}) where {T<:Number} = One{T}()

@inline Base.iszero(::Symbolic) = false
@inline Base.iszero(x::Symbolic{<:Number}) = iszero(value(x))
@inline Base.iszero(::Zero) = true
@inline Base.iszero(::One) = false

@inline Base.isone(::Symbolic) = false
@inline Base.isone(x::Symbolic{<:Number}) = isone(value(x))
@inline Base.isone(::Zero) = false
@inline Base.isone(::One) = true

@inline Base.isinf(::Symbolic) = false
@inline Base.isinf(x::Symbolic{<:Number}) = isinf(value(x))

##################################################
# Default rules
##################################################

const x = Wildcard{SymbolOrExpr}(:x)

@rule Base.:(==)(::Zero, ::Zero) --> true
@rule Base.:(==)(::One, ::One) --> true
@rule Base.:(==)(::Zero, ::One) --> false
@rule Base.:(==)(::One, ::Zero) --> false

@rule Base.:-(x, ::Zero) --> x
@rule Base.:*(::One, x) --> x
@rule Base.:*(x, ::One) --> x
@rule Base.:\(::One, x) --> x
@rule Base.:/(x, ::One) --> x

@rule Base.:-(::Zero, x) --> -x

@rule Base.:-(x, x) --> zero(x)
@rule Base.:*(::Zero, x) --> zero(x)
@rule Base.:*(x, ::Zero) --> zero(x)

@rule Base.:+(x, x) --> 2x
@rule Base.:+(x, x, x...) --> (2 + length(xs))*x

@rule Base.:*(x, x) --> x^2
@rule Base.:*(x, x, x...) --> x^(2 + length(xs))

@inline Base.:+(::Zero{T}, ::Zero{S}) where {T,S} = Zero(T, S)
@inline Base.:-(::Zero{T}, ::Zero{S}) where {T,S} = Zero(T, S)
@inline Base.:*(::Zero{T}, ::Zero{S}) where {T,S} = Zero(T, S)

@inline Base.:-(::One{T}, ::One{S}) where {T,S} = Zero(T, S)
@inline Base.:*(::One{T}, ::One{S}) where {T,S} = One(T, S)
@inline Base.:/(::One{T}, ::One{S}) where {T,S} = One(T, S)
@inline Base.:\(::One{T}, ::One{S}) where {T,S} = One(T, S)

@inline Base.:-(::Zero{T}, ::One{S}) where {T,S} = One(T, S)
@inline Base.:-(::One{T}, ::Zero{S}) where {T,S} = One(T, S)
@inline Base.:*(::Zero{T}, ::One{S}) where {T,S} = Zero(T,S)
@inline Base.:*(::One{T}, ::Zero{S}) where {T,S} = Zero(T,S)
@inline Base.:/(::Zero{T}, ::One{S}) where {T,S} = Zero(T,S)
@inline Base.:\(::One{T}, ::Zero{S}) where {T,S} = Zero(T,S)

@inline Base.:/(a::T, b::T) where {T<:Symbolic} = (!iszero(a) && !isinf(b)) ? one(a) : join(:/, (a, b))
@inline Base.:\(a::T, b::T) where {T<:Symbolic} = (!iszero(b) && !isinf(a)) ? one(b) : join(:\, (a, b))

end # module
