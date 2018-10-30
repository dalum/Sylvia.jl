# Sylvia 🧚🏻

[![Build Status](https://travis-ci.org/dalum/Sylvia.jl.svg?branch=master)](https://travis-ci.org/dalum/Sylvia.jl)

A simple symbolic library with a pretty name.

## Usage

```julia
julia> using Sylvia

julia> @symbols Number a b c d
(a, b, c, d)

julia> a + b*c + c |> gather
a + b * c + c

julia> @assume iszero(a) isone(b);

julia> a + b*c + c |> gather
2c

julia> substitute(a + b + c, a => b, b => c) |> gather
3c

julia> using LinearAlgebra

julia> @symbols Matrix{Float64} A B
(A, B)

julia> Matrix(A, 2, 2)^2
2×2 Array{Sylvia.Sym{Float64},2}:
 A[1, 1] * A[1, 1] + A[1, 2] * A[2, 1]  A[1, 1] * A[1, 2] + A[1, 2] * A[2, 2]
 A[2, 1] * A[1, 1] + A[2, 2] * A[2, 1]  A[2, 1] * A[1, 2] + A[2, 2] * A[2, 2]

julia> X = gather.(substitute.( # `b` is going to be optimized away, since we `@assume isone(b)`
           Matrix(A, 2, 2)^2,
           Ref(A[1,1] => a),
           Ref(A[1,2] => b),
           Ref(A[2,1] => c),
           Ref(A[2,2] => d)
       ))
2×2 Array{Sylvia.Sym{Number},2}:
 a ^ 2 + c      d
 a * c + c * d  c + d ^ 2

julia> f = @λ tr(X'X);

julia> methods(f) # a function of 3 variables, `a`, `c` and `d`
# 1 method for generic function "#24":
[1] (::getfield(Main, Symbol("##24#25")))(a, c, d) in Main

julia> using BenchmarkTools

julia> @btime f(1, 2, 3)
  17.491 ns (0 allocations: 0 bytes)
203
```
