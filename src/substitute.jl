"""
    substitute!(dest::Sym, x::Sym, pairs...; strict=false)

Like `substitute(x, pairs...)` but overwrites `dest` with the result.

"""
function substitute!(dest::Sym, x::Sym, pairs::Pair...; kwargs...)
    y = Sym(substitute(x, pairs...; kwargs...))
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
    for (pat, sub) in pairs
        if strict && !issubtag(tagof(sub), tagof(pat))
            error("strict mode: cannot substitute: $pat => $sub: $(tagof(sub)) is not a subtype of $(tagof(pat))")
        elseif isequal(x, pat)
            return sub
        end
    end
    isatomic(x) && return x
    args = map(arg -> _substitute(arg, pairs...; strict=strict, context=context), getargs(x))
    if hashead(x, :call)
        return apply(args...; context=context)
    else
        return combine(gethead(x), args...; context=context)
    end
end
