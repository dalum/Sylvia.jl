struct Sig{TAG,DATA,UNIQUE} end

function Sig(x::Sym{TAG}) where {TAG}
    DATA = typeof(x.args)
    unique = Vector{Int}(undef, length(x.args))
    for i in eachindex(x.args)
        for j in 1:i
            if x.args[i] === x.args[j]
                unique[i] = j
                break
            end
        end
    end
    return Sig{TAG,DATA,Tuple{unique...}}()
end
