struct Mock{TAG} end

tagof(x::Sym{Mock}) = DEFAULT_TAG
tagof(x::Sym{Mock{TAG}}) where {TAG} = TAG

ismocking(x) = false
ismocking(x::Sym{<:Mock}) = true

##################################################
# Function mocking
##################################################

function Cassette.execute(ctx::CassetteCtx, f, args...)
    if Cassette.canoverdub(ctx, f, args...)
        return apply(f, (get(ctx.metadata, arg, arg) for arg in args)...)
    else
        return f(args...)
    end
end

function mock(f, xs::Sym{<:Mock}...)
    tags = map(tagof, xs)
    ps = map(AbstractInstances.oftype, tags)
    ctx = CassetteCtx(metadata = IdDict{Any,Sym}(key => val for (key, val) in zip(ps, xs)))
    result = Cassette.overdub(ctx, invoke, f, Tuple{tags...}, ps...)
    return get(ctx.metadata, result, result)
end
