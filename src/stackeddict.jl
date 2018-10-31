struct StackedDict{T,S} <: AbstractDict{T,S}
    keys::Vector{T}
    vals::Vector{S}

    function StackedDict{T,S}(pairs::Pair{<:T,<:S}...) where {T,S}
        keys = Vector{T}(undef, length(pairs))
        vals = Vector{S}(undef, length(pairs))
        for i in eachindex(pairs)
            keys[i] = first(pairs[i])
            vals[i] = last(pairs[i])
        end
        return new{T,S}(keys, vals)
    end
end
StackedDict(pairs::Pair{T,S}...) where {T,S} = StackedDict{T,S}(pairs...)

Base.length(d::StackedDict) = length(d.keys)
Base.iterate(d::StackedDict) = iterate(zip(d.keys, d.vals))
Base.iterate(d::StackedDict, x) = iterate(zip(d.keys, d.vals), x)

function Base.getindex(d::StackedDict, key)
    idx = findlast(isequal(key), d.keys)
    idx === nothing && throw(KeyError(key))
    return d.vals[idx]
end

function Base.get(d::StackedDict, key, default)
    idx = findlast(isequal(key), d.keys)
    idx === nothing && return default
    return d.vals[idx]
end

function Base.push!(d::StackedDict{T,S}, pair::Pair{<:T,<:S}) where {T,S}
    push!(d.keys, first(pair))
    push!(d.vals, last(pair))
    return d
end

function Base.pop!(d::StackedDict{T,S}, key::T) where {T,S}
    idx = findlast(isequal(key), d.keys)
    idx === nothing && throw(KeyError(key))
    val = d.vals[idx]
    deleteat!(d.keys, idx)
    deleteat!(d.vals, idx)
    return val
end

function Base.pop!(d::StackedDict{T,S}, pair::Pair{<:T,<:S}) where {T,S}
    idx = findlast(x -> isequal(pair[1], x[1]) && isequal(pair[2], x[2]), collect(zip(d.keys, d.vals)))
    idx === nothing && throw(KeyError(pair))
    deleteat!(d.keys, idx)
    deleteat!(d.vals, idx)
    return pair[2]
end

function Base.empty!(d::StackedDict)
    Base.empty!(d.keys)
    Base.empty!(d.vals)
    return d
end
