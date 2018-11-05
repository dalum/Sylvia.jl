macro Sentinel(T)
    return Expr(:toplevel, :(mutable struct $(Symbol(string(T),"Sentinel")) <: $(esc(T)) end))
end

macro sentinel(T)
    return esc(Symbol(string(T),"Sentinel"))
end

function generate_sentinel end

for T in (:Number, :Real, :Integer)
    @eval @Sentinel $T
    @eval generate_sentinel(::Type{$T}) = @sentinel($T)()
end

generate_sentinel(::Type{<:Wild{T}}) where {T} = generate_sentinel(T)
generate_sentinel(::Type{T}) where {T<:Number} = rand(T)
generate_sentinel(::Type{T}) where {S,N,T<:AbstractArray{S,N}} = T(undef, (0 for _ in 1:N)...)
generate_sentinel(::Type{T}) where {N,T<:(AbstractArray{S,N} where S)} = T(undef, (0 for _ in 1:N)...)
