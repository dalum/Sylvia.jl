using Base.Iterators: flatten, product

for op in (:+, :-, :exp, :log, :sqrt,
           :cos, :sin, :tan, :sec, :csc, :cot, :cosh, :sinh, :tanh, :sech, :csch, :coth,
           :acos, :asin, :atan, :asec, :acsc, :acot, :acosh, :asinh, :atanh, :asech, :acsch, :acoth)
    name = :(Base.$op)
    @eval $name(x::Symbolic{<:Number}) = Symbolic($name(x.value))
    @eval $name(x::Symbolic{<:AbstractArray}) = Symbolic($name(x.value))
    @eval $name(x::SymbolOrExpr) = derived($name, x)
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
function isnegative(x::Symbolic{Expr})
    if isnegation(x)
        return true
    end
    if iscall(:*, x) && isnegative(value(x).args[2])
        return true
    end
    return false
end

isnegation(x::Symbolic{Expr}) = iscall(:-, x) && length(value(x).args) == 2
isadd(x) = iscall(:+, x) && length(value(x).args) >= 3
issub(x) = iscall(:-, x) && length(value(x).args) == 3
ismul(x) = iscall(:*, x)
isdiv(x) = iscall(:/, x)
isidiv(x) = iscall(:\, x)
isrdiv(x) = iscall(://, x)
ispow(x) = iscall(:^, x)
isinv(x) = iscall(x) && ispow(x) && isnegative(value(x).args[3])
isconj(x) = iscall(:conj, x)
istranspose(x) = x isa Symbolic{Expr} && value(x).head == Symbol(".'")
isadjoint(x) = x isa Symbolic{Expr} && value(x).head == Symbol("'")

# sign
Base.sign(x::Symbolic) = isnegative(x) ? -identity_element(*, x, :left) : identity_element(*, x, :left)

# equality

Base.:(==)(x::Symbolic, y::Symbolic) = false
Base.:(==)(x::Symbolic{T,C}, y::Symbolic{T,C}) where {T,C} = x.value == y.value# && x.properties == y.properties

# negation

Base.:-(x::Symbolic) = Symbolic(-value(x))
Base.:-(x::Symbolic{Symbol}) = derived(-, x)
function Base.:-(x::Symbolic{Expr})
    F = factorize(+, x)
    if length(F) > 1
        return reduce(+, (-).(F.data))
    end
    if isnegation(x)
        return value(x).args[2]
    elseif issub(x)
        return value(x).args[3] - value(x).args[2]
    end
    derived(-, x)
end

# collapse

function expand(x::Symbolic)
    F = factorize(+, x)
    for i in length(F)
        FF = factorize(*, F[i])
        prod = collect(product(factorize.(+, FF.data)...))
        F.data[i] = mapreduce(x->reduce((xx,yy)->derived(*, xx, yy), x), (x,y)->derived(+, x, y), prod)
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
        if all(x->x isa Symbolic{<:Number}, (i, a, b))
            i = i * a + b
            a = ONE
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

    commutesort!(+, xs, by=isnegative)
    addexpr = derived(+, xs...)
end

# sub

Base.:-(x::Symbolic, y::Symbolic) = derived(-, x, y)
Base.:-(x::SymbolOrExpr, y::SymbolOrExpr) = subtract(x, y)
Base.:-(x::SymbolOrExpr, y::Symbolic) = subtract(x, y)
Base.:-(x::Symbolic, y::SymbolOrExpr) = subtract(x, y)

subtract(x, y)::Symbolic = x + -y

# mul

Base.:*(x::Symbolic, y::Symbolic) = derived(*, x, y)
Base.:*(x::SymbolOrExpr, y::SymbolOrExpr) = multiply(x, y)
Base.:*(x::SymbolOrExpr, y::Symbolic) = multiply(x, y)
Base.:*(x::Symbolic, y::SymbolOrExpr) = multiply(x, y)

function multiply(xs::Symbolic...)::Symbolic
    xs = collect(Symbolic, flatten(factorize.(*, xs)))
    if any(iszero, xs) && !any(isinf, xs)
        return ZERO
    end
    xs = collapse(*, commutesort(*, xs))
    filter!(x->!isone(x), xs)

    if length(xs) == 0
        return ONE
    elseif length(xs) == 1
        return xs[1]
    end

    xs = commutesort(*, xs, lt=isless, by=isinv)
    mulexpr = derived(*, xs...)
end

# div

Base.:/(x::Symbolic, y::Symbolic) = x * inv(y)
Base.:\(x::Symbolic, y::Symbolic) = inv(x) * y

# pow

Base.:^(x::Symbolic, y::Symbolic) = derived(^, x, y)
Base.:^(x::SymbolOrExpr, y::SymbolOrExpr) = pow(x, y)
Base.:^(x::SymbolOrExpr, y::Symbolic) = pow(x, y)
Base.:^(x::Symbolic, y::SymbolOrExpr) = pow(x, y)

function pow(x, y)::Symbolic
    x, i = factorize(^, x)[1:2]
    y = i * y
    if iszero(y)
        return one(x)
    end
    if isone(x)
        return x
    end
    isone(y) ? x : derived(^, x, y)
end

# inv

Base.inv(x::Symbolic) = x^-1
Base.inv(x::Symbolic{<:Number}) = Symbolic(inv(value(x)))
function Base.inv(A::StridedMatrix{<:Symbolic})
    Base.LinAlg.checksquare(A)
    AA = convert(AbstractArray{Symbolic}, A)
    if istriu(AA)
        AA = UpperTriangular(AA)
        Ai = A_ldiv_B!(AA, eye(Symbolic, size(AA, 1)))
    elseif istril(AA)
        AA = LowerTriangular(AA)
        Ai = A_ldiv_B!(AA, eye(Symbolic, size(AA, 1)))
    else
        Ai = Base.LinAlg.inv!(lufact(AA))
    end
    Ai = convert(AbstractArray{typejoin(typeof.(Ai)...)}, Ai)
    return Ai
end

function Base.lufact(A::AbstractMatrix{<:Symbolic})
    AA = similar(A, Symbolic, size(A))
    copy!(AA, A)
    F = lufact!(AA, Val(false))
    if Base.LinAlg.issuccess(F)
        return F
    else
        AA = similar(A, Symbolic, size(A))
        Base.LinAlg.copy!(AA, A)
        return lufact!(AA, Val(true))
    end
end


# conj

Base.conj(x::Symbolic{Symbol}) = derived(conj, x)
function Base.conj(x::Symbolic{Expr})
    isconj(x) && return value(x).args[2]
    istranspose(x) && return adjoint(value(x).args[1])
    isadjoint(x) && return transpose(value(x).args[1])
    derived(conj, x)
end

# transpose

Base.transpose(x::Symbolic{Symbol}) = derived(transpose, x)
function Base.transpose(x::Symbolic{Expr})
    isconj(x) && return adjoint(value(x).args[2])
    istranspose(x) && return value(x).args[1]
    isadjoint(x) && return conj(value(x).args[1])
    derived(transpose, x)
end

# adjoint

Base.adjoint(x::Symbolic{Symbol}) = derived(adjoint, x)
function Base.adjoint(x::Symbolic{Expr})
    isconj(x) && return transpose(value(x).args[2])
    istranspose(x) && return conj(value(x).args[1])
    isadjoint(x) && return value(x).args[1]
    derived(adjoint, x)
end
