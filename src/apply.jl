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
_unwrap(x::Sym{TAG}) where {TAG} = hashead(x, :object) ? firstarg(x) : x

_apply(args...) = _apply(map(arg -> convert(Sym, arg), args)...)
function _apply(op::Sym, xs::Sym...)
    tags = map(tagof, xs)
    TAG = promote_tag(:call, op, tags...)
    if all(hashead(:object), xs)
        x = Sym{TAG}(firstarg(op)(map(firstarg, xs)...))
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

apply(op, xs...) = _unwrap(query!(_apply(op, xs...)))
combine(head::Symbol, xs...) = _unwrap(query!(_combine(head, xs...)))
