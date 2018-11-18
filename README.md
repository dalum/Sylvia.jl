# Sylvia 🧚🏻

[![Build Status](https://travis-ci.org/dalum/Sylvia.jl.svg?branch=master)](https://travis-ci.org/dalum/Sylvia.jl)
[![codecov](https://codecov.io/gh/dalum/Sylvia.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dalum/Sylvia.jl)

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://dalum.github.io/Sylvia.jl/dev)

A simple symbolic library with a pretty name.

## Usage

```julia
julia> using Sylvia

julia> @sym [Number] a b c d
(@! a, @! b, @! c, @! d)

julia> a + b*c + c |> gather
@! a + b * c + c

julia> @! set iszero(a) --> true; # a == zero(a)

julia> @! set isone(b) --> true; # b == one(b)

julia> a + b*c + c |> gather
@! 2c

julia> substitute(a + b + c, a => b, b => c, c => a)
@! c + a + b

julia> using LinearAlgebra

julia> @sym [AbstractMatrix{Float64}] A B
(@! A, @! B)

julia> Matrix(A, 2, 2)^2
2×2 Array{Sylvia.Sym{Any},2}:
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

julia> @! eval :f(c, d) = tr(X'X)
f (generic function with 1 method)

julia> methods(f)
# 1 method for generic function "f":
[1] f(c::Number, d::Number) in Main

julia> using BenchmarkTools

julia> @btime f(1, 2)
  0.026 ns (0 allocations: 0 bytes)
34
```
