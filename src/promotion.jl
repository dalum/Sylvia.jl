##################################################
# Type promotion/conversion
##################################################

Base.convert(::Type{Sym}, x) = Sym(x)
Base.convert(::Type{Sym}, x::Sym) = x
Base.convert(::Type{Sym{T}}, x) where {T} = Sym{T}(x)
Base.convert(::Type{Sym{T}}, x::Sym) where {T} = Sym{T}(x.head, x.args...)

# Base.convert(::Type{AbstractArray{Sym{T,TAG}}}, A::AbstractArray) where {T,TAG} = Base.convert(AbstractArray{Sym}, A)

Base.promote_rule(::Type{Sym{T}}, ::Type{Any}) where {T} = Sym
Base.promote_rule(::Type{Sym{T}}, ::Type{S}) where {T,S} = Sym{promote_type(T, S)}
Base.promote_rule(::Type{Sym{T}}, ::Type{Sym{S}}) where {T,S} = Sym{promote_type(T, S)}

Base.promote_op(f, a::Type{<:Sym{T}}) where {T} = Sym{promote_tag(:call, f, T)}

Base.promote_op(f, a::Type{Sym{T}}, b::S) where {T,S} = Sym{promote_tag(:call, f, T, S)}
Base.promote_op(f, a::T, b::Type{S}) where {T,S} = Sym{promote_tag(:call, f, T, S)}
Base.promote_op(f, a::Type{Sym{T}}, b::Type{Sym{S}}) where {T,S} = Sym{promote_tag(:call, f, T, S)}

##################################################
# Tag promotion
##################################################

promote_tag(head::Symbol, args...) = promote_tag(Val(head), args...)
promote_tag(::Val{:call}, op, argtags::Type...) = Base.promote_op(op, argtags...)

# Improve stability, assuming all numbers form a ring
promote_tag(::Val{:call}, ::typeof(Base.:+), argtags::Type{T}...) where {T<:Number} =
    Base.promote_type(T, typeof(zero(T) + zero(T)))
promote_tag(::Val{:call}, ::typeof(Base.:-), argtags::Type{T}...) where {T<:Number} =
    Base.promote_type(T, typeof(zero(T) - zero(T)))
promote_tag(::Val{:call}, ::typeof(Base.:*), argtags::Type{T}...) where {T<:Number} =
    T
promote_tag(::Val{:call}, ::typeof(Base.:/), argtags::Type{T}...) where {T<:Number} =
    Base.promote_type(T, typeof(zero(T)/oneunit(T)))
