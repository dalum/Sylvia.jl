function generate_sentinel end

generate_sentinel(::Type{<:Wild{T}}) where {T} = generate_sentinel(T)
generate_sentinel(::Type{T}) where {T<:Number} = 0
generate_sentinel(::Type{T}) where {S,N,T<:AbstractArray{S,N}} = T(undef, (0 for _ in 1:N)...)
generate_sentinel(::Type{T}) where {N,T<:(AbstractArray{S,N} where S)} = T(undef, (0 for _ in 1:N)...)
