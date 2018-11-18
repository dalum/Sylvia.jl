##################################################
# Raw apply/combine
##################################################

unwrap(x) = x
function unwrap(x::Sym{TAG}) where {TAG}
    hashead(x, :object) && return firstarg(x)
    if hashead(x, :call)
        op = firstarg(x)
        if hashead(op, :fn)
            xs = tailargs(x)
            f = firstarg(op)
            tags = map(tagof, xs)
            if hasmethod(f, Tuple{tags...})
                if all(hashead(:object), xs) && all(x -> firstarg(x) isa tagof(x), xs)
                    return invoke(f, Tuple{tags...}, map(firstarg, xs)...)
                elseif all(ismocking, xs) && all(isabstracttype, tags)
                    return mock(f, xs...)
                end
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
