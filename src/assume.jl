include("stackeddict.jl")

const AssumptionStack = StackedDict{Sym,Any}

const GLOBAL_ASSUMPTION_STACK = AssumptionStack()

macro assumptions()
    return :(GLOBAL_ASSUMPTION_STACK)
end

query(x::Sym) = query(GLOBAL_ASSUMPTION_STACK, x)
function query(as::AssumptionStack, x::Sym)::Union{typeof(x), Missing}
    for i in length(as.keys):-1:1
        m = match(x, as.keys[i])
        if ismatch(m)
            return substitute(as.vals[i], filter(y -> !(y isa Bool), m)...)
        end
    end
    return missing
end

assume(x::Sym{T}, val::Union{Sym{T}, T}) where {T} = assume(GLOBAL_ASSUMPTION_STACK, x, val)
assume(as::AssumptionStack, x::Sym{T}, val::Union{Sym{T}, T}) where {T} = push!(as, x => val)

const INTERCEPT_OPS = (:!, :(==), :<, :(!=))

macro assume(xs...)
    ret = Expr(:block)
    for x in xs
        x, val = preprocess_assumption(x)
        push!(ret.args, :(assume($x, $val)))
    end
    return ret
end

unassume(x::Sym) = unassume(GLOBAL_ASSUMPTION_STACK, x)
unassume(x::Sym, val) = unassume(GLOBAL_ASSUMPTION_STACK, x, val)
unassume(as::AssumptionStack, x::Sym) = (popall!(as, x); as)
unassume(as::AssumptionStack, x::Sym, val) = (pop!(as, x => val); as)

macro unassume(xs...)
    ret = Expr(:block)
    for x in xs
        x, val = preprocess_assumption(x)
        push!(ret.args, :(unassume($x, $val)))
    end
    return ret
end

##################################################
# Pre-processing
##################################################

function preprocess_assumption(x)
    if Meta.isexpr(x, :call) && x.args[1] === :(=>)
        x, val = x.args[2:end]
        val = esc(val)
    else
        val = true
        converged = false
        while !converged
            x_, val_ = assume_intercept(x, val)
            converged = x_ === x && val_ === val
            x, val = x_, val_
        end
    end
    if Meta.isexpr(x, :call)
        x = :(_apply($(map(esc, x.args)...)))
    elseif Meta.isexpr(x, (:(.), :ref, Symbol("'")))
        x = :(_combine($(esc(Meta.quot(x.head))), $(map(esc, x.args)...)))
    else
        x = esc(x)
    end

    return x, val
end

function assume_intercept(x, val)
    @assert Meta.isexpr(x, :call) "$x"
    if firstarg(x) in INTERCEPT_OPS
        if firstarg(x) === :!
            x = x.args[2]
            val = !val
        elseif x.args[1] === :(!=)
            x.args[1] = :(==)
            val = !val
        end
    end
    return x, val
end

assuming(f, pairs::Pair{<:Sym,<:Any}...) = assuming(f, GLOBAL_ASSUMPTION_STACK, pairs...)
function assuming(f, as::AssumptionStack, pairs::Pair{<:Sym,<:Any}...)
    for pair in pairs
        assume(as, pair[1], pair[2])
    end
    val = f()
    for pair in pairs
        unassume(as, pair[1], pair[2])
    end
    return val
end
