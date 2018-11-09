macro register(name, N::Integer)
    name = esc(name)
    symbols = Any[gensym("symvar") for _ in 1:N]
    ret = register_promote(name, symbols)

    arglist = [Expr(:(::), s, :Sym) for s in symbols]
    e = quote
        function $name($(arglist...))
            diveinto($name, $(symbols...))
        end
    end
    push!(ret.args, e)

    return ret
end

macro register_atomic(name, N::Integer)
    name = esc(name)
    symbols = Any[gensym("symvar") for _ in 1:N]
    ret = register_promote(name, symbols)

    arglist = [Expr(:(::), s, :Sym) for s in symbols]
    e = quote
        function $name($(arglist...))
            apply($name, $(symbols...))
        end
    end
    push!(ret.args, e)

    return ret
end

macro register_symmetric(name, N::Integer)
    name = esc(name)
    symbols = Any[gensym("symvar") for _ in 1:N]
    ret = register_promote(name, symbols)

    arglist = [Expr(:(::), s, :Sym) for s in symbols]
    e = quote
        function $name($(arglist...))
            apply_symmetric($name, $(symbols...))
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
