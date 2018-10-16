# Sylvia
[![Build Status](https://travis-ci.org/eveydee/Sylvia.jl.svg?branch=master)](https://travis-ci.org/dalum/Sylvia.jl)
[![Coverage Status](https://coveralls.io/repos/github/eveydee/Sylvia.jl/badge.svg?branch=master)](https://coveralls.io/github/dalum/Sylvia.jl?branch=master)
[![codecov.io](http://codecov.io/github/eveydee/Sylvia.jl/coverage.svg?branch=master)](http://codecov.io/github/dalum/Sylvia.jl?branch=master)

A simple symbolic library with a pretty name.

## Usage

```julia
julia> using Sylvia

julia> @symbols a b c d
(a, b, c, d)

julia> @rule a + b --> c

julia> a + b + c
2c

julia> [a b; c d]^2
2×2 Array{Any,2}:
 a ^ 2 + b * c  a * b + b * d
 c * a + d * c  c * b + d ^ 2
```
