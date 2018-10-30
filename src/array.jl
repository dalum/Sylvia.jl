Base.Vector(v::Sym, n) = [v[i] for i in 1:n]
Base.Matrix(A::Sym, n, m) = [A[i,j] for i in 1:n, j in 1:m]
