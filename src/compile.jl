pairs_to_assignments(x) = (:(const $key = $val) for (key, val) in x)

lower_expr(fn::Symbol, xs...; kwargs...) = lower_expr(fn, map(x -> Tuple(collectsort(getsyms(x))) => x, xs)...; kwargs...)
function lower_expr(fn::Symbol, xs::Pair{<:Tuple,<:Any}...; kwargs...)
    exprs = mapreduce(x -> x.args, vcat, map(x -> lower_one_expr(fn, x[1], x[2]), xs))
    ex = Expr(:toplevel,
              :(using Sylvia: @register),
              pairs_to_assignments(kwargs)...,
              exprs...)
    return striplines(ex)
end

lower_one_expr(fn::Symbol, x) = lower_one_expr(fn, collectsort(getsyms(x)), x)
function lower_one_expr(fn::Symbol, syms::Tuple, x)
    types = map(tagof, syms)
    symbols = map(firstarg, syms)
    signature = [Expr(:(::), s, T) for (s, T) in zip(symbols, types)]

    signature_str = join(signature, ", ")

    ops = map(firstarg, collect(getops(x)))
    modules = map(parentmodule, ops)
    import_stmts = [:(using $(nameof(mod)): $(nameof(op))) for (mod, op) in zip(modules, ops)]
    body = expr(x)

    ex = quote
        $(import_stmts...)
        function $fn($(signature...))
            $body
        end
        @register $fn $(length(signature))
    end

    return striplines(ex)
end

lower(xs...; kwargs...) = lower(gensym("f"), xs...; kwargs...)
lower(fn::Symbol, xs...; kwargs...) = Core.eval(Module(:__anon__, false), lower_expr(fn, xs...; kwargs...))
