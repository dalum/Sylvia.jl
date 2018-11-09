##################################################
# Function diving
##################################################

Cassette.@context CassetteCtx

function Cassette.execute(ctx::CassetteCtx, f, args...)
    if Cassette.canoverdub(ctx, f, args...)
        newargs = (get(ctx.metadata, arg, arg) for arg in args)
        return f(newargs...)
    else
        @warn "Could not overdub `$f` using sentinels: $(args)"
        return Cassette.fallback(ctx, f, args...)
    end
end

function diveinto(op, xs::Sym...)
    tags = map(tagof, xs)
    ps = map(oftype, tags)
    ctx = CassetteCtx(metadata = IdDict{Any,Sym}(key => val for (key, val) in zip(ps, xs)))
    return Cassette.overdub(ctx, invoke, op, Tuple{tags...}, sentinels...)
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

function apply(op, xs::Sym...)
    x = _apply(op, xs...)
    q = query(x)
    return _unwrap(q === missing ? x : q)
end

function apply_symmetric(op, xs::Sym...)
    x0 = nothing
    for ys in permutations(xs)
        x = _apply(op, ys...)
        q = query(x)
        if q !== missing
            x0 = q
            break
        elseif x0 === nothing
            x0 = x
        end
    end
    return _unwrap(x0)
end

function combine(head::Symbol, xs...)
    x = _combine(head, xs...)
    q = query(x)
    return _unwrap(q === missing ? x : q)
end

##################################################
# Special cases
##################################################

apply(::typeof(+), x::Sym) = x
apply(::typeof(*), x::Sym) = x
apply(::typeof(&), x::Sym) = x
apply(::typeof(|), x::Sym) = x
