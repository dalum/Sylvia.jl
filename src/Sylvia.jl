module Sylvia

import Combinatorics: permutations
import LinearAlgebra

export @S_str, @assume, @assumptions, @expr, @λ, @symbols, @unassume,
    assuming, commuteswith, gather, substitute, tagof

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

include("array.jl")

##################################################
# Base
##################################################

# One-arg operators
for op in (:+, :-, :!,
           :abs, :abs2, :complex, :conj, :exp, :imag, :inv,
           :log, :one, :oneunit, :real, :sqrt, :transpose, :zero,
           :cos, :sin, :tan, :sec, :csc, :cot,
           :acos, :asin, :atan, :asec, :acsc, :acot,
           :cosh, :sinh, :tanh, :sech, :csch, :coth,
           :acosh, :asinh, :atanh, :asech, :acsch, :acoth)
    @eval @register $(:(Base.$op)) 1
end
Base.adjoint(x::Sym) = combine(Symbol("'"), x)

for op in (:norm,)
    @eval @register $(:(LinearAlgebra.$op)) 1
end

# One-arg queries
for op in (:iseven, :isinf, :isnan, :isodd)
    @eval @register_query $(:(Base.$op)) GLOBAL_ASSUMPTION_STACK 1
end

for (op, idop) in ((:isone, :one), (:iszero, :zero))
    @eval @register_query_identity $(:(Base.$op)) $(:(Base.$idop)) GLOBAL_ASSUMPTION_STACK 1
end

# Two-arg operators
for op in (:-, :/, :\, ://, :^, :÷, :&, :|)
    @eval @register $(:(Base.$op)) 2
end
Base.getindex(x::Sym, val::Symbol) = Base.getindex(promote(x, QuoteNode(val))...)
Base.getindex(x::Sym, vals...) = Base.getindex(promote(x, map(val -> val isa Symbol ? QuoteNode(val) : val, vals)...)...)
Base.getindex(x::Sym, val::Sym) = combine(:ref, x, val)
Base.getindex(x::Sym, vals::Sym...) = combine(:ref, x, vals...)

# Two-arg queries
for op in (:isless, :<)
    @eval @register_query $(:(Base.$op)) GLOBAL_ASSUMPTION_STACK 2
end

for op in (:(==),)
    @eval @register_query_symmetric $(:(Base.$op)) GLOBAL_ASSUMPTION_STACK 2
end

Base.in(x::Sym, y::Sym) = apply_query(in, GLOBAL_ASSUMPTION_STACK, x, y)

# Multi-arg operators
for op in (:+, :*)
    @eval @register_split $(:(Base.$op)) 2
end

Base.isequal(x::Sym, y::Sym) = x === y

@register_query commuteswith GLOBAL_ASSUMPTION_STACK 3

##################################################
# Special cases
##################################################

Base.zero(::Type{Sym{TAG}}) where TAG = apply(zero, Sym(TAG))
Base.one(::Type{Sym{TAG}}) where TAG = apply(one, Sym(TAG))
Base.oneunit(::Type{Sym{TAG}}) where TAG = apply(oneunit, Sym(TAG))

commuteswith(::typeof(+), x::Sym{<:Number}, y::Sym{<:Number}) = true
commuteswith(::typeof(+), x::Sym{<:Array}, y::Sym{<:Array}) = true

commuteswith(::typeof(*), x::Sym{<:Number}, y::Sym{<:Number}) = true

end # module
