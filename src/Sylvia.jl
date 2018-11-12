module Sylvia

import Cassette
import Combinatorics: permutations
import DataStructures: OrderedDict
import LinearAlgebra
import MacroTools: striplines

export @S_str, @λ, @scope, @!, @symbols, @unset!,
    commuteswith, gather, substitute, tagof,
    isfalse, istrue

include("sym.jl")
include("wild.jl")
include("match.jl")
include("protoinstance.jl")
include("promotion.jl")
include("expr.jl")
include("show.jl")
include("compile.jl")
include("context.jl")
include("register.jl")
include("apply.jl")

include("substitute.jl")
include("simplify.jl")
include("array.jl")
include("ops.jl")
include("rules.jl")

##################################################
# Special cases
##################################################

@inline istrue(x) = x == true
@inline isfalse(x) = x == false

Base.zero(::Type{Sym{TAG}}) where TAG = apply(zero, Sym(TAG))
Base.one(::Type{Sym{TAG}}) where TAG = apply(one, Sym(TAG))
Base.oneunit(::Type{Sym{TAG}}) where TAG = apply(oneunit, Sym(TAG))

commuteswith(::Any, ::Any, ::Any) = false
@register_atomic commuteswith 3

commuteswith(::Sym{typeof(+)}, ::Sym{<:Number}, ::Sym{<:Number}) = true
commuteswith(::Sym{typeof(*)}, ::Sym{<:Number}, ::Sym{<:Number}) = true

commuteswith(::Sym{typeof(+)}, ::Sym{<:Array}, ::Sym{<:Array}) = true

commuteswith(::Sym{typeof(&)}, ::Sym{<:Bool}, ::Sym{<:Bool}) = true
commuteswith(::Sym{typeof(|)}, ::Sym{<:Bool}, ::Sym{<:Bool}) = true

end # module
