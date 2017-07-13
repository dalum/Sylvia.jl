module Sylvia

import Base: convert, isless, zero, one, oneunit,
    +, -, *, /, ^, //, \,
    inv, conj, transpose, ctranspose

export @def

TypeSymbolLike = Union{Type{Symbol}, Type{Expr}, Type{QuoteNode}}
SymbolLike = Union{Symbol, Expr, QuoteNode}

#

isone(x) = x == one(x)

convert(::Type{Expr}, x::QuoteNode) = :(1*$x)
convert(::Type{Expr}, x::Symbol) = :(1*$x)
convert(::TypeSymbolLike, x::Number) = :(1*$x)

zero(::Union{TypeSymbolLike, SymbolLike, Type{SymbolLike}}) = QuoteNode(0)#:(0+0)# QuoteNode(0)
one(::Union{TypeSymbolLike, SymbolLike, Type{SymbolLike}}) = QuoteNode(1)#:(1*1)# QuoteNode(1)
oneunit(x::Union{TypeSymbolLike, SymbolLike, Type{SymbolLike}}) = one(x)

iscall(x) = false
iscall(x::Expr) = x.head == :call

getsymbols(::Number) = Set(Symbol[])
getsymbols(x::Symbol) = Set(Symbol[x])
function getsymbols(x::Expr)
    if x.head in [Symbol("'"), Symbol(".'"), :row, :vcat]
        return mapreduce(getsymbols, union, x.args[1:end])
    end
    if x.head == :call
        return mapreduce(getsymbols, union, x.args[2:end])
    end
end
getsymbols(A::AbstractArray) = mapreduce(getsymbols, union, A)

hassymbols(::Number) = false
hassymbols(::Symbol) = true
function hassymbols(x::Expr)
    if x.head in [Symbol("'"), Symbol(".'")]
        return hassymbols(x.args[1])
    end
    if x.head == :call
        return any(map(hassymbols, x.args[2:end]))
    end
end

first_symbol(x) = nothing
first_symbol(x::Symbol) = x
first_symbol(x::QuoteNode) = x.value
function first_symbol(x::Expr)
    if x.head == Symbol("'")
        return first_symbol(x.args[1])
    end
    if x.head == :call
        for arg in x.args[2:end]
            (s = first_symbol(arg)) != nothing && return s
        end
    end
    nothing
end

isless(x::SymbolLike, y::SymbolLike) = isless(first_symbol(x), first_symbol(y))
isless(x::Number, y::SymbolLike) = isless(string(x), string(first_symbol(y)))
isless(x::SymbolLike, y::Number) = isless(string(first_symbol(x)), string(y))
isless(::Void, ::Any) = true
isless(::Any, ::Void) = false
isless(::Void, ::Void) = false

# Helper functions

split_expr(x, ::Symbol) = (x, 1)
function split_expr(x::Expr, f::Symbol)
    if x.head == :call && x.args[1] == f
        if length(x.args[3:end]) > 1
            return (x.args[2], Expr(:call, f, x.args[3:end]...))
        end
        return (x.args[2], x.args[3])
    end
    (x, 1)
end

unroll_expr(x, ::Symbol) = [x]
unroll_expr(x::QuoteNode, ::Symbol) = [x.value]
unroll_expr(x::Expr, f::Symbol) = x.args[1] == f ? x.args[2:end] : [x]

mulsort(a, i) = a isa Number ? (i, a) : (a, i)

# Negation
function neg(x)
    #return :(-($x))
    xs = unroll_expr(x, :+)
    if length(xs) > 1
        return Expr(:call, :+, map(-, xs)...)
    end
    if x.args[1] == :-
        if length(x.args) == 2
            return x.args[2]
        else
            return x.args[3] - x.args[2]
        end
    end
    :(-($x))
end
neg(x::Symbol) = :(-$x)

isneg(x::Real) = x < 0
isneg(x::Complex) = real(x) < 0
isneg(x::Symbol) = false
isneg(x::Expr) = x.head == :call && x.args[1] == :- && length(x.args) == 2

sign(x) = isneg(x) ? (-1, -x) : (1, x)
sign(x, s) = isneg(s) ? -x : x

-(x::SymbolLike) = neg(x)
#+(x::SymbolLike) = 1 * x

# add
function addcollect(x)
    if length(x) == 0
        return 0
    end
    if length(x) == 1
        return x[1]
    end
    Expr(:call, :+, x...)
end

function addunroll(x)
    isneg(x) && return map(neg, unroll_expr(x.args[2], :+))

    x = unroll_expr(x, :-)
    length(x) == 1 && return unroll_expr(x[1], :+)
    length(x) == 2 && return [unroll_expr(x[1], :+);
                              map(neg, unroll_expr(x[2], :+))]
end

function add(x, y)
    iszero(x) && return y
    iszero(y) && return x
    x == y && return 2x

    rawargs = sort([addunroll(x); addunroll(y)])
    args = []
    a = rawargs[1]

    s, a = sign(a)
    a, i = mulsort(split_expr(a, :*)...); i *= s
    for b in rawargs[2:end]
        if !hassymbols(a) && !hassymbols(i) && !hassymbols(b)
            a *= i
            i = 1
            a += b
            continue
        end

        s, b = sign(b)
        b, j = mulsort(split_expr(b, :*)...); j *= s
        if b == a
            i = i + j
        else
            !iszero(a) && !iszero(i) && push!(args, isone(i) ? a : a * i)
            a, i = b, j
        end
    end
    # Push final element
    !iszero(a) && !iszero(i) && push!(args, isone(i) ? a : a * i)

    if length(args) == 0
        return 0
    end
    if length(args) == 1
        return args[1]
    end

    subargs = []
    addargs = []
    while length(args) > 0
        a = pop!(args)
        isneg(a) ? push!(subargs, -a) : push!(addargs, a)
    end

    addexpr = addcollect(sort(addargs))
    subexpr = addcollect(sort(subargs))

    iszero(subexpr) && return addexpr
    iszero(addexpr) && return :(-$subexpr)
    return :($addexpr - $subexpr)
end

isadd(x) = false
isadd(x::Expr) = x.head == :call && x.args[1] == :+

# sub
function sub(x, y)
    if iszero(x)
        return -y
    end
    if iszero(y)
        return x
    end
    if x == y
        return 0
    end
    x + (-y)
end

# mul
function mulcollect(x)
    if length(x) == 0
        return 1
    end
    if length(x) == 1
        return x[1]
    end
    Expr(:call, :*, x...)
end

function mulunroll(x)
    x = unroll_expr(x, :/)
    length(x) == 1 && return unroll_expr(x[1], :*)
    length(x) == 2 && return [unroll_expr(x[1], :*);
                              map(inv, reverse(unroll_expr(x[2], :*)))]
end

function mul(x, y)
    (iszero(x) || iszero(y)) && return zero(Expr)
    isone(x) && return y
    isone(y) && return x
    x == y && return x^2

    s, x = sign(x)
    s_, y = sign(y); s *= s_

    rawargs = [mulunroll(x); mulunroll(y)]
    args = []
    a = rawargs[1]

    a, i = split_expr(a, :^)
    s_, a = sign(a); s *= s_

    for b in rawargs[2:end]
        if !hassymbols(a) && !hassymbols(i) && !hassymbols(b)
            a ^= i
            i = 1
            a *= b
            continue
        end

        b, j = split_expr(b, :^)
        s_, b = sign(b); s *= s_

        if b == a
            i = i + j
        else
            !isone(a) && push!(args, iszero(i) ? 1 : isone(i) ? a : a^i)
            a, i = b, j
        end
    end
    # Push final element
    push!(args, iszero(i) ? 1 : isone(i) ? a : a^i)

    if length(args) == 1
        return sign(args[1], s)
    end

    # Sort out division
    divargs = []
    a, i = split_expr(pop!(args), :^)
    while length(args) > 0 && isneg(i)
        push!(divargs, isone(-i) ? a : a^-i)
        a, i = split_expr(pop!(args), :^)
    end
    if isneg(i)
        push!(divargs, isone(-i) ? a : a^-i)
        push!(args, 1)
    else
        push!(args, iszero(i) ? 1 : isone(i) ? a : a^i)
    end

    mulexpr = mulcollect(args)
    divexpr = mulcollect(divargs)

    sign(isone(divexpr) ? mulexpr : :($mulexpr / $divexpr), s)
end
mul(x::SymbolLike, y::Number) = mul(y, x)

# div
function div(x, y)
    isone(x) && return inv(y)
    isone(y) && return x
    x == y && return 1

    x * inv(y)
end
rdiv(x, y) = inv(x) * y

# pow
function pow(x, y)
    Expr(:call, :^, x, y)
end

# inv
function inv(x::SymbolLike)
    s, x = sign(x)
    sign(x^-1, s)
end

isinv(x) = false
isinv(x::Expr) = x.head == :call && x.args[1] == :^ && isneg(x.args[3])

# Needs special treatment
^(x::SymbolLike, y::Integer) = pow(x, y)

conj(x::Symbol) = :(conj($x))
conj(x::Expr) = isconj(x) ? x.args[2] : :(conj($x))
isconj(x::Symbol) = false
isconj(x::Expr) = x.head == :call && x.args[1] == :conj

for (f, s) in [(:transpose, ".'"), (:ctranspose, "'")]
    isf = Symbol(:is, f)

    @eval $isf(x) = false
    @eval $isf(x::Expr) = x.head == Symbol("$($s)")
    @eval $f(x::SymbolLike) = Expr(Symbol("$($s)"), x)
end

function transpose(x::Expr)
    !hassymbols(x) && return transpose(eval(x))
    istranspose(x) && return x.args[1]
    isadd(x) && return sum(map(transpose, unroll_expr(x, :+)))
    isconj(x) && return ctranspose(x.args[2])

    X = mulunroll(x)
    length(X) == 1 && return :($x.')
    prod(map(transpose, reverse(X)))
end

function ctranspose(x::Expr)
    !hassymbols(x) && return ctranspose(eval(x))
    isctranspose(x) && return x.args[1]
    isadd(x) && return sum(map(ctranspose, unroll_expr(x, :+)))
    isconj(x) && return transpose(x.args[2])

    X = mulunroll(x)
    length(X) == 1 && return :($x')
    prod(map(ctranspose, reverse(X)))
end

for (op, name) in ((:+, add), (:-, sub),
                 (:*, mul), (:/, div), (:\, rdiv), (://, div),
                 (:^, pow))
    @eval $op(x::SymbolLike, y) = $name(x, y)
    @eval $op(x, y::SymbolLike) = $name(x, y)
    @eval $op(x::SymbolLike, y::SymbolLike) = $name(x, y)
end

expressify(a) = a # Catch all
expressify(A::AbstractMatrix) = Expr(:vcat, mapslices(x -> Expr(:row, x...), A, 2)...)

macro def(expr)
    expr.head != :(=) && throw(ArgumentError("invalid function definition"))

    body = expressify(Main.eval(expr.args[2]))

    name = expr.args[1]
    if name isa Symbol
        symbols = sort(collect(getsymbols(body)))
    elseif iscall(name)
        name, symbols = name.args[1], name.args[2:end]
    else
        throw(ArgumentError("name must be either a symbol or call"))
    end
    return esc(:($name($(symbols...,)) = $body))
end

end # module
