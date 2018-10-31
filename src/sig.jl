struct Sig{TAG,DATA,UNIQUE} end

function Sig(x::Sym{TAG}) where {TAG}
    args = getargs(x)
    DATA = typeof(args)
    unique = Vector{Int}(undef, length(args))
    for i in eachindex(args)
        for j in 1:i
            if args[i] === args[j]
                unique[i] = j
                break
            end
        end
    end
    return Sig{TAG,DATA,Tuple{unique...}}()
end
