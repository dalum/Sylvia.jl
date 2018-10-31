##################################################
# Expression manipulations
##################################################

function apply(op, xs::Sym...)
    TAG = promote_tag(:call, op, map(tagof, xs)...)
    if all(hashead(:object), xs)
        return Sym{TAG}(op(map(firstarg, xs)...))
    else
        return Sym{TAG}(:call, op, xs...)
    end
end

function apply_query(op, as::AssumptionStack, xs::Sym...)
    x = apply(op, xs...)
    q = query(as, x)
    return q === missing ? x : q
end

function apply_query_symmetric(op, as::AssumptionStack, xs::Sym...)
    x0 = nothing
    for ys in permutations(xs)
        q = apply_query(op, as, ys...)
        q isa Bool && return q
        x0 === nothing && (x0 = q)
    end
    return x0
end

function combine(head::Symbol, xs...)
    TAG = promote_tag(head, map(tagof, xs)...)
    return Sym{TAG}(head, xs...)
end

function split(op, x::Sym)
    if hashead(x, :call) && firstarg(x) === op
        return tailargs(x)
    end
    return (x,)
end

##################################################
# Special cases
##################################################

apply(::typeof(+), x::Sym) = x
apply(::typeof(*), x::Sym) = x
apply(::typeof(&), x::Sym) = x
apply(::typeof(|), x::Sym) = x
