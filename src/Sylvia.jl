module Sylvia

############################################################

export @S_str, @def, @λ, @symbols, Symbolic

include("symbolic.jl")
include("show.jl")

_strict = false
function strict(strict=true)
    global _strict
    _strict = strict
    println("Strict mode: $strict")
end

include("identities.jl")
include("expression.jl")

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

# Helper functions


include("math.jl")
include("operators.jl")
define_operators(false)

function debug(debug::Bool = true)
    if debug
        setshow("S\"", "\"")
        define_operators(true)
    else
        setshow("", "")
        define_operators(false)
    end
    print("Debug: $debug")
end

include("def.jl")

end # module
