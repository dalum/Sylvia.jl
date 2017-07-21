struct Symbolic{T}
    value::T
end
Symbolic(x::Symbolic) = Symbolic(x.value)
Symbolic(A::AbstractArray) = convert(AbstractArray{Symbolic}, A)

macro S_str(str)
    Symbolic(parse(str))
end

# value

value(x) = x
value(x::Symbolic) = x.value

#convert

Base.promote_rule(::Type{Symbolic}, ::Type{<:Any}) = Symbolic
Base.promote_rule(::Type{Symbolic{T}}, ::Type{<:Any}) where T = Symbolic{T}

Base.convert(T::Type, x::Symbolic{S}) where S                   = convert(T, x.value)
Base.convert(T::Type{Any}, x::Symbolic{S}) where S              = convert(T, x.value)
Base.convert(::Type{Symbolic}, x)                               = Symbolic(x)
Base.convert(::Type{Symbolic{T}}, x) where T                    = Symbolic(x)
Base.convert(::Type{Symbolic}, x::Symbolic)                     = x
Base.convert(::Type{Symbolic{T}}, x::Symbolic{T}) where T       = x
Base.convert(::Type{Symbolic{T}}, x::Symbolic{S}) where {T,S}   = Symbolic(convert(T, x.value))

Base.convert(::Type{AbstractArray{Symbolic{T},N}}, A::AbstractArray{S,N}) where {T<:Number,S,N} = Base.convert(AbstractArray{Symbolic,N}, A)

Base.similar(a::Array{T,1}) where {T<:Symbolic}                        = Array{Symbolic,1}(size(a,1))
Base.similar(a::Array{T,2}) where {T<:Symbolic}                        = Array{Symbolic,2}(size(a,1), size(a,2))
Base.similar(a::Array{T,1}, S::Type{Symbolic{T}}) where {T}            = Array{Symbolic,1}(size(a,1))
Base.similar(a::Array{T,2}, S::Type{Symbolic{T}}) where {T}            = Array{Symbolic,2}(size(a,1), size(a,2))
Base.similar(a::Array{T}, m::Int) where {T<:Symbolic}                  = Array{Symbolic,1}(m)
Base.similar(a::Array, ::Type{Symbolic{T}}, dims::Dims{N}) where {T,N} = Array{Symbolic,N}(dims)
Base.similar(a::Array{T}, dims::Dims{N}) where {T<:Symbolic,N}         = Array{Symbolic,N}(dims)

Core.eval(x::Symbolic) = eval(x.value)
Core.eval(mod::Module, x::Symbolic) = eval(mod, x.value)
