module Sylvia

import Cassette
import Combinatorics: permutations
import DataStructures: OrderedDict
import LinearAlgebra
import MacroTools: striplines

export @S_str, @λ, @symbols,
    commuteswith, gather, substitute, tagof,
    isfalse, istrue

istrue(x) = x === true
isfalse(x) = x === false

include("sym.jl")
include("wild.jl")
include("sentinel.jl")
include("sig.jl")
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

##################################################
# Base
##################################################

# One-arg operators
for op in (:istrue, :isfalse)
    @eval @register_atomic $op 1
end

for op in (:+, :-, :!,
           :length, :size,
           :abs, :abs2, :complex, :conj, :exp, :imag, :inv,
           :log, :one, :oneunit, :real, :sqrt, :transpose, :zero,
           :cos, :sin, :tan, :sec, :csc, :cot,
           :acos, :asin, :atan, :asec, :acsc, :acot,
           :cosh, :sinh, :tanh, :sech, :csch, :coth,
           :acosh, :asinh, :atanh, :asech, :acsch, :acoth,
           :iseven, :isinf, :isnan, :isodd)
    @eval @register_atomic $(:(Base.$op)) 1
end
Base.adjoint(x::Sym) = combine(Symbol("'"), x)

# Two-arg operators
for op in (:-, :/, :\, ://, :^, :÷, :isless, :<, :&, :|)
    @eval @register_atomic $(:(Base.$op)) 2
end
Base.getindex(x::Sym, val::Symbol) = Base.getindex(promote(x, QuoteNode(val))...)
Base.getindex(x::Sym, vals...) = Base.getindex(promote(x, map(val -> val isa Symbol ? QuoteNode(val) : val, vals)...)...)
Base.getindex(x::Sym, val::Sym) = combine(:ref, x, val)
Base.getindex(x::Sym, vals::Sym...) = combine(:ref, x, vals...)

Base.getproperty(x::Sym, val::Symbol) = Base.getproperty(promote(x, QuoteNode(val))...)
Base.getproperty(x::Sym, val::Sym{Symbol}) = combine(:(.), x, val)

# Two-arg symmetric operators
for op in (:(==),)
    @eval @register_symmetric $(:(Base.$op)) 2
end

Base.in(x::Sym, y::Sym) = apply(in, x, y)

# Multi-arg operators
for op in (:+, :*)
    @eval @register_atomic $(:(Base.$op)) 2
    @eval $(:(Base.$op))(xs::Sym...) = apply($(:(Base.$op)), xs...)
end
@register commuteswith 3

##################################################
# Linear algebra
##################################################

# One-arg operators
for op in (:norm,)
    @eval @register_atomic $(:(LinearAlgebra.$op)) 1
end

# Two-arg operators
for op in (:dot, :cross)
    @eval @register_atomic $(:(LinearAlgebra.$op)) 2
end

##################################################
# Default rules
##################################################

let w = S"w::Wild{Any}"
    @set! w == w => true
    @set! zero(zero(w)) => zero(w)
    @set! one(one(w)) => one(w)
end

##################################################
# Special cases
##################################################

Base.zero(::Type{Sym{TAG}}) where TAG = apply(zero, Sym(TAG))
Base.one(::Type{Sym{TAG}}) where TAG = apply(one, Sym(TAG))
Base.oneunit(::Type{Sym{TAG}}) where TAG = apply(oneunit, Sym(TAG))

commuteswith(::typeof(+), x::Sym{<:Number}, y::Sym{<:Number}) = true
commuteswith(::typeof(+), x::Sym{<:Array}, y::Sym{<:Array}) = true

commuteswith(::typeof(*), x::Sym{<:Number}, y::Sym{<:Number}) = true

commuteswith(::typeof(&), x::Sym{<:Bool}, y::Sym{<:Bool}) = true
commuteswith(::typeof(|), x::Sym{<:Bool}, y::Sym{<:Bool}) = true

end # module
