# Sylvia 🧚🏻

[![Build Status](https://travis-ci.org/dalum/Sylvia.jl.svg?branch=master)](https://travis-ci.org/dalum/Sylvia.jl)
[![codecov](https://codecov.io/gh/dalum/Sylvia.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dalum/Sylvia.jl)

A simple symbolic library with a pretty name.

## Usage

```julia
julia> using Sylvia

julia> @sym a b c d
(a, b, c, d)

julia> a + b*c + c |> gather
a + b * c + c

julia> @! iszero(a) = true; # a == zero(a)

julia> @! isone(b) = true; # b == one(b)

julia> a + b*c + c |> gather
2c

julia> substitute(a + b + c, a => b, b => c) |> gather
3c

julia> using LinearAlgebra

julia> @sym AbstractMatrix{Float64} :: A B
(A, B)

julia> Matrix(A, 2, 2)^2
2×2 Array{Sylvia.Sym{Float64},2}:
 A[1, 1] * A[1, 1] + A[1, 2] * A[2, 1]  A[1, 1] * A[1, 2] + A[1, 2] * A[2, 2]
 A[2, 1] * A[1, 1] + A[2, 2] * A[2, 1]  A[2, 1] * A[1, 2] + A[2, 2] * A[2, 2]

julia> X = gather.(substitute.( # `a` and `b` are going to be optimized away
           Matrix(A, 2, 2)^2,
           Ref(A[1,1] => a),
           Ref(A[1,2] => b),
           Ref(A[2,1] => c),
           Ref(A[2,2] => d)
       ))
2×2 Array{Sylvia.Sym{Number},2}:
 c      d
 c * d  c + d ^ 2

julia> f = @λ (c, d) => tr(X'X);

julia> f(c, d)
(0 + (c' * c + (c * d)' * (c * d))) + (d' * d + (c + d ^ 2)' * (c + d ^ 2))

julia> using BenchmarkTools

julia> @btime $(f)(1, 2)
  0.026 ns (0 allocations: 0 bytes)
34

julia> using StaticArrays

julia> g(c, d) = (X = SMatrix{2,2}(0, 1, c, d)^2; tr(X'X))
g (generic function with 2 methods)

julia> @btime $(g)(1, 2)
  5.738 ns (0 allocations: 0 bytes)
34
```
