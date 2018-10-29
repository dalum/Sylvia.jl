# Conversion
function substitute(x, pairs::Pair...; strict=false)
    pairs = map(pair -> Pair(convert(Sym, first(pair)), convert(Sym, last(pair))), pairs)
    return substitute(x, pairs..., strict=strict)
end

# Catch all
substitute(x, pairs::(Pair{Sym{T},Sym{S}} where {T,S})...; strict=false) = x

function substitute(x::Sym{TAG}, pairs::(Pair{Sym{T},Sym{S}} where {T,S})...; strict=false) where {TAG}
    for (pat, sub) in pairs
        if strict && !(tagof(sub) <: tagof(pat))
            error("strict mode: cannot substitute: $pat => $sub: $(tagof(sub)) is not a subtype of $(tagof(pat))")
        end
        if x === pat
            x = sub
        else
            x = Sym{TAG}(x.head, map(arg -> substitute(arg, pat => sub, strict=strict), x.args))
        end
    end
    return x
end
