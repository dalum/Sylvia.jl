module Sylvia

__precompile__(true)

export @S_str, @def, @λ, @symbols, @assume, Symbolic

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
include("assumptions.jl")

import .Assumptions: @assume

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
