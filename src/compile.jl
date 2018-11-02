function compile(x)
    modname = gensym()
    symbols = getsymbols(x)
    ops = collect(getops(x))
    modules = map(parentmodule, ops)
    import_stmts = [:(using $(nameof(mod)): $(nameof(op))) for (mod, op) in zip(modules, ops)]
    body = expr(x)
    m = @eval baremodule $modname
        $(import_stmts...)
        function f($(symbols...))
            $body
        end
    end
    return m.f
end
