__precompile__(true)

module Sylvia

export @S_str, @def, @λ, @symbols, @assume, Symbolic

struct Symbolic{T}
    value::T
end

macro S_str(str)
    Symbolic(parse(str))
end

### Value extraction
value(x) = x
value(x::Symbolic) = x.value

### Promotion rules
Base.convert(::Type{Symbolic}, x) = Symbolic(x)
Base.convert(::Type{Symbolic{T}}, x) where T = Symbolic{T}(x)
Base.convert(::Type{Symbolic}, x::Symbolic{T}) where T = x
Base.convert(::Type{Symbolic{S}}, x::Symbolic{T}) where {S, T} = Symbolic{S}(x.value)
Base.convert(T::Type{<:Any}, x::Symbolic{S}) where S = convert(T, x.value)

Base.promote_rule(::Type{Symbolic}, ::Type{<:Any}) = Symbolic
Base.promote_rule(::Type{Symbolic{T}}, ::Type{<:Any}) where T = Symbolic{T}

### Array stuff
Base.similar(a::Array{T,1}) where {T<:Symbolic}                        = Array{Symbolic,1}(size(a,1))
Base.similar(a::Array{T,2}) where {T<:Symbolic}                        = Array{Symbolic,2}(size(a,1), size(a,2))
Base.similar(a::Array{T,1}, S::Type{Symbolic{T}}) where {T}            = Array{Symbolic,1}(size(a,1))
Base.similar(a::Array{T,2}, S::Type{Symbolic{T}}) where {T}            = Array{Symbolic,2}(size(a,1), size(a,2))
Base.similar(a::Array{T}, m::Int) where {T<:Symbolic}                  = Array{Symbolic,1}(m)
Base.similar(a::Array, ::Type{Symbolic{T}}, dims::Dims{N}) where {T,N} = Array{Symbolic,N}(dims)
Base.similar(a::Array{T}, dims::Dims{N}) where {T<:Symbolic,N}         = Array{Symbolic,N}(dims)

show_prefix = ""
show_suffix = ""
function setshow(prefix, suffix)
    global show_prefix, show_suffix
    show_prefix = prefix
    show_suffix = suffix
    println("Symbolic types printed as print(Symbolic(x)) -> $(show_prefix)x$(show_suffix)")
end

Base.show(io::IO, x::Symbolic) = print(io, "$show_prefix$(x.value)$show_suffix")

include("identities.jl")
include("expression.jl")
include("assumptions.jl")

# commutes

commutes(x, y) = false
commutes(::Number, ::Number) = true
commutes(::Number, ::Any) = true
commutes(::Any, ::Number) = false

# sort

add_order(x, y) = isless(string(firstsymbol(x, x)), string(firstsymbol(y, y)))
mul_order(x, y) = commutes(x, y)

import .Assumptions: @assume

include("math.jl")
#include("operators.jl")
# define_operators(false)

# function debug(debug::Bool = true)
#     if debug
#         setshow("S\"", "\"")
#         define_operators(true)
#     else
#         setshow("", "")
#         define_operators(false)
#     end
#     print("Debug: $debug")
# end

include("def.jl")

end # module
