##################################################
# Expression manipulations
##################################################

_unwrap(x) = x
_unwrap(x::Sym{TAG}) where {TAG} = hashead(x, :object) ? firstarg(x)::TAG : x

_apply(op, xs::Sym...) = _apply(GLOBAL_ASSUMPTION_STACK, op, xs...)
function _apply(as::AssumptionStack, op, xs::Sym...)
    TAG = promote_tag(:call, op, map(tagof, xs)...)
    if all(hashead(:object), xs)
        x = Sym{TAG}(op(map(firstarg, xs)...))
    else
        x = Sym{TAG}(:call, op, xs...)
    end
    return x::Sym{TAG}
end

apply(op, xs::Sym...) = apply(GLOBAL_ASSUMPTION_STACK, op, xs...)
function apply(as::AssumptionStack, op, xs::Sym...)
    x = _apply(as, op, xs...)
    q = query(as, x)
    return _unwrap(q === missing ? x : q)
end

apply_symmetric(op, xs::Sym...) = apply_symmetric(GLOBAL_ASSUMPTION_STACK, op, xs...)
function apply_symmetric(as::AssumptionStack, op, xs::Sym...)
    x0 = nothing
    for ys in permutations(xs)
        x = _apply(as, op, ys...)
        q = query(as, x)
        if q !== missing
            x0 = q
            break
        elseif x0 === nothing
            x0 = x
        end
    end
    return _unwrap(x0)
end

combine(head::Symbol, xs...) = combine(GLOBAL_ASSUMPTION_STACK, head, xs...)
function combine(as::AssumptionStack, head::Symbol, xs...)
    TAG = promote_tag(head, map(tagof, xs)...)
    x = Sym{TAG}(head, xs...)
    q = query(as, x)
    return _unwrap(q === missing ? x : q)
end

##################################################
# Special cases
##################################################

apply(::typeof(+), x::Sym) = x
apply(::typeof(*), x::Sym) = x
apply(::typeof(&), x::Sym) = x
apply(::typeof(|), x::Sym) = x
