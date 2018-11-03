##################################################
# Function diving
##################################################

Cassette.@context CassetteCtx

function Cassette.execute(ctx::CassetteCtx, f, args...)
    if Cassette.canoverdub(ctx, f, args...)
        return f(ctx.metadata...)
    else
        @warn "Could not overdub `$f` using sentinels: $(args)"
        return Cassette.fallback(ctx, f, args...)
    end
end

function diveinto(op, xs::Sym...)
    tags = map(tagof, xs)
    ctx = CassetteCtx(metadata = xs)
    return Cassette.overdub(ctx, invoke, op, Tuple{tags...}, map(generate_sentinel, tags)...)
end

##################################################
# Raw apply/combine
##################################################

_unwrap(x) = x
_unwrap(x::Sym{TAG}) where {TAG} = hashead(x, :object) ? firstarg(x)::TAG : x

function _apply(op, xs::Sym...)
    tags = map(tagof, xs)
    TAG = promote_tag(:call, op, tags...)
    if all(hashead(:object), xs)
        x = Sym{TAG}(op(map(firstarg, xs)...))
    else
        x = Sym{TAG}(:call, op, xs...)
    end
    return x::Sym{TAG}
end

function _combine(head::Symbol, xs...)
    TAG = promote_tag(head, map(tagof, xs)...)
    return Sym{TAG}(head, xs...)
end

##################################################
# Querying apply/combine
##################################################

apply(op, xs::Sym...) = apply(GLOBAL_ASSUMPTION_STACK, op, xs...)
function apply(as::AssumptionStack, op, xs::Sym...)
    x = _apply(op, xs...)
    q = query(as, x)
    return _unwrap(q === missing ? x : q)
end

apply(op, xs::Sym...) = apply(GLOBAL_ASSUMPTION_STACK, op, xs...)
function apply(as::AssumptionStack, op, xs::Sym...)
    x = _apply(op, xs...)
    q = query(as, x)
    return _unwrap(q === missing ? x : q)
end

apply_identity(op, idop, xs::Sym...) = apply_symmetric(GLOBAL_ASSUMPTION_STACK, op, idop, xs...)
function apply_identity(as::AssumptionStack, op, idop, x::Sym)
    hashead(x, :call) && firstarg(x) === idop && return true
    return apply(as, op, x)
end

apply_symmetric(op, xs::Sym...) = apply_symmetric(GLOBAL_ASSUMPTION_STACK, op, xs...)
function apply_symmetric(as::AssumptionStack, op, xs::Sym...)
    x0 = nothing
    for ys in permutations(xs)
        x = _apply(op, ys...)
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
    x = _combine(head, xs...)
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
