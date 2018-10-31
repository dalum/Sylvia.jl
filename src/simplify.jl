"""
    cse

Common subexpression elimination.

"""
function cse(x::Sym, subxs = Dict{Sym,Sym}())
    if hashead(x, :call)
        args = collect(tailargs(x))
    else
        args = collect(getargs(x))
    end

    for i in eachindex(args)
        if args[i] in keys(subxs)
            args[i] = subxs[args[i]]
        else
            args[i] = subxs[args[i]] = Sym{tagof(args[i])}(gensym())
        end
    end
    return args, subxs
end

"""
    normalorder

Sort by commuting adjacent elements.

"""
normalorder(op, x) = x
function normalorder(op, x::Sym{TAG}) where {TAG}
    if x.head === :call
        args = map(arg -> normalorder(op, arg), tailargs(x))
    else
        return x
    end

    if firstarg(x) !== op
        return Sym{TAG}(x.head, firstarg(x), args...)
    end

    args = collect(args)
    sort!(args, alg=InsertionSort, lt=(a, b) -> _commute_lt(op, a, b))
    return apply(op, args...)
end
function _commute_lt(op, a, b)
    return (commuteswith(op, a, b) === true || commuteswith(op, b, a) === true) && isless(string(a), string(b))
end

"""
    rle

Run length encode.

"""
rle(op, enc_op, x) = x
function rle(op, enc_op, x::Sym{TAG}) where {TAG}
    if x.head === :call
        in_args = map(arg -> rle(op, enc_op, arg), tailargs(x))
    else
        return x
    end

    if firstarg(x) !== op
        return Sym{TAG}(x.head, firstarg(x), in_args...)
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

"""
    remove_identities(op, isidentity, x)

Remove identities of the operator `op`.  `isidentity` is a function that
returns true, if the element is an identity element of `op`.

"""
remove_identities(op, isidentity, x) = x
function remove_identities(op, isidentity, x::Sym{TAG}) where TAG
    if hashead(x, :call)
        in_args = map(a -> remove_identities(op, isidentity, a), tailargs(x))
    else
        return x
    end

    if firstarg(x) !== op
        return Sym{TAG}(:call, firstarg(x), in_args...)
    end

    out_args = []
    for arg in in_args
        if isidentity(arg) !== true
            push!(out_args, arg)
        end
    end
    if length(out_args) == 0
        push!(out_args, in_args[end])
    end
    return Sym{TAG}(:call, firstarg(x), out_args...)
end

"""
    resolve_absorbing(op, isabsorbing, x)

Resolves absorbing elements of the operator `op`.  `isabsorbing` is a
function that returns true, if the element is an absorbing element of
`op`

"""
resolve_absorbing(op, isabsorbing, x) = x
function resolve_absorbing(op, isabsorbing, x::Sym{TAG}) where TAG
    if hashead(x, :call)
        args = map(a -> resolve_absorbing(op, isabsorbing, a), tailargs(x))
    else
        return x
    end

    if firstarg(x) !== op
        return Sym{TAG}(:call, firstarg(x), args...)
    end

    for arg in args
        if isabsorbing(arg) === true
            args = [arg]
            break
        end
    end
    return Sym{TAG}(:call, firstarg(x), args...)
end

##################################################
# Multi-algorithms
##################################################

const MAX_GATHER_ITERATIONS = 10

function gather(x)
    x_ = x
    for _ in 1:MAX_GATHER_ITERATIONS
        x = _gather_one_iteration(x_)
        if x === x_
            break
        else
            x_ = x
        end
    end
    return x
end

function _gather_one_iteration(x::Sym)
    x = remove_identities(+, iszero, x)
    x = remove_identities(*, isone, x)
    x = resolve_absorbing(*, iszero, x)
    x = normalorder(+, x)
    x = normalorder(*, x)
    x = rle(+, *, x)
    x = rle(*, ^, x)

    x = remove_identities(|, isfalse, x)
    x = remove_identities(&, istrue, x)
    x = resolve_absorbing(|, istrue, x)
    x = resolve_absorbing(&, isfalse, x)
    x = normalorder(&, x)
    x = normalorder(|, x)

    return x
end
