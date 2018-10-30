##################################################
# Expression manipulations
##################################################

function apply(op, xs::Sym...)
    TAG = promote_tag(:call, op, map(tagof, xs)...)
    return Sym{TAG}(:call, op, xs...)
end

function apply_query(op, as::AssumptionStack, xs::Sym...)
    x = apply(op, xs...)
    q = query(as, x)
    return q === missing ? x : q
end

function apply_query_symmetric(op, as::AssumptionStack, xs::Sym...)
    x0 = apply(op, xs...)
    q = query(as, x0)
    q === missing || return q
    for ys in collect(permutations(xs))[2:end]
        y = apply(op, ys...)
        q = query(as, y)
        q === missing || return q
    end
    return x0
end

function combine(head::Symbol, xs...)
    TAG = promote_tag(head, map(tagof, xs)...)
    return Sym{TAG}(head, xs...)
end

function split(op, x::Sym)
    if x.head === :call && x.args[1] === op
        return x.args[2:end]
    end
    return (x,)
end

##################################################
# Special cases
##################################################

apply(::typeof(+), x::Sym) = x
apply(::typeof(*), x::Sym) = x

