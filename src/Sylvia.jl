module Sylvia

import DataStructures: OrderedDict

export @S_str, @assume, @expr, @λ, @symbols,
    tagof

include("sym.jl")
include("sig.jl")
include("promotion.jl")
include("expr.jl")
include("show.jl")
include("assume.jl")
include("register.jl")
include("baseops.jl")
include("substitute.jl")
include("simplify.jl")

##################################################
# Base
##################################################

# One-arg operators
for op in (:abs, :abs2, :adjoint, :complex, :conj, :exp, :imag, :inv,
           :log, :one, :real, :sqrt, :transpose, :zero,
           :+, :-, :!,
           :cos, :sin, :tan, :sec, :csc, :cot, :cosh, :sinh, :tanh, :sech, :csch, :coth,
           :acos, :asin, :atan, :asec, :acsc, :acot, :acosh, :asinh, :atanh, :asech, :acsch, :acoth)
    @eval @register $(:(Base.$op)) 1
end

# One-arg queries
for op in (:iseven, :isinf, :isodd, :isone, :iszero)
    @eval @register_query $(:(Base.$op)) GLOBAL_ASSUMPTION_STACK 1
end

# Two-arg operators
for op in (:-, :/, :\, ://, :^, :÷, :(==), :&, :|)
    @eval @register $(:(Base.$op)) 2
end

# Two-arg queries
for op in (:in,)
    @eval @register_query $(:(Base.$op)) GLOBAL_ASSUMPTION_STACK 2
end


# Multi-arg operators
for op in (:+, :*)
    @eval @register_split $(:(Base.$op)) 2
end

Base.isequal(x::Sym, y::Sym) = x === y

function Base.zero(::Type{Sym{TAG}}) where {TAG}
    x = Sym{TAG}(:call, zero, TAG)
    @assume iszero(x)
    return x
end

function Base.one(::Type{Sym{TAG}}) where {TAG}
    x = Sym{TAG}(:call, one, TAG)
    @assume isone(x)
    return x
end

end # module
