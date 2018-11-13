##################################################
# Function diving
##################################################

Cassette.@context CassetteCtx

function Cassette.execute(ctx::CassetteCtx, f, args...)
    if Cassette.canoverdub(ctx, f, args...)
        newargs = (get(ctx.metadata, arg, arg) for arg in args)
        return f(newargs...)
    else
        return Cassette.fallback(ctx, f, args...)
    end
end

function diveinto(op, xs::Sym...)
    tags = map(tagof, xs)
    ps = map(oftype, tags)
    ctx = CassetteCtx(metadata = IdDict{Any,Sym}(key => val for (key, val) in zip(ps, xs)))
    return Cassette.overdub(ctx, invoke, op, Tuple{tags...}, ps...)
end

##################################################
# Raw apply/combine
##################################################

unwrap(x) = x
function unwrap(x::Sym{TAG}) where {TAG}
    hashead(x, :object) && return firstarg(x)
    if hashead(x, :call)
        op = firstarg(x)
        xs = getargs(x)[2:end]
        if hashead(op, :fn) && all(hashead(:object), xs)
            f = firstarg(op)
            objs = map(firstarg, xs)
            if applicable(f, objs...)
                return firstarg(op)(objs...)
            end
        end
    end
    return x
end

_apply(args...) = _apply(map(arg -> convert(Sym, arg), args)...)
function _apply(op::Sym, xs::Sym...)
    tags = map(tagof, xs)
    TAG = promote_tag(:call, op, tags...)
    x = Sym{TAG}(:call, op, xs...)
    return x::Sym{TAG}
end

function _combine(head::Symbol, xs...)
    TAG = promote_tag(head, map(tagof, xs)...)
    return Sym{TAG}(head, xs...)
end

##################################################
# Querying apply/combine
##################################################

apply(op, xs...) = unwrap(query!(_apply(op, xs...)))
combine(head::Symbol, xs...) = unwrap(query!(_combine(head, xs...)))
