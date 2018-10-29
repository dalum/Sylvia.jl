"""
    cse

Common subexpression elimination.

"""
function cse end

"""
    normalorder

Sort by commuting adjacent elements.

"""
function normalorder(op, x::Sym{TAG}) where {TAG}
    if x.head === :call
        args = map(arg -> normalorder(op, arg), x.args[2:end])
    else
        return x
    end

    if x.args[1] !== op
        return Sym{TAG}(x.head, x.args[1], args...)
    end

    args = collect(args)
    sort!(args, alg=InsertionSort, lt=(a, b) -> _commute_lt(op, a, b))
    return apply(op, args...)
end
_commute_lt(op, a, b) = (commuteswith(op, a, b) === true || commuteswith(op, b, a) === true) && isless(string(a), string(b))

"""
    rle

Run length encode.

"""
rle(op, enc_op, x) = x
function rle(op, enc_op, x::Sym{TAG}) where {TAG}
    if x.head === :call
        in_args = map(arg -> rle(op, enc_op, arg), x.args[2:end])
    else
        return x
    end

    if x.args[1] !== op
        return Sym{TAG}(x.head, x.args[1], in_args...)
    end

    N = length(in_args)
    out_args = []
    n = 1
    for i in 1:N
        if i < N && in_args[i] === in_args[i+1]
            n += 1
        else
            if n > 1
                push!(out_args, enc_op(in_args[i], n))
            else
                push!(out_args, in_args[i])
            end
            n = 1
        end
    end
    return apply(op, out_args...)
end

##################################################
# Special cases
##################################################

function gather(x::Sym)
    x = normalorder(+, x)
    x = normalorder(*, x)
    x = rle(+, *, x)
    x = rle(*, ^, x)
    return x
end
