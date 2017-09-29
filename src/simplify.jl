function nextwhile(f, xs, offset::Integer = 0)
    output = []
    i = start(xs)
    if done(xs, i)
        return output, i + offset
    end
    while !done(xs, i)
        x, i = next(xs, i)
        if f(x)
            push!(output, x)
        else
            i -= 1
            break
        end
    end
    return output, i + offset
end

# collapse

"""
    expand(x)
"""
function expand(x::Symbolic)
    F = factorize(+, x)
    for i in length(F)
        FF = factorize(*, F[i])
        prod = collect(product(factorize.(+, FF.data)...))
        F.data[i] = mapreduce(x->reduce((xx,yy)->derived(*, xx, yy), x), (x,y)->derived(+, x, y), prod)
    end
    return reduce(F)
end

#="""
    collapse(op, xs::Vector)
"""=#
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

    # # Remove leading sign
    # if output[1] isa Symbolic{<:Number} && isnegative(output[1]) && isone(-output[1])
    #     output[2] = -output[2]
    #     return output[2:end]
    # end
    return output
end
