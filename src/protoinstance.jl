macro Proto(T)
    return Expr(:toplevel, :(mutable struct $(Symbol("Proto", string(T))) <: $(esc(T)) end))
end

macro proto(T)
    return esc(Symbol("Proto", string(T)))
end

function oftype end

for T in (:Number, :Real, :Integer)
    @eval @Proto $T
    @eval oftype(::Type{$T}) = @proto($T)()
end

oftype(::Type{<:Wild{T}}) where {T} = oftype(T)
oftype(::Type{T}) where {T<:Number} = rand(T)
oftype(::Type{T}) where {S,N,T<:AbstractArray{S,N}} = T(undef, (0 for _ in 1:N)...)
oftype(::Type{T}) where {N,T<:(AbstractArray{S,N} where S)} = T(undef, (0 for _ in 1:N)...)
