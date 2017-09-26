using Base.Iterators: flatten, product

for op in (:+, :-, :exp, :log, :sqrt,
           :cos, :sin, :tan, :sec, :csc, :cot, :cosh, :sinh, :tanh, :sech, :csch, :coth,
           :acos, :asin, :atan, :asec, :acsc, :acot, :acosh, :asinh, :atanh, :asech, :acsch, :acoth)
    name = :(Base.$op)
    @eval $name(x::Symbolic{<:Number}) = Symbolic($name(x.value))
    @eval $name(x::Symbolic{<:AbstractArray}) = Symbolic($name(x.value))
end

for op in (:+, :-, :*, :/, :\, ://, :^, :÷)
    name = :(Base.$op)
    @eval $name(x::Symbolic{<:Number}, y::Symbolic{<:Number}) = Symbolic($name(x.value, y.value))
    @eval $name(x::Symbolic{<:AbstractArray}, y::Symbolic{<:AbstractArray}) = Symbolic($name(x.value, y.value))
end

isnegative(x) = false
isnegative(x::Symbolic) = isnegative(value(x))
isnegative(x::UniformScaling) = x.λ < 0
isnegative(x::Real) = x < 0
isnegative(x::Complex) = real(x) < 0
isnegative(x::Symbolic{Expr}) = iscall(:-, x) && length(value(x).args) == 2

isadd(x) = iscall(:+, x) && length(value(x).args) >= 3
issub(x) = iscall(:-, x) && length(value(x).args) == 3
ismul(x) = iscall(:*, x)
isdiv(x) = iscall(:/, x)
isidiv(x) = iscall(:\, x)
isrdiv(x) = iscall(://, x)
ispow(x) = iscall(:^, x)
isinv(x) = iscall(:inv) || ispow(x) && isnegative(x.value.args[3])
isconj(x) = iscall(:conj, x)
istranspose(x) = iscall(:(.'), x)
isadjoint(x) = iscall(Symbol("'"), x)

# sign

Base.sign(x::Symbolic) = isnegative(x) ? -identity_element(*, x, :left) : identity_element(*, x, :left)
# signed(s, x) = isnegative(s) ? -x : x

# neg

Base.:(==)(x::Symbolic, y::Symbolic) = false
Base.:(==)(x::Symbolic{T,C}, y::Symbolic{T,C}) where {T,C} = x.value == y.value# && x.properties == y.properties

Base.:-(x::Symbolic) = Symbolic(-value(x))
Base.:-(x::Symbolic{Symbol}) = derived(-, x)
function Base.:-(x::Symbolic{Expr})
    xs = factorize(+, x)
    if length(xs) > 1
        return Expr(:call, :+, (-).(xs)...)
    end
    if isnegative(x)
        return value(x).args[2]
    elseif issub(x)
        return value(x).args[3] - value(x).args[2]
    end
    derived(-, x)
end

# collapse

function countrepeated(input::AbstractVector{T}) where T
    a = input[1]
    i = 1
    output = Tuple{T, Int64}[]
    for b in input[2:end]
        if a == b
            i += 1
        else
            push!(output, (a, i))
            a = b
            i = 1
        end
    end
    push!(output, (a, i))
    return output
end

function expand(x::Symbolic)
    F = factorize(+, x)
    for i in length(F)
        FF = factorize(*, F[i])
        prod = collect(product(factorize.(+, FF.data)...))
        F.data[i] = mapreduce(x->reduce((xx,yy)->derived(*, xx, yy), x), (x,y)->derived(+, x, y), prod)
        println(prod)
    end
    return reduce(F)
end

function collapse(::typeof(+), input::AbstractVector{<:Symbolic})
    output = Symbolic[]
    a = factorize(*, input[1])

    if a[1] isa Symbolic{<:Number}
        i, a = a[1], reduce(a[2:end])
    else
        i, a = a[0], reduce(a)
    end

    for b in input[2:end]
        if all(x->x isa Symbolic{<:Number}, (a, i, b))
            a = i * a * b
            continue
        end

        b = factorize(*, b)
        if b[1] isa Symbolic{<:Number}
            j, b = b[1], reduce(b[2:end])
        else
            j, b = b[0], reduce(b)
        end

        if a == b
            i += j
        else
            !iszero(a) && !iszero(i) && push!(output, isone(i) ? a : i * a)
            a, i = b, j
        end
    end
    # Push final element
    !iszero(a) && !iszero(i) && push!(output, isone(i) ? a : i * a)

    if length(output) == 0
        return [ZERO]
    end
    if length(output) == 1
        return output
    end
    return output
end

function collapse(::typeof(*), input::AbstractVector{<:Symbolic})
    output = Symbolic[]
    a, p = factorize(^, input[1])[1:2]

    for b in input[2:end]
        if all(x->x isa Symbolic{<:Number}, (a, p, b))
            a = a^p * b
            continue
        end

        b, q = factorize(^, b)[1:2]
        if b == a
            p += q
        else
            !isone(a) && !iszero(p) && push!(output, isone(p) ? a : a^p)
            a, p = b, q
        end
    end
    # Push final element
    if (!isone(a) && !iszero(p)) || length(output) == 0
        push!(output, iszero(p) ? ONE : isone(p) ? a : a^p)
    end
    if length(output) == 1
        return output
    end

    # Remove leading sign
    if output[1] isa Symbolic{<:Number} && isnegative(output[1]) && isone(-output[1])
        output[2] = -output[2]
        return output[2:end]
    end
    return output
end

# add

Base.:+(x::Symbolic, y::Symbolic) = derived(+, x, y)
Base.:+(x::SymbolOrExpr, y::SymbolOrExpr) = add(x, y)
Base.:+(x::SymbolOrExpr, y::Symbolic) = add(x, y)
Base.:+(x::Symbolic, y::SymbolOrExpr) = add(x, y)

function add(xs::Symbolic...)::Symbolic
    xs = collect(Symbolic, flatten(factorize.(+, xs)))
    xs = collapse(+, commutesort(+, xs))
    filter!(x->!iszero(x), xs)

    if length(xs) == 0
        return ZERO
    elseif length(xs) == 1
        return xs[1]
    end

    commutesort(+, xs, lt=isless, by=isnegative)
    addexpr = derived(+, xs...)
end

# sub

Base.:-(x::Symbolic, y::Symbolic) = derived(-, x, y)
Base.:-(x::SymbolOrExpr, y::SymbolOrExpr) = subtract(x, y)
Base.:-(x::SymbolOrExpr, y::Symbolic) = subtract(x, y)
Base.:-(x::Symbolic, y::SymbolOrExpr) = subtract(x, y)

subtract(x, y) = add(x, -y)

# mul

Base.:*(x::Symbolic, y::Symbolic) = derived(*, x, y)
Base.:*(x::SymbolOrExpr, y::SymbolOrExpr) = multiply(x, y)
Base.:*(x::SymbolOrExpr, y::Symbolic) = multiply(x, y)
Base.:*(x::Symbolic, y::SymbolOrExpr) = multiply(x, y)

function multiply(xs::Symbolic...)::Symbolic
    xs = collect(Symbolic, flatten(factorize.(*, xs)))
    if any(iszero, xs)
        return ZERO
    end
    xs = collapse(*, commutesort(*, xs))
    filter!(x->!isone(x), xs)

    if length(xs) == 0
        return ONE
    elseif length(xs) == 1
        return xs[1]
    end

    # # Sort out division
    # divargs = []
    # a, i = split_expr(pop!(args), :^)
    # while length(args) > 0 && isnegative(i)
    #     push!(divargs, isone(neg(i)) ? a : pow(a, neg(i)))
    #     a, i = split_expr(pop!(args), :^)
    # end
    # if isnegative(i)
    #     push!(divargs, isone(neg(i)) ? a : pow(a, neg(i)))
    #     push!(args, 1)
    # else
    #     push!(args, iszero(i) ? 1 : isone(i) ? a : pow(a, i))
    # end

    mulexpr = derived(*, xs...)
    # return isnegative(s) ? -mulexpr : mulexpr
    # divexpr = mulcollect(sort(divargs, lt=mulorder))

    # sign(s, isone(divexpr) ? mulexpr : :($mulexpr / $divexpr))
end

# div

div(x::Number, y::Number) = x / y
div(x::Union{Symbol, Expr}, y::Number) = isone(y) ? x : _div(x, y)
div(x::Number, y::Union{Symbol, Expr}) = iszero(x) && !iszero(y) ? 0 : isone(x) ? inv(y) : _div(x, y)
div(x, y) = _div(x, y)

_div(x, y) = mul(x, inv(y))

idiv(x::Number, y::Number) = x \ y
idiv(x::Union{Symbol, Expr}, y::Number) = iszero(y) && !iszero(x) ? 0 : isone(y) ? inv(x) : _idiv(x, y)
idiv(x::Number, y::Union{Symbol, Expr}) = isone(x) ? y : _idiv(x, y)
idiv(x, y) = _idiv(x, y)

_idiv(x, y) = mul(inv(x), y)

rdiv(x::Number, y::Number) = x // y
rdiv(x::Union{Symbol, Expr}, y::Number) = isone(y) ? x : _rdiv(x, y)
rdiv(x::Number, y::Union{Symbol, Expr}) = _rdiv(x, y)
rdiv(x, y) = x == y ? 1 : _rdiv(x, y)

_rdiv(x, y) = :($x // $y)

# pow

Base.:^(x::Symbolic, y::Symbolic) = derived(^, x, y)
Base.:^(x::SymbolOrExpr, y::SymbolOrExpr) = pow(x, y)
Base.:^(x::SymbolOrExpr, y::Symbolic) = pow(x, y)
Base.:^(x::Symbolic, y::SymbolOrExpr) = pow(x, y)

function pow(x, y)
    isone(y) ? x : derived(^, x, y)
end

# pow(x::Union{Symbol, Expr}, n::Number) = iszero(n) ? 1 : isone(n) ? x : _pow(x, n)
# pow(n::Number, x::Union{Symbol, Expr}) = isone(n) ? n : _pow(n, x)
# pow(x, y) = _pow(x, y)

# function _pow(x, y)
#     s, x = sign(x)
#     x, i = split_expr(x, :^)
#     i, j = split_expr(i, :*)
#     y = mul(y, isone(i) ? j : mul(i, j))
#     iszero(y) && return 1

#     if isdiv(x) && isnegative(y)
#         x = div(reverse(split_expr(x, :/))...)
#         y = neg(y)
#     end
#     x = sign(s, x)
#     isone(y) ? x : :(($x) ^ $y)
# end

# inv

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
