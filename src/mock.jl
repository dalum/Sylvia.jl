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
        context, dict = ctx.metadata
        return apply(f, (get(dict, arg, arg) for arg in args)...; context=context)
    else
        return f(args...)
    end
end

function mock(f, xs::Sym{<:Mock}...; context::Context = @__context__)
    tags = map(tagof, xs)
    ps = map(AbstractInstances.oftype, tags)
    metadata = (
        context = context,
        dict = IdDict{Any,Sym}(key => val for (key, val) in zip(ps, xs))
    )
    ctx = CassetteCtx(metadata = metadata)
    result = Cassette.overdub(ctx, invoke, f, Tuple{tags...}, ps...)
    return get(ctx.metadata.dict, result, result)
end
