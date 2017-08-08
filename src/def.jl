expressify(a) = a # Catch all
expressify(a::Expr) = Expr(a.head, map(expressify, a.args)...)
expressify(a::Symbolic) = expressify(value(a))
expressify(V::AbstractVector) = Expr(:vect, value.(V)...)
expressify(A::AbstractMatrix) = Expr(:vcat, mapslices(x -> Expr(:row, value.(x)...), A, 2)...)

# symbols

macro symbols(names::Symbol...)
    esc(Expr(:block, (Expr(:(=), name, Symbolic(name)) for name in names)..., :nothing))
end

# def

_def(mod::Module, expr::Symbol) = throw(ArgumentError("invalid function definition"))
function _def(mod::Module, expr::Expr)
    if expr.head ≠ :(=)
        throw(ArgumentError("invalid function definition"))
    end

    body = expressify(eval(mod, expr.args[2]))

    name = expr.args[1]
    if name isa Symbol
        symbols = sort(collect(getsymbols(body)))
    elseif iscall(name)
        name, symbols = name.args[1], name.args[2:end]
    else
        throw(ArgumentError("name must be either a symbol or call"))
    end
    return esc(Expr(:(=), Expr(:call, name, symbols...), body))
end

if VERSION >= v"0.7.0-DEV"
    macro def(expr) _def(__module__, expr) end
else
    macro def(expr) _def(Main, expr) end
end
macro def(mod, expr) _def(mod, expr) end

# λ

_parse_args(args::Symbol) = (args,)
function _parse_args(args::Expr)
    if args.head ≠ :tuple
        throw(ArgumentError("invalid argument list"))
    end
    return args.args
end

function _lambda_implicit(mod::Module, expr)
    body = expressify(eval(mod, expr))
    symbols = sort(collect(getsymbols(body)))
    esc(Expr(:(->), Expr(:tuple, symbols...), body))
end

_lambda(mod::Module, x::Symbol) = _lambda_implicit(mod, x)
function _lambda(mod::Module, expr::Expr)
    expr.head ≠ :(->) && return _lambda_implicit(mod, expr)
    symbols = _parse_args(expr.args[1])
    body = expressify(eval(mod, expr.args[2]))
    esc(Expr(:(->), Expr(:tuple, symbols...), body))
end

if VERSION >= v"0.7.0-DEV"
    macro λ(expr) _lambda(__module__, expr) end
else
    macro λ(expr) _lambda(Main, expr) end
end
macro λ(mod, expr) _lambda(mod, expr) end
