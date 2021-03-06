module Sylvia

import AbstractInstances
import Cassette
import Combinatorics: permutations
import DataStructures: OrderedDict
import LinearAlgebra
import MacroTools: striplines, unblock

export @S_str, @λ, @scope, @!, @sym,
    Mock, Sym, Wild,
    gather, substitute, tagof

##################################################
# Misc
##################################################

@inline istrue(x) = x == true
@inline isfalse(x) = x == false
@inline commuteswith(op, x, y) = op(x, y) == op(y, x)

##################################################
# Includes
##################################################

include("cassettectx.jl")

include("sym.jl")
include("wild.jl")
include("match.jl")
include("promotion.jl")
include("expr.jl")
include("show.jl")
include("compile.jl")
include("context.jl")
include("register.jl")
include("apply.jl")
include("mock.jl")
include("protect.jl")

include("substitute.jl")
include("simplify.jl")
include("array.jl")
include("ops.jl")
include("rules.jl")

end # module
