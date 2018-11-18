struct Protected end

protect(x) = Sym{Protected}(:protected, x)

unprotect(x) = x
unprotect(x::Sym{TAG}) where {TAG} = Sym{TAG}(gethead(x), map(unprotect, getargs(x))...)
unprotect(x::Sym{Protected}) = unprotect(firstarg(x))

isprotected(x) = false
isprotected(x::Sym{Protected}) = true
