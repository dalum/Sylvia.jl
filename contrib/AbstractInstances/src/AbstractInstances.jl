module AbstractInstances

_singletonsymbol(T::UnionAll) = _singletonsymbol(T.body)
_singletonsymbol(T::DataType) = Symbol("Singleton", string(T))

_new_singleton(T::UnionAll) = _new_singleton(T.body)
function _new_singleton(T::DataType)
    S = _singletonsymbol(T)
    return quote
        struct $S <: $T end
    end
end

_concretesymbol(T::UnionAll) = _concretesymbol(T.body)
_concretesymbol(T::DataType) = Symbol("Concrete", string(T))

_new_concrete(T::UnionAll) = _new_concrete(T.body)
function _new_concrete(T::DataType)
    S = _concretesymbol(T)
    return quote
        mutable struct $S <: $T end
    end
end

"""
    singletontype(T::Type)

Return a concrete immutable type with no fields which is a subtype of
`T`.  The immutability of the returned type ensures that instances of
the type are singletons.
"""
function singletontype(T::Type)
    @assert isabstracttype(T)
    S = _singletonsymbol(T)
    if !(@eval @isdefined $S)
        @eval $(_new_singleton(T))
    end
    return @eval $S
end

"""
    singleton(T::Type)

Create an instance of type, `singletontype(T)`.
"""
singleton(T::Type) = @eval singletontype($T)()

"""
    concretetype(T::Type)

Return a concrete mutable type with no fields which is a subtype of
`T`.  The mutability of the returned type ensures that instances of
the type are unique.
"""
function concretetype(T::Type)
    @assert isabstracttype(T)
    S = _concretesymbol(T)
    if !(@eval @isdefined $S)
        @eval $(_new_concrete(T))
    end
    return @eval $S
end

"""
    oftype(T::Type)

Create a unique instance of type, `concretetype(T)`.
"""
oftype(T::Type) = @eval concretetype($T)()

end # module
