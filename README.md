# Sylvia

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
