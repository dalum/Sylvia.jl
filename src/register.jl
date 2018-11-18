macro register(name, N::Integer)
    return register(nothing, _parse_name(name)..., N)
end

macro register(ctx::Symbol, name, N::Integer)
    return register(ctx, _parse_name(name)..., N)
end

_parse_name(name) = Meta.isexpr(name, :(-->)) ? name.args : (name, name)

function register(ctx::Union{Symbol,Nothing}, name, alias, N::Integer)
    name = esc(name)
    alias = esc(alias)
    symbols = Any[gensym("symvar") for _ in 1:N]
    ret = register_promote(name, symbols)

    arglist = [Expr(:(::), s, :Sym) for s in symbols]
    e = if ctx === nothing
        quote
            function $name($(arglist...))
                apply($alias, $(symbols...))
            end
        end
    else
        quote
            function $name($(arglist...))
                apply($alias, $(symbols...); context=$(esc(ctx)))
            end
        end
    end

    push!(ret.args, e)

    return ret
end

function register_promote(name, symbols)
    N = length(symbols)
    ret = Expr(:block)

    if N > 1
        for has_types in Iterators.product(((true, false) for _ in 1:N)...)
            (all(has_types) || !any(has_types)) && continue
            arglist = [has_type ? Expr(:(::), s, :Sym) : s for (has_type, s) in zip(has_types, symbols)]
            e = :($name($(arglist...)) = $name(promote($(symbols...))...))
            push!(ret.args, e)
        end
    end

    return ret
end
