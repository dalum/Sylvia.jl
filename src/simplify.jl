"""
    cse

Common subexpression elimination.

"""
function cse(x::Sym, subxs = Dict{Sym,Sym}())
    if hashead(x, :call)
        args = tailargs(x)
    else
        args = getargs(x)
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
normalorder(x::Sym, op::Sym) = normalorder!(deepcopy(x), op)

normalorder!(x, op) = x
function normalorder!(x::Sym, op::Sym)
    isatomic(x) && return x
    map(a -> normalorder!(a, op), getargs(x))
    (hashead(x, :call) && (firstarg(x) == op) === true) || return x
    sort!(getargs(x), alg=InsertionSort, lt=(a, b) -> _commute_lt(op, a, b))
    return x
end
function _commute_lt(op, a, b)
    return (commuteswith(op, a, b) === true || commuteswith(op, b, a) === true) && isless(string(a), string(b))
end

"""
    rle

Run length encode.

"""
rle(x::Sym, op::Sym, enc_op::Sym) = rle!(deepcopy(x), op, enc_op)

rle!(x, op, enc_op) = x
function rle!(x::Sym, op::Sym, enc_op::Sym)
    isatomic(x) && return x
    map(a -> rle!(a, op, enc_op), getargs(x))
    (hashead(x, :call) && (firstarg(x) == op) === true) || return x

    N = length(getargs(x))
    args = []
    n = 1
    for i in 1:N
        if i < N && (getargs(x, i) == getargs(x, i + 1)) === true
            n += 1
        else
            if n > 1
                push!(args, firstarg(enc_op)(getargs(x, i), n))
            else
                push!(args, getargs(x, i))
            end
            n = 1
        end
    end
    return setargs!(x, args)
end

"""
    remove_identities(x, op, isidentity)

Remove identities of the operator `op`.  `isidentity` is a function that
returns true, if the element is an identity element of `op`.

"""
remove_identities(x::Sym, op::Sym, isidentity::Sym) = remove_identities!(deepcopy(x), op, isidentity)

remove_identities!(x, op, isidentity) = x
function remove_identities!(x::Sym, op::Sym, isidentity::Sym)
    isatomic(x) && return x
    map(a -> remove_identities!(a, op, isidentity), getargs(x))
    (hashead(x, :call) && (firstarg(x) == op) === true) || return x
    args = getargs(x)
    deleteat!(
        args,
        findall(
            arg -> firstarg(isidentity)(arg) === true,
            args
        )
    )
    return query!(x)
end

"""
    resolve_absorbing(x, op, isabsorbing)

Resolves absorbing elements of the operator `op`.  `isabsorbing` is a
function that returns true, if the element is an absorbing element of
`op`

"""
resolve_absorbing(x::Sym, op::Sym, isabsorbing::Sym) = resolve_absorbing!(deepcopy(x), op, isabsorbing)

resolve_absorbing!(x, op, isabsorbing) = x
function resolve_absorbing!(x::Sym, op::Sym, isabsorbing::Sym)
    isatomic(x) && return x
    map(a -> resolve_absorbing!(a, op, isabsorbing), getargs(x))
    (hashead(x, :call) && (firstarg(x) == op) === true) || return x
    args = getargs(x)
    absorber_index = findfirst(arg -> firstarg(isabsorbing)(arg) === true, args)
    absorber_index === nothing && return x
    setargs!(x, Any[firstarg(x), getargs(x, absorber_index)])
    return query!(x)
end

split_reapply(x::Sym, op::Sym) = split_reapply!(deepcopy(x), op)

split_reapply!(x, op) = x
function split_reapply!(x::Sym{TAG}, op::Sym) where TAG
    isatomic(x) && return x
    map(a -> split_reapply!(a, op), getargs(x))
    (hashead(x, :call) && (firstarg(x) == op) === true) || return x
    args = []
    for arg in getargs(x)
        if hashead(arg, :call) && (firstarg(arg) == op) === true
            append!(args, tailargs(arg))
        else
            push!(args, arg)
        end
    end
    return setargs!(x, args)
end

##################################################
# Multi-algorithms
##################################################

const MAX_GATHER_ITERATIONS = 10

gather(x) = gather!(deepcopy(x))
function gather!(x)
    x_ = x
    for _ in 1:MAX_GATHER_ITERATIONS
        x = _gather_one_iteration!(x_)
        if x == x_ === true
            break
        else
            x_ = x
        end
    end
    return x
end

_gather_one_iteration!(x) = x
function _gather_one_iteration!(x::Sym)
    remove_identities!(x, Sym(+), Sym(iszero))
    remove_identities!(x, Sym(*), Sym(isone))
    resolve_absorbing!(x, Sym(*), Sym(iszero))
    split_reapply!(x, Sym(+))
    split_reapply!(x, Sym(*))
    normalorder!(x, Sym(+))
    normalorder!(x, Sym(*))
    rle!(x, Sym(+), Sym(*))
    rle!(x, Sym(*), Sym(^))

    remove_identities!(x, Sym(|), Sym(isfalse))
    remove_identities!(x, Sym(&), Sym(istrue))
    resolve_absorbing!(x, Sym(|), Sym(istrue))
    resolve_absorbing!(x, Sym(&), Sym(isfalse))
    normalorder!(x, Sym(&))
    normalorder!(x, Sym(|))

    return x
end
