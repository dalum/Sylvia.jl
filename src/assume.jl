const AssumptionStack = OrderedDict{Sym,Bool}

const GLOBAL_ASSUMPTION_STACK = AssumptionStack()

query(x::Sym) = query(GLOBAL_ASSUMPTION_STACK, x)
query(as::AssumptionStack, x::Sym) = get(as, x, missing)

assume(x::Union{Sym,Bool}) = assume(GLOBAL_ASSUMPTION_STACK, x)
assume(x::Union{Sym,Bool}, val) = assume(GLOBAL_ASSUMPTION_STACK, x, val)

assume(as::AssumptionStack, x::Sym, val::Bool) = setindex!(as, val, x)
assume(as::AssumptionStack, x::Sym, val::Missing) = delete!(as, x)
assume(as::AssumptionStack, x::Bool, val::Bool) = (@assert(x == val, "assumption inconsistency: $x != $val"); as)

assume(as::AssumptionStack, x::Bool) = (@assert(x, "assumption inconsistency: $x != true"); as)

function assume(as::AssumptionStack, x::Sym)
    if x.head === :call && x.args[1] === Base.:!
        assume(as, x.args[2], false)
    else
        assume(as, x, true)
    end
end

macro assume(xs...)
    ret = Expr(:block)
    for x in xs
        push!(ret.args, :(assume($(esc(x)))))
    end
    return ret
end
