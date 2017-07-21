Base.zero(x::Symbolic{T}) where T = Symbolic(zero(x.value))
Base.one(x::Symbolic{T}) where T = Symbolic(one(x.value))
Base.oneunit(x::Symbolic{T}) where T = Symbolic(oneunit(x.value))
Base.zero(x::Symbolic{T}) where T<:Union{Symbol,Expr} = Symbolic(0)
Base.one(x::Symbolic{T}) where T<:Union{Symbol,Expr} = Symbolic(1)
Base.oneunit(x::Symbolic{T}) where T<:Union{Symbol,Expr} = Symbolic(1)

Base.zero(::Type{Symbolic{T}}) where T = Symbolic(zero(T))
Base.one(::Type{Symbolic{T}}) where T = Symbolic(one(T))
Base.oneunit(::Type{Symbolic{T}}) where T = Symbolic(one(T))
Base.zero(::Type{Symbolic}) = Symbolic(0)
Base.one(::Type{Symbolic}) = Symbolic(1)
Base.oneunit(::Type{Symbolic}) = Symbolic(1)
Base.zero(::Type{Symbolic{T}}) where T<:Union{Symbol,Expr} = Symbolic(0)
Base.one(::Type{Symbolic{T}}) where T<:Union{Symbol,Expr} = Symbolic(1)
Base.oneunit(::Type{Symbolic{T}}) where T<:Union{Symbol,Expr} = Symbolic(1)

Base.iszero(x::Symbolic) = iszero(x.value) # Compatibility
iszero(x) = Base.iszero(x)
iszero(::Symbol) = false
iszero(::Expr) = false

isone(x) = x == one(x)
isone(::Symbol) = false
isone(::Expr) = false

ideleml(::Type{Val{:+}}) = 0
ideleml(::Type{Val{:*}}) = 1
idelemr(::Type{Val{:+}}) = 0
idelemr(::Type{Val{:*}}) = 1
idelemr(::Type{Val{:^}}) = 1

iscall(x) = false
iscall(x::Expr) = x.head == :call
