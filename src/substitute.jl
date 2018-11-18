"""
    substitute!(dest::Sym, x::Sym, pairs...; strict=false)

Like `substitute(x, pairs...)` but overwrites `dest`.

"""
function substitute!(dest::Sym, x::Sym, pairs::Pair...; strict=false)
    y = substitute(x, pairs...; strict=strict)
    sethead!(dest, gethead(y))
    setargs!(dest, getargs(y))
    return dest
end

"""
    substitute(x, pairs...; strict=false)

Using pairs of `pat => sub`, substitute occurences of `pat` in `x`
with `sub`.  If `strict` is `true`, only allow substitutions for which
the tag of `pat` is a subtype of the tag of `sub`.

"""
function substitute(x, pairs::Pair...; strict=false)
    pairs = map(pair -> Pair(convert(Sym, first(pair)), convert(Sym, last(pair))), pairs)
    return substitute(x, pairs..., strict=strict)
end

# Catch all
substitute(x, pairs::(Pair{<:Sym,<:Sym})...; strict=false) = x

function substitute(x::Sym, pairs::Pair{<:Sym,<:Sym}...; strict=false)
    for (pat, sub) in pairs
        if strict && !(tagof(sub) <: tagof(pat))
            error("strict mode: cannot substitute: $pat => $sub: $(tagof(sub)) is not a subtype of $(tagof(pat))")
        end

        if isequal(x, pat)
            x = sub
        elseif !isatomic(x)
            args = map(arg -> substitute_one(arg, pat => sub, strict=strict), getargs(x))
            if hashead(x, :call)
                x = query!(_apply(args...))
            else
                x = query!(_combine(gethead(x), args...))
            end
        end

    end
    return x
end

substitute_one(arg, pair::(Pair{Sym{T},Sym{S}} where {T,S}); strict=false) = arg
substitute_one(arg::Sym, pair::(Pair{Sym{T},Sym{S}} where {T,S}); strict=false) = substitute(arg, pair, strict=strict)

function substitute(f::Function, pairs::(Pair{Sym{T},Sym{S}} where {T,S})...; strict=false)
    return substitute(f(), pairs..., strict=strict)
end
