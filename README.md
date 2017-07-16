# Sylvia
[![Build Status](https://travis-ci.org/eveydee/Sylvia.jl.svg?branch=master)](https://travis-ci.org/eveydee/Sylvia.jl)
[![Coverage Status](https://coveralls.io/repos/eveydee/Sylvia.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/eveydee/Sylvia.jl?branch=master)
[![codecov.io](http://codecov.io/github/eveydee/Sylvia.jl/coverage.svg?branch=master)](http://codecov.io/github/eveydee/Sylvia.jl?branch=master)

A simple symbolic library with a pretty name.

## Usage

```julia
julia> using Sylvia
julia> @symbols a b c d
julia> A = [a b; c d]
julia> A^2
2×2 Array{Sylvia.Symbolic,2}:
 a ^ 2 + b * c  a * b + b * d
 c * a + d * c  c * b + d ^ 2

julia> @def f = A^2 # alphabetically ordered automagic parameters
julia> @def g(d, c, b) = A^2 # manual parameters, unspecified `a` means global
julia> f(1, 2, 3, 4)
2×2 Array{Int64,2}:
  7  10
 15  22

julia> g(4, 3, 2)
2×2 Array{Any,2}:
 6 + a ^ 2    8 + 2a
 12 + 3a    22

julia> a = 2
julia> g(4, 3, 2)
2×2 Array{Int64,2}:
 10  12
 18  22
```
