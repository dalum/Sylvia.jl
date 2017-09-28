#="""
    derive_class(f, xs...)
"""=#
function derive_class(f::Function, xs::Type...)
    inferred = Core.Inference.return_type(f, Tuple{xs...})
    return inferred == Union{} ? Any : inferred
end

derive_class(f::Function, x1::Class{C}) where {C} = derive_class(f, C)
derive_class(f::Function, x1::Class{C1}, x2::Class{C2}) where {C1, C2} = derive_class(f, C1, C2)
function derive_class(f::Function, x1::Class{C1}, x2::Class{C2}, xs::Symbolic...) where {C1, C2}
    assoc = Base.operator_associativity(Symbol(f))
    if assoc === :left || Symbol(f) in (:+, :*)
        fold = foldl
    elseif assoc === :right
        fold = foldr
    else
        return Any
    end
    return fold((x, y) -> derive_class(f, x, y), map(x -> typeof(x).parameters[2], [x1, x2, xs...]))
end

# Generic
derive_class(f::Function, ::Type{T}, ::Type{S}) where {T<:Number,S<:Number} = typejoin(T, S, typeof(f(zero(T), one(S))))
derive_class(f::typeof(/), ::Type{T}, ::Type{S}) where {T<:Number,S<:Number} = typejoin(T, S, typeof(f(zero(T), one(S))))

# Negation
derive_class(::Union{typeof(-), typeof(+), typeof(conj)}, ::Type{T}) where {T<:Union{Number,AbstractArray}} = T

# Addition
derive_class(f::Union{typeof(+), typeof(-)}, ::Type{A}, ::Type{S}) where {T<:Number, N, A<:AbstractArray{T,N}, S<:Number} = A.name.wrapper{derive_class(f, T, S), N}
derive_class(f::Union{typeof(+), typeof(-)}, ::Type{S}, ::Type{A}) where {T<:Number, N, A<:AbstractArray{T,N}, S<:Number} = A.name.wrapper{derive_class(f, T, S), N}
derive_class(f::Union{typeof(-), typeof(+)}, ::Type{A}, ::Type{B}) where {N, T1<:Number, A<:AbstractArray{T1,N}, T2<:Number, B<:AbstractArray{T2,N}} = A.name.wrapper{derive_class(f, T1, T2), N}

# Multiplication
derive_class(::typeof(*), ::Type{A}, ::Type{S}) where {T<:Number, N, A<:AbstractArray{T,N}, S<:Number} = A.name.wrapper{derive_class(*, T, S), N}
derive_class(::typeof(*), ::Type{S}, ::Type{A}) where {T<:Number, N, A<:AbstractArray{T,N}, S<:Number} = A.name.wrapper{derive_class(*, T, S), N}

derive_class(::typeof(*), ::Type{A}, ::Type{B}) where {T1<:Number, A<:AbstractMatrix{T1}, T2<:Number, B<:AbstractMatrix{T2}} = (C = derive_class(*, T1, T2); A.name.wrapper{derive_class(+, C, C), 2})

# Division
derive_class(::typeof(/), ::Type{A}, ::Type{B}) where {A,B} = derive_class(*, A, derive_class(inv, B))
derive_class(::typeof(\), ::Type{A}, ::Type{B}) where {A,B} = derive_class(*, derive_class(inv, A), B)

# Inverse
derive_class(::typeof(inv), ::Type{A}) where A = derive_class(^, A, Integer)

# Exponentiation
derive_class(::Union{typeof(^)}, ::Type{T}, ::Type{S}) where {T<:Number,S<:Integer} = derive_class(/, Integer, T)
derive_class(::Union{typeof(^)}, ::Type{T}, ::Type{S}) where {T<:Number,S<:Number} = Number

derive_class(f::Union{typeof(^)}, ::Type{A}, ::Type{S}) where {T<:Number, N, A<:AbstractArray{T,N}, S<:Number} = (C = derive_class(f, T, S); A.name.wrapper{derive_class(+, C, C), 2})
derive_class(f::Union{typeof(^)}, ::Type{S}, ::Type{A}) where {T<:Number, N, A<:AbstractArray{T,N}, S<:Number} = (C = derive_class(^, A, Integer); C = derive_class(/, C, Integer); A.name.wrapper{derive_class(+, C, C), 2})

derive_class(f::Union{typeof(^)}, ::Type{A}, ::Type{B}) where {T1<:Number, A<:AbstractMatrix{T1}, T2<:Number, B<:AbstractMatrix{T2}} = (C = derive_class(f, T1, T2); A.name.wrapper{derive_class(+, C, C), 2})

# Roots
BasicFunctions = Union{typeof(exp), typeof(log), typeof(sqrt), typeof(cos), typeof(sin), typeof(tan), typeof(sec), typeof(csc), typeof(cot), typeof(cosh), typeof(sinh), typeof(tanh), typeof(sech), typeof(csch), typeof(coth), typeof(acos), typeof(asin), typeof(atan), typeof(asec), typeof(acsc), typeof(acot), typeof(acosh), typeof(asinh), typeof(atanh), typeof(asech), typeof(acsch), typeof(acoth)}

derive_class(f::BasicFunctions, ::Type{<:Number}) = Number
derive_class(f::BasicFunctions, ::Type{A}) where {T<:Number, A<:AbstractMatrix{T}} = A.name.wrapper{derive_class(f, T), 2}

derive_properties(f, xs::Symbolic...) = Properties()

derived(f::Function, xs::Symbolic...) = Symbolic(derive_class(f, xs...), Expr(:call, Symbol(f), xs...), derive_properties(f, xs...))

# special
derived(f::typeof(transpose), xs::Symbolic...) = Symbolic(derive_class(f, xs...), Expr(Symbol(".'"), xs...), derive_properties(f, xs...))
derived(f::typeof(adjoint), xs::Symbolic...) = Symbolic(derive_class(f, xs...), Expr(Symbol("'"), xs...), derive_properties(f, xs...))
