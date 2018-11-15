const MatchPairs = Set{Union{Bool,Pair{<:Sym{<:Wild},<:Sym}}}

# Catch all
match(x, y) = (x == y) === true ? MatchPairs() : MatchPairs(false)
match(x::Sym, y) = match(promote(x, y)...)
match(x, y::Sym) = match(promote(x, y)...)

match(x::Sym{<:TAG}, y::Sym{Wild{TAG}}) where {TAG} = MatchPairs([y => x])
match(x::Sym{Wild{T}}, y::Sym{Wild{S}}) where {T,S} = MatchPairs(false)
match(x::Sym{Wild{T}}, y::Sym{Wild{S}}) where {S,T<:S} = MatchPairs([x => y])

match(x::Sym, y::Sym) = MatchPairs(false)
function match(x::Sym{<:T}, y::Sym{T}) where T
    gethead(x) === gethead(y) || return MatchPairs(false)
    xargs, yargs = getargs(x), getargs(y)
    length(xargs) == length(yargs) || return MatchPairs(false)
    m = mapreduce(x -> match(x[1], x[2]), union, zip(xargs, yargs))
    return any(isfalse, m) ? MatchPairs(false) : m
end

function ismatch(pairs::MatchPairs)
    matches = Dict()
    for pair in pairs
        pair === true && continue
        pair === false && return false
        val = get(matches, pair[1], pair[2])
        isequal(val, pair[2]) || return false
        matches[pair[1]] = pair[2]
    end
    return true
end
