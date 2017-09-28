struct Factorization{F, T}
    op::F
    data::Vector{T}
end
Base.show(io::IO, F::Factorization) = print(io, "Factorization($(F.op), $(F.data))")

function Base.getindex(F::Factorization, ind::Int64)
    side = ind < 1 ? :left : :right
    firstlast = ind < 1 ? first(F.data) : last(F.data)
    return get(F.data, ind, identity_element(F.op, ind < 1 ? first(F.data) : last(F.data), side))
end
Base.getindex(F::Factorization, inds::AbstractRange) = Factorization(F.op, [Base.getindex(F, ind) for ind in inds])
Base.length(F::Factorization) = length(F.data)
Base.start(F::Factorization) = start(F.data)
Base.next(F::Factorization, state) = next(F.data, state)
Base.done(F::Factorization, state) = done(F.data, state)
Base.endof(F::Factorization) = endof(F.data)
Base.:(==)(F1::Factorization, F2::Factorization) = F1.op == F2.op && F1.data == F2.data

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

Base.iszero(x::Symbolic) = iszero(value(x))
Base.iszero(::SymbolOrExpr) = false
Base.isone(x::Symbolic) = isone(value(x))
Base.isone(::SymbolOrExpr) = false
Base.isinf(x::Symbolic) = isinf(value(x))
Base.isinf(::SymbolOrExpr) = false

Base.complex(x::Symbolic{<:Number}) = Symbolic(complex(value(x)))
Base.complex(x::Symbolic{T,C}) where {T<:Union{Symbol,Expr}, C<:Number} = Symbolic{T,C}(x)

identity_element(::typeof(+), ::Symbolic{T,<:Union{Number,AbstractArray{Number}}}, ::Symbol) where {T} = ZERO
identity_element(::typeof(*), ::Symbolic{T,<:Union{Number,AbstractArray{Number}}}, ::Symbol) where {T} = ONE
identity_element(::typeof(^), ::Symbolic{T,<:Union{Number,AbstractArray{Number}}}, side::Symbol) where {T} = side == :right ? ONE : error("^ only has a right identity element")

getsymbols(x::Symbolic) = getsymbols(x.value)
getsymbols(::Number) = Set(Symbol[])
getsymbols(x::Symbol) = Set(Symbol[x])
getsymbols(A::AbstractArray) = mapreduce(getsymbols, union, A)
getsymbols(x::Expr) = getsymbols(Val{x.head}, x.args)
getsymbols(::Any, args) = mapreduce(getsymbols, union, args)
getsymbols(::Type{Val{:call}}, args) = mapreduce(getsymbols, union, args[2:end])

replacesymbols(::Val{<:Symbol}, expr::Expr) = replacesymbols(expr, 1, endof(expr.args))
replacesymbols(::Val{:call}, expr::Expr) = replacesymbols(expr, 2, endof(expr.args))
replacesymbols(expr::Expr, start::Integer, stop::Integer) = replacesymbols!(copy(expr), start, stop)

function replacesymbols!(expr::Expr, start::Integer, stop::Integer)::Symbolic
    for (i, arg) in enumerate(expr.args[start:stop])
        expr.args[start + i - 1] = symbol(arg)
    end
    return expr
end

hassymbols(x::Symbolic) = hassymbols(x.value)
hassymbols(::Number) = false
hassymbols(::Symbol) = true
hassymbols(x::Expr) = hassymbols(Val{x.head}, x.args)
hassymbols(::Any, args) = any(map(hassymbols, args))
hassymbols(::Type{Val{:call}}, args) = any(map(hassymbols, args[2:end]))

fingerprint(x) = ""
fingerprint(x::Symbolic{Symbol}) = string(x)
fingerprint(x::Symbolic{Expr}) = mapreduce(fingerprint, *, value(x).args)

iscall(::Symbolic) = false
iscall(::Symbol, ::Symbolic) = false
iscall(x::Symbolic{Expr}) = value(x).head == :call
iscall(op::Symbol, x::Symbolic{Expr}) = iscall(x) && value(x).args[1] == op

firstsymbol(x::Symbolic, d) = firstsymbol(x.value, d)
firstsymbol(x, d=nothing) = (s = _firstsymbol(x)) == nothing ? d : s

_firstsymbol(x) = nothing
_firstsymbol(x::Symbol) = x
_firstsymbol(x::AbstractArray) = for arg in x
    (s = _firstsymbol(arg)) != nothing && return s
end # else return nothing
_firstsymbol(x::Expr) = _firstsymbol(Val{x.head}, x.args)
_firstsymbol(::Any, args) = _firstsymbol(args)
_firstsymbol(::Type{Val{:call}}, args) = _firstsymbol(args[2:end])

# split_expr(x, f::Symbol) = _split_expr(x, f)
# split_expr(x::Expr, f::Symbol) = _split_expr(Val{x.head}, x, f)

# _split_expr(x, f::Symbol) = (x, idelemr(Val{f}))
# _split_expr(::Any, x, f::Symbol) = _split_expr(x, f)
# function _split_expr(::Type{Val{:call}}, x::Expr, f::Symbol)
#     x.args[1] != f && return _split_expr(x, f)
#     length(x.args[2:end]) == 2 && return x.args[2:end]
#     (x.args[2], Expr(:call, f, x.args[3:end]...))
# end

#="""
    commutesort(x, f)
"""=#
commutesort(f, x::Symbolic; kw...) = x
commutesort(f, x::Symbolic{Expr}; kw...) = join(f, commutesort(f, split(f, x); kw...))
commutesort(f, terms::AbstractVector{<:Symbolic}; kw...) = commutesort!(f, copy(terms); kw...)
function commutesort!(f, terms::AbstractVector{<:Symbolic}; lt=isless, by=fingerprint)
    if length(terms) <= 1
        return terms
    end

    sort!(terms, by=x->!all(iscommutative(f, typeof(x), T) for T in unique(typeof.(terms))))

    a = 1
    for b in 2:length(terms)
        if !iscommutative(f, terms[b], terms[b-1])
            terms[a:(b-1)] .= sort(terms[a:(b-1)], lt=lt, by=by)
            a = b
        end
    end

    terms[a:end] .= sort(terms[a:end], lt=lt, by=by)
    return terms
end

"""
    factorize(op, x::Symbolic)

Return a vector of the factors of `x` with respect to the operator `op`.  This function is the inverse of
`reduce`.

# Examples
```jldoctest
julia> factorize(*, S"a * b * c")
Factorization(*, Symbolic{Symbol,Number}[a, b, c])
```
"""
Base.factorize(op::Function, x::Symbolic; kw...) = Factorization(op, _factorize(op, x))

_factorize(op::Function, x::Symbolic) = _factorize(Symbol(op), x)
_factorize(op::Symbol, x::Symbolic) = [x]
function _factorize(op::Symbol, x::Symbolic{Expr})
    retvec = Symbolic[]
    if iscall(x) && value(x).args[1] == op
        append!(retvec, value(x).args[2:end])
    else
        push!(retvec, x)
    end
    return retvec
end

function _factorize(::typeof(+), x::Symbolic{Expr})
    isnegation(x) && return (-).(_factorize(:+, value(x).args[2]))
    x = _factorize(:-, x)
    length(x) == 1 && return _factorize(:+, x[1])
    length(x) == 2 && return vcat(_factorize(:+, x[1]), (-).(_factorize(:+, x[2])))
    throw(ArgumentError("cannot factorize using (+) on expression: $x"))
end

function _factorize(::typeof(*), x::Symbolic{Expr})
    x = _factorize(:/, x)
    if length(x) == 1
        fact =  _factorize(:*, x[1])
    elseif length(x) == 2
        fact = vcat(factorize(:*, x[1]), inv.(reverse(_factorize(:*, x[2]))))
    else
        throw(ArgumentError("cannot factorize using (*) on expression: $x"))
    end
    return mapreduce(factorize_sign, vcat, fact)
end
factorize_sign(x::Symbolic) = isnegative(x) ? [sign(x), -x] : [x]


Base.reduce(F::Factorization{<:Function, <:Symbolic}) = derived(F.op, F.data...)

function Base.reduce(F::Factorization{<:Union{typeof(*), typeof(/)}, <:Symbolic})
    length(F.data) == 0 && return ONE
    length(F.data) == 1 && return F.data[1]
    return derived(F.op, F.data...)
end
function Base.reduce(F::Factorization{<:Union{typeof(+), typeof(-)}, <:Symbolic})
    length(F.data) == 0 && return ZERO
    length(F.data) == 1 && return F.data[1]
    return derived(F.op, F.data...)
end
