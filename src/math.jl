# eq

eq(x, y) = x == y

# sign

sign(x) = isneg(x) ? (-1, neg(x)) : (1, x)
sign(s, x) = isneg(s) ? neg(x) : x

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

isadd(x) = false
isadd(x::Expr) = iscall(x) && x.args[1] == :+

add(x::Number, y::Number) = x + y
add(x::Union{Symbol, Expr}, n::Number) = iszero(n) ? x : _add(x, n)
add(n::Number, x::Union{Symbol, Expr}) = add(x, n)
add(x, y) = _add(x, y)

function _add(x, y)
    x == y && return mul(2, x)
    x == neg(y) && return 0

    rawargs = sort([addunroll(x); addunroll(y)], lt=add_order)
    args = []
    a = rawargs[1]

    s, a = sign(a)
    a, i = mulsort(split_expr(a, :*)...)
    i = mul(s, i)
    for b in rawargs[2:end]
        if a isa Number && b isa Number && i isa Number
            a = a * i + b
            i = 1
            continue
        end

        s, b = sign(b)
        b, j = mulsort(split_expr(b, :*)...)
        j = mul(j, s)
        if b == a
            i = add(i, j)
        elseif !isone(i) && i == j
            a = add(a, b)
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

    addexpr = addcollect(sort(addargs, lt=add_order))
    subexpr = addcollect(sort(subargs, lt=add_order))

    iszero(subexpr) && return addexpr
    iszero(addexpr) && return :(-$subexpr)
    return :($addexpr - $subexpr)
end

# sub

sub(x, y) = add(x, neg(y))

# mul

ismul(x) = false
ismul(x::Expr) = iscall(x) && x.args[1] == :*

mul(::UniformScaling, x) = UniformScaling(x)
mul(x, ::UniformScaling) = UniformScaling(x)
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

    rawargs = sort([mulunroll(x); mulunroll(y)], lt=mul_order)
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
        return sign(s, args[1])
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

    mulexpr = mulcollect(sort(args, lt=mul_order))
    divexpr = mulcollect(sort(divargs, lt=mul_order))

    sign(s, isone(divexpr) ? mulexpr : :($mulexpr / $divexpr))
end

# div

isdiv(x) = false
isdiv(x::Expr) = iscall(x) && x.args[1] == :/
isidiv(x) = false
isidiv(x::Expr) = iscall(x) && x.args[1] == :\
isrdiv(x) = false
isrdiv(x::Expr) = iscall(x) && x.args[1] == ://

div(x::Number, y::Number) = x / y
div(x::Union{Symbol, Expr}, y::Number) = isone(y) ? x : _div(x, y)
div(x::Number, y::Union{Symbol, Expr}) = iszero(x) && !_strict ? 0 : isone(x) ? inv(y) : _div(x, y)
div(x, y) = _div(x, y)

_div(x, y) = mul(x, inv(y))

idiv(x::Number, y::Number) = x \ y
idiv(x::Union{Symbol, Expr}, y::Number) = iszero(x) && !_strict ? 0 : isone(x) ? inv(y) : _idiv(x, y)
idiv(x::Number, y::Union{Symbol, Expr}) = isone(y) ? x : _idiv(x, y)
idiv(x, y) = _idiv(x, y)

_idiv(x, y) = mul(inv(x), y)

rdiv(x::Number, y::Number) = x // y
rdiv(x::Union{Symbol, Expr}, y::Number) = isone(y) ? x : _rdiv(x, y)
rdiv(x::Number, y::Union{Symbol, Expr}) = _rdiv(x, y)
rdiv(x, y) = x == y ? 1 : _rdiv(x, y)

_rdiv(x, y) = :($x // $y)

# pow
ispow(x) = false
ispow(x::Expr) = iscall(x) && x.args[1] == :^

pow(x::Union{Symbol, Expr}, n::Number) = iszero(n) ? 1 : isone(n) ? x : _pow(x, n)
pow(n::Number, x::Union{Symbol, Expr}) = isone(n) ? n : _pow(n, x)
pow(x, y) = _pow(x, y)

function _pow(x, y)
    s, x = sign(x)
    x, i = split_expr(x, :^)
    i, j = split_expr(i, :*)
    y = mul(y, isone(i) ? j : mul(i, j))
    iszero(y) && return 1

    if isdiv(x) && isneg(y)
        x = div(reverse(split_expr(x, :/))...)
        y = neg(y)
    end
    x = sign(s, x)
    isone(y) ? x : :(($x) ^ $y)
end

# inv

isinv(x) = false
isinv(x::Expr) = ispow(x) && isneg(x.args[3])

inv(x) = Base.inv(x)
inv(x::Symbol) = :($x^-1)
inv(x::Expr) = pow(x, -1)

# conj

conj(x) = Base.conj(x)
conj(x::Symbol) = :(conj($x))
function conj(x::Expr)
    isconj(x) && return x.args[2]
    istranspose(x) && return ctranspose(x.args[1])
    isctranspose(x) && return transpose(x.args[1])

    isadd(x) && return reduce(add, map(conj, unroll_expr(x, :+)))

    X = mulunroll(x)
    length(X) == 1 && return :(conj($x))
    reduce(mul, (map(conj, X)))
end

isconj(x) = false
isconj(x::Expr) = iscall(x) && x.args[1] == :conj

# transpose

transpose(x) = Base.transpose(x)
transpose(x::Symbol) = :($x.')
function transpose(x::Expr)
    isconj(x) && return ctranspose(x.args[2])
    istranspose(x) && return x.args[1]
    isctranspose(x) && return conj(x.args[1])

    isadd(x) && return reduce(add, map(transpose, unroll_expr(x, :+)))

    X = mulunroll(x)
    length(X) == 1 && return :($x.')
    reduce(mul, (map(transpose, reverse(X))))
end

istranspose(x) = false
istranspose(x::Expr) = iscall(x) && x.args[1] == Symbol(".'")

# ctranspose

ctranspose(x) = Base.ctranspose(x)
ctranspose(x::Symbol) = :($x')
function ctranspose(x::Expr)
    isconj(x) && return transpose(x.args[2])
    istranspose(x) && return conj(x.args[1])
    isctranspose(x) && return x.args[1]

    isadd(x) && return reduce(add, map(ctranspose, unroll_expr(x, :+)))

    X = mulunroll(x)
    length(X) == 1 && return :($x')
    reduce(mul, (map(ctranspose, reverse(X))))
end

isctranspose(x) = false
isctranspose(x::Expr) = iscall(x) && x.args[1] == Symbol("'")
