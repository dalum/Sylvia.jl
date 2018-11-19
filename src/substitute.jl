"""
    substitute!(dest::Sym, x::Sym, pairs...; strict=false)

Like `substitute(x, pairs...)` but overwrites `dest` with the result.

"""
function substitute!(dest::Sym, x::Sym, pairs::Pair...; kwargs...)
    y = substitute(x, pairs...; kwargs...)
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
function substitute(x, pairs::Pair...; kwargs...)
    x = unprotect(_substitute(x, pairs...; kwargs...))
    return x
end

function _substitute(x, pairs::Pair...; kwargs...)
    pairs = map(pair -> Pair(convert(Sym, first(pair)), convert(Sym, last(pair))), pairs)
    return _substitute(x, pairs...; kwargs...)
end

# Catch all
_substitute(x, pairs::(Pair{<:Sym,<:Sym})...; kwargs...) = x

function _substitute(x::Sym, pairs::Pair{<:Sym,<:Sym}...; strict=false, context::Context = @__context__)
    isprotected(x) && return x

    for (pat, sub) in pairs
        if strict && !issubtag(tagof(sub), tagof(pat))
            error("strict mode: cannot substitute: $pat => $sub: $(tagof(sub)) is not a subtype of $(tagof(pat))")
        end

        if isequal(x, pat)
            x = protect(sub)
            continue
        end
    end

    if !isprotected(x) && !isatomic(x)
        args = map(arg -> unprotect(_substitute(arg, pairs...; strict=strict, context=context)), getargs(x))
        if hashead(x, :call)
            x = apply(args...; context=context)
        else
            x = combine(gethead(x), args...; context=context)
        end
    end

    return x
end
