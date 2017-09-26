#__precompile__(true)

module Sylvia

export @S_str, @def, @λ, @symbols, @symbols!, @symbols!!

const Properties = Dict{Symbol,Any}

struct Symbolic{T, C}
    value::T
    #properties::Properties
    Symbolic{T, C}(value, properties) where {T, C} = new(value) #new(value, properties)
end

const Namespace = Dict{Symbol, Symbolic{Symbol}}
const GLOBAL_NAMESPACE = Namespace()

DEFAULT_SYMBOL_TYPE = Number
DEFAULT_EXPR_TYPE = Number

"""
    Symbolic([C,] value[, properties])
"""
Symbolic(::Type{C}, value, properties) where {C} = Symbolic{typeof(value), C}(value, properties)
Symbolic(::Type{C}, value) where {C} = Symbolic(C, value, Properties())
Symbolic(value) = Symbolic(value, Properties())
Symbolic(value, properties::Properties) = Symbolic(typeof(value), value, properties)
Symbolic(value::Symbol, properties::Properties) = Symbolic(DEFAULT_SYMBOL_TYPE, value, properties)
Symbolic(value::Expr, properties::Properties) = Symbolic(DEFAULT_EXPR_TYPE, value, properties)

"""
    symbol([C,] x; namespace=GLOBAL_NAMESPACE, safe=true)
"""
symbol(x) = Symbolic(x)

function symbol(::Type{C}, x::Symbol, properties::Properties; namespace::Namespace = GLOBAL_NAMESPACE, safe::Bool = true) where C
    if safe && x in keys(namespace)
        return namespace[x]
    end
    return namespace[x] = Symbolic{typeof(x), C}(x, properties)
end
symbol(x::Symbol; kw...) = symbol(DEFAULT_SYMBOL_TYPE, x; kw...)
symbol(::Type{C}, x::Symbol; kw...) where {C} = symbol(C, x, Properties(); kw...)
symbol(x::Symbol, properties::Properties; kw...) = symbol(DEFAULT_SYMBOL_TYPE, x, properties; kw...)


macro S_str(str)
    symbol(parse(str))
end

"""
    @symbols
"""
macro symbols(exprs...)
    _symbols(exprs...; safe=true)
end

macro symbols!(exprs...)
    _symbols(exprs...; safe=false)
end

macro symbols!!(exprs...)
    empty!(GLOBAL_NAMESPACE)
    _symbols(exprs...; safe=false)
end

function _symbols(exprs...; namespace::Symbol = :GLOBAL_NAMESPACE, safe::Bool = true)
    T = DEFAULT_SYMBOL_TYPE
    properties = :(Properties())
    retexpr = Expr(:block)
    for expr in exprs
        if expr isa Symbol
            push!(retexpr.args, Expr(:(=), esc(expr), :(symbol($T, $(Expr(:quote, expr)), $properties; namespace=$namespace, safe=$safe))))
        elseif expr isa Expr && expr.head === :vect && length(expr.args) >= 1
            T = esc(expr.args[1])
            properties = Expr(:call, :Properties, expr.args[2:end]...)
        else
            error("invalid type annotation or symbol: $expr")
        end
    end
    push!(retexpr.args, esc(:nothing))
    return retexpr
end

SymbolOrExpr{T} = Union{Symbolic{Symbol,T}, Symbolic{Expr,T}}
Class{T} = Symbolic{<:Any,T}

### Value extraction
value(x) = x
value(x::Symbolic) = x.value
properties(x::Symbolic) = x.properties

### Promotion rules
Base.convert(::Type{Any}, x::Symbolic) = x
Base.convert(::Type{Symbolic}, x) = Symbolic(x)
Base.convert(::Type{Symbolic{T,C} where T}, x) where {C} = Symbolic(C, x)
Base.convert(::Type{Symbolic{T,C} where T}, x::Symbolic{T2,C}) where {T2,C} = Symbolic(C, x.value)
Base.convert(::Type{Symbolic{T,C}}, x) where {T,C} = Symbolic(C, convert(T, x))
Base.convert(::Type{Symbolic}, x::Symbolic{T,C} where {T,C}) = x
Base.convert(::Type{Symbolic{T}}, x::Symbolic{T,C}) where {T,C} = x
Base.convert(::Type{Symbolic{T,C1}}, x::Symbolic{T,C2}) where {T,C1,C2} = Symbolic(C1, x.value)
Base.convert(::Type{Symbolic{T1}}, x::Symbolic{T2,C}) where {T1,T2,C} = Symbolic(C, convert(T1, x.value))
Base.convert(::Type{Symbolic{T1,C}}, x::Symbolic) where {T1,C} = Symbolic(C, convert(T1, x.value))
Base.convert(::Type{T1}, x::Symbolic{T2}) where {T1,T2} = convert(T1, x.value)

Base.convert(::Type{AbstractArray{Symbolic{T1},N}}, A::AbstractArray{T2,N}) where {T1<:Number,T2,N} = Base.convert(AbstractArray{Symbolic,N}, A)

Base.promote_rule(::Type{Symbolic}, ::Type{<:Any}) = Symbolic
Base.promote_rule(::Type{Symbolic{T}}, ::Type{<:Any}) where T = Symbolic

### Array stuff
# Base.similar(a::Vector{<:Symbolic})                                    = Vector{Symbolic}(size(a,1))
# Base.similar(a::Matrix{<:Symbolic})                                    = Matrix{Symbolic}(size(a,1), size(a,2))
# Base.similar(a::Vector{T}, S::Type{Symbolic{T}}) where {T}             = Vector{Symbolic}(size(a,1))
# Base.similar(a::Matrix{T}, S::Type{Symbolic{T}}) where {T}             = Matrix{Symbolic}(size(a,1), size(a,2))
# Base.similar(a::Array{T}, m::Int) where {T<:Symbolic}                  = Array{Symbolic,1}(m)
# Base.similar(a::Array, ::Type{Symbolic{T}}, dims::Dims{N}) where {T,N} = Array{Symbolic,N}(dims)
# Base.similar(a::Array{T}, dims::Dims{N}) where {T<:Symbolic,N}         = Array{Symbolic,N}(dims)

show_prefix = ""
show_suffix = ""
function setshow(prefix, suffix)
    global show_prefix, show_suffix
    show_prefix = prefix
    show_suffix = suffix
    println("Symbolic types printed as print(Symbolic(x)) -> $(show_prefix)x$(show_suffix)")
end

Base.show(io::IO, x::Symbolic) = print(io, "$show_prefix$(expressify(x))$show_suffix")

Base.zero(x::Symbolic{T}) where T = Symbolic(zero(x.value))
Base.one(x::Symbolic{T}) where T = Symbolic(one(x.value))
Base.oneunit(x::Symbolic{T}) where T = Symbolic(oneunit(x.value))
Base.zero(x::Symbolic{T}) where T<:Union{Symbol,Expr} = Symbolic(0)
Base.one(x::Symbolic{T}) where T<:Union{Symbol,Expr} = Symbolic(1)
Base.oneunit(x::Symbolic{T}) where T<:Union{Symbol,Expr} = Symbolic(1)
Base.zero(x::Type{<:Symbolic}) = Symbolic(0)
Base.one(x::Type{<:Symbolic}) = Symbolic(1)
Base.oneunit(x::Type{<:Symbolic}) = Symbolic(1)

const ZERO = S"0"
const ONE = S"1"

Base.zero(::Type{Symbolic{T}}) where T = Symbolic(zero(T))
Base.one(::Type{Symbolic{T}}) where T = Symbolic(one(T))
Base.oneunit(::Type{Symbolic{T}}) where T = Symbolic(one(T))
Base.zero(::Type{Symbolic}) = ZERO
Base.one(::Type{Symbolic}) = ONE
Base.oneunit(::Type{Symbolic}) = ONE
Base.zero(::Type{Symbolic{T}}) where T<:Union{Symbol,Expr} = ZERO
Base.one(::Type{Symbolic{T}}) where T<:Union{Symbol,Expr} = ONE
Base.oneunit(::Type{Symbolic{T}}) where T<:Union{Symbol,Expr} = ONE

Base.iszero(x::Symbolic) = iszero(x.value)
Base.iszero(::SymbolOrExpr) = false
Base.isone(x::Symbolic) = isone(x.value)
Base.isone(::SymbolOrExpr) = false

identity_element(::typeof(+), ::Symbolic{T,<:Number}, ::Symbol) where {T} = ZERO
identity_element(::typeof(*), ::Symbolic{T,<:Number}, ::Symbol) where {T} = ONE
identity_element(::typeof(^), ::Symbolic{T,<:Number}, side::Symbol) where {T} = side == :right ? ONE : error("^ only has a right identity element")

iscall(::Symbolic) = false
iscall(x::Symbolic{Expr}) = value(x).head == :call
iscall(op::Symbol, x::Symbolic{Expr}) = iscall(x) && value(x).args[1] == op

include("expression.jl")

#="""
    iscommutative(f, x, y)
"""=#
iscommutative(::Function, ::Type, ::Type) = false
iscommutative(f::Function, ::Class{C1}, ::Class{C2}) where {C1, C2} = iscommutative(f, C1, C2)

macro commutes(f, T, S)
    :(iscommutative(::typeof($f), ::Type{<:$T}, ::Type{<:$S}) = true)
end
@commutes(+, Number, Number)
@commutes(+, AbstractArray, AbstractArray)

@commutes(*, Number, Number)
@commutes(*, Number, AbstractArray)
@commutes(*, AbstractArray, Number)

# reorderterms(f::Function, xs::AbstractVector{<:Symbolic}) = order!(f, copy(xs))
# reorderterms!(f::Function, xs::AbstractVector{<:Symbolic}) = Base.sort!(xs, lt = (x,y) -> iscommutative(f, x, y) && isless(string(x), string(y)))

#="""
    derive_class(f, xs...)
"""=#
derive_class(f::Function, xs::Type...) = Core.Inference.return_type(f, Tuple{xs...})

derive_class(f::Function, x1::Class{C}) where {C} = derive_class(f, C)
derive_class(f::Function, x1::Class{C1}, x2::Class{C2}) where {C1, C2} = derive_class(f, C1, C2)
function derive_class(f::Function, x1::Class{C1}, x2::Class{C2}, xs::Symbolic...) where {C1, C2}
    assoc = Base.operator_associativity(Symbol(f))
    if assoc === :left || Symbol(f) in (:+, :*)
        fold = foldl
    elseif assoc === :right
        fold = foldr
    else
        return Any
    end
    return fold((x, y) -> derive_class(f, x, y), map(x -> typeof(x).parameters[2], [x1, x2, xs...]))
end

derive_class(::Union{typeof(-), typeof(+)}, ::Type{T}) where {T<:Union{Number,AbstractArray}} = T

derive_class(f::Function, ::Type{T}, ::Type{S}) where {T<:Number,S<:Number} = typejoin(T, S, typeof(f(one(T), one(S))))

derive_class(f::Union{typeof(*), typeof(/)}, ::Type{A}, ::Type{S}) where {T<:Number, N, A<:AbstractArray{T,N}, S<:Number} = A.name.wrapper{derive_class(f, T, S), N}
derive_class(f::Union{typeof(*), typeof(\)}, ::Type{S}, ::Type{A}) where {T<:Number, N, A<:AbstractArray{T,N}, S<:Number} = A.name.wrapper{derive_class(f, T, S), N}

derive_properties(f, xs::Symbolic...) = Properties()

derived(f::Function, xs::Symbolic...) = Symbolic(derive_class(f, xs...), Expr(:call, Symbol(f), xs...), derive_properties(f, xs...))

include("math.jl")
include("operators.jl")
define_operators(false)

function debug(debug::Bool = true)
    if debug
        setshow("S\"", "\"")
        define_operators(true)
    else
        setshow("", "")
        define_operators(false)
    end
    print("Debug: $debug")
end

include("def.jl")

end # module
