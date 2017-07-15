module Sylvia

############################################################

export @S_str, @def, @λ, Symbolic

############################################################

struct Symbolic
    value
end
Symbolic(value::Symbolic) = Symbolic(value.value) # Don't nest Symbolic types
Symbolic(value::AbstractArray) = convert(AbstractArray{Symbolic}, value)

value(x::Symbolic) = x.value

macro S_str(str)
    Symbolic(parse(str))
end

############################################################

show_prefix = ""
show_suffix = ""
function setshow(prefix, suffix)
    global show_prefix, show_suffix
    show_prefix = prefix
    show_suffix = suffix
    println("Symbolic types printed as print(Symbolic(x)) -> $(show_prefix)x$(show_suffix)")
end

Base.show(io::IO, x::Symbolic) = print(io, "$show_prefix$(x.value)$show_suffix")

Base.convert(::Type{Symbolic}, x) = Symbolic(x)
Base.convert(::Type{Symbolic}, x::Symbolic) = x

############################################################

############################################################

Base.zero(::Symbolic) = Symbolic(0)
Base.one(::Symbolic) = Symbolic(1)
Base.oneunit(::Symbolic) = Symbolic(1)
Base.zero(::Type{Symbolic}) = Symbolic(0)
Base.one(::Type{Symbolic}) = Symbolic(1)
Base.oneunit(::Type{Symbolic}) = Symbolic(1)

Base.iszero(x::Symbolic) = iszero(x.value) # Compatibility
iszero(x) = Base.iszero(x)
iszero(::Symbol) = false
iszero(::Expr) = false

isone(x) = x == one(x)
isone(::Symbol) = false
isone(::Expr) = false

ideleml(::Type{Val{:+}}) = 0
ideleml(::Type{Val{:*}}) = 1
idelemr(::Type{Val{:+}}) = 0
idelemr(::Type{Val{:*}}) = 1
idelemr(::Type{Val{:^}}) = 1

iscall(x) = false
iscall(x::Expr) = x.head == :call

getsymbols(::Number) = Set(Symbol[])
getsymbols(x::Symbol) = Set(Symbol[x])
getsymbols(A::AbstractArray) = mapreduce(getsymbols, union, A)
getsymbols(x::Expr) = getsymbols(Val{x.head}, x.args)
getsymbols(::Any, args) = mapreduce(getsymbols, union, args)
getsymbols(::Type{Val{:call}}, args) = mapreduce(getsymbols, union, args[2:end])

hassymbols(::Number) = false
hassymbols(::Symbol) = true
hassymbols(x::Expr) = hassymbols(Val{x.head}, x.args)
hassymbols(::Any, args) = any(map(hassymbols, args))
hassymbols(::Type{Val{:call}}, args) = any(map(hassymbols, args[2:end]))


firstsymbol(x) = nothing
firstsymbol(x::Symbol) = x
firstsymbol(x::Expr) = firstsymbol(Val{x.head}, x.args)
firstsymbol(x::AbstractArray) = for arg in x
    (s = firstsymbol(arg)) != nothing && return s
end
firstsymbol(::Any, args) = firstsymbol(args)
firstsymbol(::Type{Val{:call}}, args) = firstsymbol(args[2:end])

isless(x, y) = Base.isless(x, y)
isless(::Union{Symbol, Expr}, ::Number) = false
isless(::Number, ::Union{Symbol, Expr}) = true
isless(x::Symbol, y::Expr) = isless(x, firstsymbol(y))
isless(x::Expr, y::Symbol) = isless(firstsymbol(x), y)
isless(x::Expr, y::Expr) = isless(firstsymbol(x), firstsymbol(y))
isless(::Any, ::Void) = false
isless(::Void, ::Any) = true
isless(::Void, ::Void) = true

sort(x) = Base.sort(x, lt=isless)

# Helper functions

_split_expr(x, f::Symbol) = (x, idelemr(Val{f}))
split_expr(x, f::Symbol) = _split_expr(x, f)
split_expr(x::Expr, f::Symbol) = _split_expr(Val{x.head}, x, f)

_split_expr(::Any, x, f::Symbol) = _split_expr(x, f)
function _split_expr(::Type{Val{:call}}, x::Expr, f::Symbol)
    x.args[1] != f && return _split_expr(x, f)
    length(x.args[2:end]) == 2 && return x.args[2:end]
    (x.args[2], Expr(:call, f, x.args[3:end]...))
end

unroll_expr(x, ::Symbol) = [x]
unroll_expr(x::QuoteNode, ::Symbol) = [x.value]
unroll_expr(x::Expr, f::Symbol) = x.args[1] == f ? x.args[2:end] : [x]

mulsort(a, i) = begin
    a isa Number ? (i, a) : (a, i)
end

# eq

eq(x, y) = x == y

# sign

sign(x) = isneg(x) ? (-1, neg(x)) : (1, x)
sign(x, s) = isneg(s) ? neg(x) : x

# neg

isneg(x::UniformScaling) = x < 0
isneg(x::Real) = x < 0
isneg(x::Complex) = real(x) < 0
isneg(x::Symbol) = false
isneg(x::Expr) = iscall(x) && x.args[1] == :- && length(x.args) == 2

neg(x::Number) = -x
neg(x::Symbol) = :(-$x)
function neg(x::Expr)
    xs = unroll_expr(x, :+)
    if length(xs) > 1
        return Expr(:call, :+, map(neg, xs)...)
    end
    if x.args[1] == :-
        if length(x.args) == 2
            return x.args[2]
        else
            return sub(x.args[3], x.args[2])
        end
    end
    :(-($x))
end

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

addunroll(x) = x
function addunroll(x::Expr)
    isneg(x) && return map(neg, unroll_expr(x.args[2], :+))

    x = unroll_expr(x, :-)
    length(x) == 1 && return unroll_expr(x[1], :+)
    length(x) == 2 && return [unroll_expr(x[1], :+);
                              map(neg, unroll_expr(x[2], :+))]
end

isadd(x) = false
isadd(x::Expr) = iscall(x) && x.args[1] == :+

add(x::Number, y::Number) = x + y
add(x::Union{Symbol, Expr}, n::Number) = iszero(n) ? x : _add(x, n)
add(n::Number, x::Union{Symbol, Expr}) = add(x, n)
add(x, y) = _add(x, y)

function _add(x, y)
    x == y && return mul(2, x)
    x == neg(y) && return 0

    rawargs = sort([addunroll(x); addunroll(y)])
    args = []
    a = rawargs[1]

    s, a = sign(a)
    a, i = mulsort(split_expr(a, :*)...); i = mul(s, i)
    for b in rawargs[2:end]
        if a isa Number && b isa Number && i isa Number
            a = a * i + b
            i = 1
            continue
        end

        s, b = sign(b)
        b, j = mulsort(split_expr(b, :*)...); j = mul(j, s)
        if b == a
            i = add(i, j)
        else
            !iszero(a) && !iszero(i) && push!(args, isone(i) ? a : mul(a, i))
            a, i = b, j
        end
    end
    # Push final element
    !iszero(a) && !iszero(i) && push!(args, isone(i) ? a : mul(a, i))

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
        isneg(a) ? push!(subargs, neg(a)) : push!(addargs, a)
    end

    addexpr = addcollect(sort(addargs))
    subexpr = addcollect(sort(subargs))

    iszero(subexpr) && return addexpr
    iszero(addexpr) && return :(-$subexpr)
    return :($addexpr - $subexpr)
end

# sub
sub(x, y) = add(x, neg(y))

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

ismul(x) = false
ismul(x::Expr) = iscall(x) && x.args[1] == :*

mul(x::Number, y::Number) = x * y
function mul(x::Union{Symbol, Expr}, n::Number)
    iszero(n) && return 0
    isone(n) && return x
    isneg(n) && isneg(x) && return mul(neg(n), neg(x))
    isneg(n) && return neg(mul(neg(n), x))
    isneg(x) && return neg(mul(n, neg(x)))
    return _mul(n, x)
end
mul(n::Number, x::Union{Symbol, Expr}) = mul(x, n)
mul(x, y) = _mul(x, y)

function _mul(x, y)
    x == y && return pow(x, 2)
    x == inv(y) && return 1

    s, x = sign(x)
    s_, y = sign(y)
    s = mul(s, s_)

    rawargs = [mulunroll(x); mulunroll(y)]
    args = []
    a = rawargs[1]

    a, i = split_expr(a, :^)
    s_, a = sign(a)
    s = mul(s, s_)

    for b in rawargs[2:end]
        if a isa Number && b isa Number && i isa Number
            a = a^i * b
            i = 1
            continue
        end

        b, j = split_expr(b, :^)
        s_, b = sign(b)
        s = mul(s, s_)

        if b == a
            i = add(i, j)
        else
            !isone(a) && !iszero(i) && push!(args, isone(i) ? a : pow(a, i))
            a, i = b, j
        end
    end
    # Push final element
    if (!isone(a) && !iszero(i)) || length(args) == 0
        push!(args, iszero(i) ? 1 : isone(i) ? a : pow(a, i))
    end

    if length(args) == 1
        return sign(args[1], s)
    end

    # Sort out division
    divargs = []
    a, i = split_expr(pop!(args), :^)
    while length(args) > 0 && isneg(i)
        push!(divargs, isone(neg(i)) ? a : pow(a, neg(i)))
        a, i = split_expr(pop!(args), :^)
    end
    if isneg(i)
        push!(divargs, isone(neg(i)) ? a : pow(a, neg(i)))
        push!(args, 1)
    else
        push!(args, iszero(i) ? 1 : isone(i) ? a : pow(a, i))
    end

    mulexpr = mulcollect(args)
    divexpr = mulcollect(divargs)

    sign(isone(divexpr) ? mulexpr : :($mulexpr / $divexpr), s)
end
mul(x::Symbolic, y::Number) = mul(y, x)

# div
isdiv(x) = false
isdiv(x::Expr) = iscall(x) && x.args[1] == :/
isidiv(x) = false
isidiv(x::Expr) = iscall(x) && x.args[1] == :\
isrdiv(x) = false
isrdiv(x::Expr) = iscall(x) && x.args[1] == ://

div(x::Number, y::Number) = x / y
div(x::Union{Symbol, Expr}, y::Number) = isone(y) ? x : :($x / $y)
div(x::Number, y::Union{Symbol, Expr}) = isone(x) ? inv(y) : :($x / $y)
div(x, y) = mul(x, inv(y))

idiv(x, y) = mul(inv(x), y)

rdiv(x::Number, y::Number) = x // y
rdiv(x::Union{Symbol, Expr}, y::Number) = isone(y) ? x : :($x // $y)
rdiv(x::Number, y::Union{Symbol, Expr}) = :($x // $y)
rdiv(x, y) = x == y ? 1 : :($x // $y)

# pow
ispow(x) = false
ispow(x::Expr) = iscall(x) && x.args[1] == :^

pow(x::Union{Symbol, Expr}, n::Number) = iszero(n) ? 1 : isone(n) ? x : _pow(x, n)
pow(n::Number, x::Union{Symbol, Expr}) = isone(n) ? n : _pow(n, x)
pow(x, y) = _pow(x, y)
function _pow(x, y)
    x, i = split_expr(x, :^)
    i, j = split_expr(i, :*)
    y = mul(y, isone(i) ? j : mul(i, j))
    iszero(y) ? 1 : isone(y) ? x : :($x ^ $y)
end

# inv
isinv(x) = false
isinv(x::Expr) = ispow(x) && isneg(x.args[3])

inv(x) = Base.inv(x)
inv(x::Symbol) = :($x^-1)
inv(x::Expr) = pow(x, -1)

conj(x) = Base.conj(x)
conj(x::Symbol) = :(conj($x))
conj(x::Expr) = isconj(x) ? x.args[2] : :(conj($x))

isconj(x) = false
isconj(x::Expr) = iscall(x) && x.args[1] == :conj

transpose(x) = Base.transpose(x)
transpose(x::Symbol) = :($x.')
function transpose(x::Expr)
    isconj(x) && return ctranspose(x.args[2])
    istranspose(x) && return x.args[1]
    isctranspose(x) && return conj(x.args[1])

    isadd(x) && return sum(map(transpose, unroll_expr(x, :+)))

    X = mulunroll(x)
    length(X) == 1 && return :($x.')
    reduce(mul, (map(transpose, reverse(X))))
end

istranspose(x) = false
istranspose(x::Expr) = iscall(x) && x.args[1] == Symbol(".'")

ctranspose(x) = Base.ctranspose(x)
ctranspose(x::Symbol) = :($x')
function ctranspose(x::Expr)
    isconj(x) && return transpose(x.args[2])
    istranspose(x) && return conj(x.args[1])
    isctranspose(x) && return x.args[1]

    isadd(x) && return sum(map(ctranspose, unroll_expr(x, :+)))

    X = mulunroll(x)
    length(X) == 1 && return :($x')
    reduce(mul, (map(ctranspose, reverse(X))))
end

isctranspose(x) = false
isctranspose(x::Expr) = iscall(x) && x.args[1] == Symbol("'")

############################################################

############################################################

macro verbose_call(name, symbols, expr)
    esc(quote
        print("$($name)(", join($symbols, ", "), ")")
        retval = $expr
        println(" => $retval")
        retval
    end)
end

function define_operators(verbose::Bool)
    for (op, name) in ((:(Base.:+), identity), (:(Base.:-), neg), (:(Base.inv), inv),
                       (:(Base.conj), conj), (:(Base.transpose), transpose),
                       (:(Base.ctranspose), ctranspose))
        if verbose
            @eval $op(x::Symbolic) = @verbose_call $name (x,) Symbolic($name(x.value))
        else
            @eval $op(x::Symbolic) = Symbolic($name(x.value))
        end
    end

    for (op, name) in ((:(Base.:+), add), (:(Base.:-), sub), (:(Base.:*), mul), (:(Base.:/), div),
                       (:(Base.:\), idiv), (:(Base.://), rdiv), (:(Base.:^), pow))
        if verbose
            @eval $op(x::Symbolic, y) = @verbose_call $name (x, y) Symbolic($name(x.value, y))
            @eval $op(x, y::Symbolic) = @verbose_call $name (x, y) Symbolic($name(x, y.value))
            @eval $op(x::Symbolic, y::Symbolic) = @verbose_call $name (x, y) Symbolic($name(x.value, y.value))
        else
            @eval $op(x::Symbolic, y) = Symbolic($name(x.value, y))
            @eval $op(x, y::Symbolic) = Symbolic($name(x, y.value))
            @eval $op(x::Symbolic, y::Symbolic) = Symbolic($name(x.value, y.value))
        end
    end

    # Undressed return values

    for (op, name) in ((:(Base.:(==)), eq), (:(Base.:<), isless))
        if verbose
            @eval $op(x::Symbolic, y) = @verbose_call $name (x, y) $name(x.value, y)
            @eval $op(x, y::Symbolic) = @verbose_call $name (x, y) $name(x, y.value)
            @eval $op(x::Symbolic, y::Symbolic) = @verbose_call $name (x, y) $name(x.value, y.value)
        else
            @eval $op(x::Symbolic, y) = $name(x.value, y)
            @eval $op(x, y::Symbolic) = $name(x, y.value)
            @eval $op(x::Symbolic, y::Symbolic) = $name(x.value, y.value)
        end
    end

    # Needs special treatment
    if verbose
        Base.:^(x::Symbolic, y::Integer) = @verbose_call $name (x, y) Symbolic(pow(x.value, y))
    else
        Base.:^(x::Symbolic, y::Integer) = Symbolic(pow(x.value, y))
    end
end

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

############################################################

############################################################

expressify(a) = a # Catch all
expressify(V::AbstractVector) = Expr(:vect, value.(V)...)
expressify(A::AbstractMatrix) = Expr(:vcat, mapslices(x -> Expr(:row, value.(x)...), A, 2)...)

macro def(expr)
    if expr.head ≠ :(=)
        throw(ArgumentError("invalid function definition"))
    end

    body = expressify(Main.eval(expr.args[2]))

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

macro λ(expr)
    if expr.head == :(->)
        if expr.args[1].head ≠ :tuple
            throw(ArgumentError("invalid lambda definition"))
        end
        body = expressify(Main.eval(expr.args[2]))
        symbols = expr.args[1].args
    else
        body = expressify(Main.eval(expr))
        symbols = sort(collect(getsymbols(body)))
    end
    return esc(Expr(:(->), Expr(:tuple, symbols...), body))
end

end # module
