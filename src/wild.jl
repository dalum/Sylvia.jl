struct Wild{TAG} end

tagof(x::Sym{Wild{TAG}}) where {TAG} = TAG

##################################################
# Comparison
##################################################

Base.isequal(x::Sym{<:TAG}, y::Sym{Wild{TAG}}) where {TAG} = true
Base.isequal(x::Sym{Wild{TAG}}, y::Sym{<:TAG}) where {TAG} = true
Base.isequal(x::Sym{Wild{TAG}}, y::Sym{Wild{TAG}}) where {TAG} = x === y

const MatchPairs = Set{Union{Bool,Pair{<:Sym{<:Wild},<:Sym}}}

# Catch all
match(x, y) = istrue(x == y) ? MatchPairs() : MatchPairs(false)
match(x::Sym, y) = match(promote(x, y)...)
match(x, y::Sym) = match(promote(x, y)...)

match(x::Sym{<:TAG}, y::Sym{Wild{TAG}}) where {TAG} = MatchPairs([y => x])
match(x::Sym{Wild{TAG}}, y::Sym{Wild{TAG}}) where {TAG} = MatchPairs([x => y])
function match(x::Sym, y::Sym)
    gethead(x) === gethead(y) || return MatchPairs(false)
    xargs, yargs = getargs(x), getargs(y)
    length(xargs) == length(yargs) || return MatchPairs(false)
    tmp = mapreduce(x -> match(x[1], x[2]), union, zip(xargs, yargs))
    return any(isfalse, tmp) ? MatchPairs(false) : tmp
end

function ismatch(pairs::MatchPairs)
    matches = Dict(MatchPairs())
    for pair in pairs
        pair === true && continue
        pair === false && return false
        val = get(matches, pair[1], pair[2])
        val === pair[2] || return false
        matches[pair[1]] = pair[2]
    end
    return true
end
