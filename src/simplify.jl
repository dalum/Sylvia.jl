# """
#     cse

# Common subexpression elimination.

# """
# function cse(x::Sym, subxs = Dict{Sym,Sym}())
#     if hashead(x, :call)
#         args = tailargs(x)
#     else
#         args = getargs(x)
#     end

#     for i in eachindex(args)
#         if args[i] in keys(subxs)
#             args[i] = subxs[args[i]]
#         else
#             args[i] = subxs[args[i]] = Sym{tagof(args[i])}(gensym())
#         end
#     end
#     return args, subxs
# end

"""
    normalorder

Sort by commuting adjacent elements.

"""
normalorder(x::Sym, op::Sym; kwargs...) = normalorder!(deepcopy(x), op; kwargs...)

normalorder!(x, op; kwargs...) = x
function normalorder!(x::Sym, op::Sym; context::Context = @__context__(), kwargs...)
    isatomic(x) && return x
    map(a -> normalorder!(a, op; context=context), getargs(x))
    (hashead(x, :call) && (firstarg(x) == op) === true) || return x
    sort!(getargs(x), alg=InsertionSort, lt=(a, b) -> _commute_lt(op, a, b; context=context))
    return query!(x, context=context)
end

function _commute_lt(op, a, b; context::Context)
    return @scope context begin
        (commuteswith(op, a, b) === true ||
         commuteswith(op, b, a) === true) &&
         isless(string(a), string(b))
    end
end

"""
    rle

Run length encode.

"""
rle(x::Sym, op::Sym, enc_op::Sym; kwargs...) = rle!(deepcopy(x), op, enc_op; kwargs...)

rle!(x, op, enc_op; kwargs...) = x
function rle!(x::Sym, op::Sym, enc_op::Sym; context::Context = @__context__(), kwargs...)
    isatomic(x) && return x
    map(a -> rle!(a, op, enc_op, context=context), getargs(x))
    (hashead(x, :call) && (firstarg(x) == op) === true) || return x

    N = length(getargs(x))
    args = []
    n = 1
    for i in 1:N
        if i < N && (getargs(x, i) == getargs(x, i + 1)) === true
            n += 1
        else
            if n > 1
                push!(args, @scope context firstarg(enc_op)(getargs(x, i), n))
            else
                push!(args, getargs(x, i))
            end
            n = 1
        end
    end
    return query!(setargs!(x, args), context=context)
end

"""
    remove_identities(x, op, isidentity)

Remove identities of the operator `op`.  `isidentity` is a function that
returns true, if the element is an identity element of `op`.

"""
remove_identities(x::Sym, op::Sym, isidentity::Sym; kwargs...) = remove_identities!(deepcopy(x), op, isidentity; kwargs...)

remove_identities!(x, op, isidentity; kwargs...) = x
function remove_identities!(x::Sym, op::Sym, isidentity::Sym; context::Context = @__context__)
    isatomic(x) && return x
    map(a -> remove_identities!(a, op, isidentity, context=context), getargs(x))
    (hashead(x, :call) && (firstarg(x) == op) === true) || return x
    args = getargs(x)
    deleteat!(
        args,
        findall(
            arg -> @scope(context, firstarg(isidentity)(arg)) === true,
            args
        )
    )
    return query!(x, context=context)
end

"""
    resolve_absorbing(x, op, isabsorbing)

Resolves absorbing elements of the operator `op`.  `isabsorbing` is a
function that returns true, if the element is an absorbing element of
`op`

"""
resolve_absorbing(x::Sym, op::Sym, isabsorbing::Sym; kwargs...) = resolve_absorbing!(deepcopy(x), op, isabsorbing; kwargs...)

resolve_absorbing!(x, op, isabsorbing; kwargs...) = x
function resolve_absorbing!(x::Sym, op::Sym, isabsorbing::Sym; context::Context = @__context__)
    isatomic(x) && return x
    map(a -> resolve_absorbing!(a, op, isabsorbing, context=context), getargs(x))
    (hashead(x, :call) && (firstarg(x) == op) === true) || return x
    args = getargs(x)
    absorber_index = findfirst(arg -> @scope(context, firstarg(isabsorbing)(arg)) === true, args)
    absorber_index === nothing && return x
    setargs!(x, Any[firstarg(x), getargs(x, absorber_index)])
    return query!(x, context=context)
end

split_reapply(x::Sym, op::Sym; kwargs...) = split_reapply!(deepcopy(x), op; kwargs...)

split_reapply!(x, op; kwargs...) = x
function split_reapply!(x::Sym{TAG}, op::Sym; context::Context = @__context__) where TAG
    isatomic(x) && return x
    map(a -> split_reapply!(a, op, context=context), getargs(x))
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

gather(x; kwargs...) = gather!(deepcopy(x); kwargs...)
function gather!(x; context::Context = @__context__)
    x_ = deepcopy(x)
    for _ in 1:MAX_GATHER_ITERATIONS
        _gather_one_iteration!(x_; context=context)
        if (x == x_) === true
            break
        else
            x, x_ = x_, deepcopy(x_)
        end
    end
    return query!(x_, context=context)
end

_gather_one_iteration!(x; kwargs...) = x
function _gather_one_iteration!(x::Sym; context::Context = @__context__)
    remove_identities!(x, Sym(+), Sym(iszero), context=context)
    remove_identities!(x, Sym(*), Sym(isone), context=context)
    resolve_absorbing!(x, Sym(*), Sym(iszero), context=context)
    split_reapply!(x, Sym(+), context=context)
    split_reapply!(x, Sym(*), context=context)
    normalorder!(x, Sym(+), context=context)
    normalorder!(x, Sym(*), context=context)
    rle!(x, Sym(+), Sym(*), context=context)
    rle!(x, Sym(*), Sym(^), context=context)

    remove_identities!(x, Sym(|), Sym(isfalse), context=context)
    remove_identities!(x, Sym(&), Sym(istrue), context=context)
    resolve_absorbing!(x, Sym(|), Sym(istrue), context=context)
    resolve_absorbing!(x, Sym(&), Sym(isfalse), context=context)
    normalorder!(x, Sym(&), context=context)
    normalorder!(x, Sym(|), context=context)

    return x
end
