# Sylvia

[![Build Status](https://travis-ci.org/dalum/Sylvia.jl.svg?branch=master)](https://travis-ci.org/dalum/Sylvia.jl)

A simple symbolic library with a pretty name.

## Usage

```julia
julia> using Sylvia

julia> @symbols Number a b c d
(a, b, c, d)

julia> x = a + b + c
a + b + c

julia> Sylvia.substitute(x, a => b, b => c)
c + c + c

julia> [a b; c d]^2
2×2 Array{Sylvia.Sym{Number},2}:
 a * a + b * c  a * b + b * d
 c * a + d * c  c * b + d * d

julia> c in d
c in d

julia> @assume c in d;

julia> c in d
true

julia> x = a + b + a + sin(c) * sin(c) + cos(a + d) * cos(d + a)
a + b + a + sin(c) * sin(c) + cos(a + d) * cos(d + a)

julia> gather(x)
a * 2 + b + cos(a + d) ^ 2 + sin(c) ^ 2

```
