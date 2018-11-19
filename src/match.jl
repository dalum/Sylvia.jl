const MatchPairs = Set{Union{Bool,Pair}}

# Catch all
match(x, y) = (x == y) === true ? MatchPairs() : MatchPairs(false)
match(x::Sym, y) = match(promote(x, y)...)
match(x, y::Sym) = match(promote(x, y)...)

match(x::Sym, y::Sym{<:Wild}) = MatchPairs(issubtag(tagof(x), tagof(y)) ? [y => x] : false)

function match(x::Sym, y::Sym)
    issubtag(tagof(x), tagof(y)) || return MatchPairs(false)
    gethead(x) === gethead(y) || return MatchPairs(false)
    xargs, yargs = getargs(x), getargs(y)
    length(xargs) == length(yargs) || return MatchPairs(false)
    m = mapreduce(x -> match(x[1], x[2]), union, zip(xargs, yargs))
    any(isfalse, m) && return MatchPairs(false)
    hashead(x, :symbol) && return MatchPairs([y => x])
    return m
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
