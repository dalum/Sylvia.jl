include("stackeddict.jl")

const AssumptionStack = StackedDict{Sym,Bool}

const GLOBAL_ASSUMPTION_STACK = AssumptionStack()

macro assumptions()
    return :(GLOBAL_ASSUMPTION_STACK)
end

query(x::Sym) = query(GLOBAL_ASSUMPTION_STACK, x)
function query(as::AssumptionStack, x::Sym)
    if hashead(x, :object) && firstarg(x) isa Bool
        return firstarg(x)
    else
        get(as, x, missing)
    end
end

assume(x::Sym, val) = assume(GLOBAL_ASSUMPTION_STACK, x, val)
assume(as::AssumptionStack, x::Sym, val::Bool) = push!(as, x => val)
assume(as::AssumptionStack, x::Sym, val::Missing) = unassume(as, x)

macro assume(xs...)
    ret = Expr(:block)
    for x in xs
        val = true
        @assert x.head === :call
        if x.args[1] === :!
            x = x.args[2]
            val = false
            @assert x.head === :call
        elseif x.args[1] === :(!=)
            x.args[1] = :(==)
            val = false
        end
        x = :(apply($(map(esc, x.args)...)))
        push!(ret.args, :(assume($x, $val)))
    end
    return ret
end

unassume(x::Sym, val::Bool) = unassume(GLOBAL_ASSUMPTION_STACK, x, val)
unassume(as::AssumptionStack, x::Sym, val::Bool) = pop!(as, x => val)

macro unassume(xs...)
    ret = Expr(:block)
    for x in xs
        val = true
        @assert x.head === :call
        if x.args[1] === :!
            x = x.args[2]
            val = false
            @assert x.head === :call
        end
        x = :(apply($(map(esc, x.args)...)))
        push!(ret.args, :(unassume($x, $val)))
    end
    push!(ret.args, GLOBAL_ASSUMPTION_STACK)
    return ret
end

assuming(f, pairs::Pair{<:Sym,Bool}...) = assuming(f, GLOBAL_ASSUMPTION_STACK, pairs...)
function assuming(f, as::AssumptionStack, pairs::Pair{<:Sym,Bool}...)
    for pair in pairs
        assume(as, pair[1], pair[2])
    end
    val = f()
    for pair in pairs
        unassume(as, pair[1], pair[2])
    end
    return val
end
