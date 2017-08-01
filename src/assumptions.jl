module Assumptions

export @assume

# Global tables

AssumedTypes = Dict{Symbol, Any}()

assumed_typeof(a::Symbol) = a in keys(AssumedTypes) ? eval(AssumedTypes[a]) : Any

# helper functions


_assert_symbols() = throw(ArgumentError("not a symbol or a tuple of symbols: $symbols"))

assert_symbols(symbols) = _assert_symbols()
assert_symbols(symbols::Symbol) = [symbols]
assert_symbols(symbols::Expr) = symbols.head === :tuple ? symbols.args : _assert_symbols()

assert_symbol(symbol) = throw(ArgumentError("not a symbol: $symbol"))
assert_symbol(symbol::Symbol) = symbol

# assumptions

macro assume(exprs::Expr...)
    for expr in exprs
        if expr.head === :tuple
            conditions = expr.args[2:end]
            expr = expr.args[1]
        else
            conditions = []
        end
        parse_assumption(expr, parse_conditions(conditions))
    end
    nothing
end

function parse_assumption(expr::Expr, conditions)
    if expr.head === :call
        parse_type_assumption(Val{expr.args[1]}, expr.args[2:end], conditions)
    end
end

function parse_type_assumption(::Union{Type{Val{:in}}, Type{Val{:∈}}}, args, conditions)
    global AssumedTypes

    symbols = assert_symbols(args[1])
    T = assert_symbol(args[2])

    for symbol in symbols
        AssumedTypes[symbol] = conditions == nothing ? T : :($conditions ? $T : Any)
    end
end

# conditions

function parse_conditions(conditions)
    if length(conditions) == 0
        return nothing
    elseif length(conditions) == 1
        return parse_condition(conditions[1])
    end
    return Expr(:(&&), parse_condition(conditions[1]), parse_conditions(conditions[2:end]))
end

function parse_condition(condition::Expr)
    if condition.head === :call
        return parse_type_condition(Val{condition.args[1]}, condition.args[2:end])
    end
    return condition
end

function parse_type_condition(::Union{Type{Val{:in}}, Type{Val{:∈}}}, condition)
    symbols = assert_symbols(condition[1])
    T = assert_symbol(condition[2])
    return foldl((a, b) -> Expr(:&&, a, b), (:(assumed_typeof($(QuoteNode(symbol))) <: $T) for symbol in symbols))
end

function parse_type_condition(f::Union{Type{Val{:<}}, Type{Val{:>}}}, condition)
    symbols = assert_symbols(condition)

    if condition[2] isa Symbol
        T = condition[2]
    else
        throw(ArgumentError("right-hand side in a type assumption must be a single symbol"))
    end
end

# isless

isless(x, y) = Base.isless(x, y)

# commutes

commutes(x, y) = false
commutes(::Number, ::Number) = true
commutes(::Number, ::Any) = true
commutes(::Any, ::Number) = false

# sort

add_order(x, y) = isless(string(firstsymbol(x, x)), string(firstsymbol(y, y)))
mul_order(x, y) = commutes(x, y)

end
