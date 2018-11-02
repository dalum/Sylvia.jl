include("stackeddict.jl")

const AssumptionStack = StackedDict{Sym,Any}

const GLOBAL_ASSUMPTION_STACK = AssumptionStack()

macro assumptions()
    return :(GLOBAL_ASSUMPTION_STACK)
end

query(x::Sym) = query(GLOBAL_ASSUMPTION_STACK, x)
query(as::AssumptionStack, x::Sym)::Union{typeof(x), Missing} = get(as, x, missing)

assume(x::Sym, val) = assume(GLOBAL_ASSUMPTION_STACK, x, val)
assume(as::AssumptionStack, x::Sym, val) = push!(as, x => val)

const INTERCEPT_OPS = (:!, :(==), :<, :(!=))

macro assume(xs...)
    ret = Expr(:block)
    for x in xs
        if hashead(x, :call) && firstarg(x) === :(=>)
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

        if hashead(x, :call)
            x = :(_apply($(map(esc, getargs(x))...)))
        else
            x = esc(x)
        end

        push!(ret.args, :(assume($x, $val)))
    end
    return ret
end

function assume_intercept(x, val)
    @assert hashead(x, :call) "$x"
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

unassume(x::Sym) = unassume(GLOBAL_ASSUMPTION_STACK, x)
unassume(x::Sym, val) = unassume(GLOBAL_ASSUMPTION_STACK, x, val)
unassume(as::AssumptionStack, x::Sym) = (popall!(as, x); as)
unassume(as::AssumptionStack, x::Sym, val) = (pop!(as, x => val); as)

macro unassume(xs...)
    ret = Expr(:block)
    for x in xs
        if hashead(x, :call) && firstarg(x) === :(=>)
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

        x = :(_apply($(map(esc, getargs(x))...)))
        push!(ret.args, :(unassume($x, $val)))
    end
    return ret
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
