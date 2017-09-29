__precompile__(true)

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
symbol(x::Symbolic) = x
symbol(expr::Expr) = replacesymbols(Val{expr.head}(), expr)

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

show_prefix = ""
show_suffix = ""
function setshow(prefix, suffix)
    global show_prefix, show_suffix
    show_prefix = prefix
    show_suffix = suffix
    println("Symbolic types printed as print(Symbolic(x)) -> $(show_prefix)x$(show_suffix)")
end

Base.show(io::IO, x::Symbolic) = print(io, "$show_prefix$(expressify(x))$show_suffix")

include("expression.jl")

#="""
    iscommutative(f, x, y)
"""=#
iscommutative(::Function, ::Type, ::Type) = false
iscommutative(f::Function, x1::Class{C1}, x2::Class{C2}) where {C1, C2} = x1 == x2 || iscommutative(f, C1, C2)
iscommutative(f::Function, ::Type{<:Class{C1}}, ::Type{<:Class{C2}}) where {C1, C2} = iscommutative(f, C1, C2)

macro commutes(f, T, S)
    :(iscommutative(::typeof($f), ::Type{<:$T}, ::Type{<:$S}) = true)
end
@commutes(+, Number, Number)
@commutes(+, Number, AbstractArray)
@commutes(+, AbstractArray, Number)
@commutes(+, AbstractArray, AbstractArray)

@commutes(*, Number, Number)
@commutes(*, Number, AbstractArray)
@commutes(*, AbstractArray, Number)

include("derive.jl")
include("math.jl")
include("simplify.jl")

macro _call(verbose, name, symbols, expr)
    if eval(verbose)
        return esc(quote
                   print("$($name)(", join($symbols, ", "), ")")
                   retval = $expr
                   println(" => $retval")
                   retval
                   end)
    else
        return esc(expr)
    end
end

function define_operators(verbose::Bool)

    ### Undressed return values
    for op in (:(Base.:(==)), :(Base.:<))
        @eval $op(x::Symbolic, y) = @_call $verbose $op (x, y) $op(x, Symbolic(y))
        @eval $op(x, y::Symbolic) = @_call $verbose $op (x, y) $op(Symbolic(x), y)
    end

    ### Dressed return values
    for op in (:(Base.:+), :(Base.:-), :(Base.:*), :(Base.:/), :(Base.:\), :(Base.://), :(Base.:^))
        @eval $op(x::Symbolic, y)::Symbolic = @_call $verbose $op (x, y) $op(x, Symbolic(y))
        @eval $op(x, y::Symbolic)::Symbolic = @_call $verbose $op (x, y) $op(Symbolic(x), y)
    end

    # Needs special treatment
    Base.:^(x::Symbolic, y::Integer)::Symbolic = x ^ Symbolic(y)

end

define_operators(false)

"""
    debug(value)
"""
function debug(value::Bool = true)
    if value
        setshow("S\"", "\"")
        define_operators(true)
    else
        setshow("", "")
        define_operators(false)
    end
    print("Debug: $value")
end

#="""
    expressify(a)
"""=#
expressify(a) = a # Catch all
expressify(a::Expr) = Expr(a.head, expressify.(a.args)...)
expressify(a::Symbolic) = expressify(value(a))
expressify(V::AbstractVector) = Expr(:vect, value.(V)...)
expressify(A::AbstractMatrix) = Expr(:vcat, mapslices(x -> Expr(:row, value.(x)...), A, 2)...)

# def

_def(mod::Module, expr::Symbol) = throw(ArgumentError("invalid function definition"))
function _def(mod::Module, expr::Expr)
    if expr.head ≠ :(=)
        throw(ArgumentError("invalid function definition"))
    end

    body = expressify(eval(mod, expr.args[2]))

    name = expr.args[1]
    if name isa Symbol
        symbols = sort(collect(getsymbols(body)))
    elseif iscall(name)
        name, symbols = name.args[1], name.args[2:end]
    else
        throw(ArgumentError("name must be either a symbol or call"))
    end
    return esc(Expr(:(=), Expr(:call, name, symbols...), body))
end

if VERSION >= v"0.7.0-DEV"
    macro def(expr) _def(__module__, expr) end
else
    macro def(expr) _def(Main, expr) end
end
macro def(mod, expr) _def(mod, expr) end

# λ

_parse_args(args::Symbol) = (args,)
function _parse_args(args::Expr)
    if args.head ≠ :tuple
        throw(ArgumentError("invalid argument list"))
    end
    return args.args
end

function _lambda_implicit(mod::Module, expr)
    body = expressify(eval(mod, expr))
    symbols = sort(collect(getsymbols(body)))
    esc(Expr(:(->), Expr(:tuple, symbols...), body))
end

_lambda(mod::Module, x::Symbol) = _lambda_implicit(mod, x)
function _lambda(mod::Module, expr::Expr)
    expr.head ≠ :(->) && return _lambda_implicit(mod, expr)
    symbols = _parse_args(expr.args[1])
    body = expressify(eval(mod, expr.args[2]))
    esc(Expr(:(->), Expr(:tuple, symbols...), body))
end

if VERSION >= v"0.7.0-DEV"
    macro λ(expr) _lambda(__module__, expr) end
else
    macro λ(expr) _lambda(Main, expr) end
end
macro λ(mod, expr) _lambda(mod, expr) end

end # module
