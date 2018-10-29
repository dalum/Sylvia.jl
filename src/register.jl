macro register(name, N::Integer)
    name = esc(name)
    symbols = Any[gensym() for _ in 1:N]
    ret = register_promote(name, symbols)

    arglist = [Expr(:(::), s, :Sym) for s in symbols]
    e = :($name($(arglist...)) = apply($name, $(symbols...)))
    push!(ret.args, e)

    return ret
end

macro register_split(name, N::Integer)
    name = esc(name)
    symbols = Any[gensym() for _ in 1:N]
    ret = register_promote(name, symbols)

    arglist = [Expr(:(::), s, :Sym) for s in symbols]
    splitlist = [Expr(:(...), Expr(:call, :split, name, s)) for s in symbols]
    e = :($name($(arglist...)) = apply($name, $(splitlist...)))
    push!(ret.args, e)

    return ret
end

macro register_query(name, assumptions, N::Integer)
    name = esc(name)
    assumptions = esc(assumptions)
    symbols = Any[gensym() for _ in 1:N]
    ret = register_promote(name, symbols)

    arglist = [Expr(:(::), s, :Sym) for s in symbols]
    e = :($name($(arglist...)) = apply_query($name, $assumptions, $(symbols...)))
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
