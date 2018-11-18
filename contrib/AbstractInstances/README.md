# AbstractInstances.jl

[![Build Status](https://travis-ci.org/dalum/AbstractInstances.jl.svg?branch=master)](https://travis-ci.org/dalum/AbstractInstances.jl)
[![codecov](https://codecov.io/gh/dalum/AbstractInstances.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dalum/AbstractInstances.jl)

A package for making concrete instances of abstract types.

## Usage

```julia
julia> using AbstractInstances

julia> AbstractInstances.oftype(Number) isa Number
true

julia> AbstractInstances.oftype(Number) === AbstractInstances.oftype(Number)
false

julia> AbstractInstances.singleton(Number) isa Number
true

julia> AbstractInstances.singleton(Number) === AbstractInstances.singleton(Number)
true
```
