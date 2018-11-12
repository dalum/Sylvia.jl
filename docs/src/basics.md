# Basics

Sylvia is a library for working with symbolic expressions.  These
expressions are stored inside mutable objects of the type `Sym`.  The
structure of the `Sym` type is very similar to the `Expr` type found
in base Julia, and consists of two fields, a `head` and `args`.  The
`head` field describes which kind of expression object we are dealing
with, and the `args` is a vector of objects describing the contents of
the expression.

## Symbols

The most basic expression in Sylvia is a symbol.  The simplest way to
construct a symbol is using the `S"..."` pattern:

```julia
julia> a = S"a"
a

julia> dump(a)
Sylvia.Sym{Any}
  head: Symbol symbol
  args: Array{Any}((1,))
    1: Symbol a
```

Here we constructed a symbol "a" and bound it to the Julia variable
`a`.  The `dump(a)` showed us the internal structure of `a` as having
the head `:symbol` with the `args`: `[:a]`.  The type parameter `Any`
seen in `Sym{Any}` is a type annotation to the symbol referred to as
its "tag".  It can be accessed either using the type parameter or via
the function `tagof`, similar to the built-in function `typeof`.  In
this case, the symbol `a` can refer to a variable of any type, and
thus its tag is set to `Any`.  Like types in Julia, Sylvia uses the
tag to derive traits.  For instance, Sylvia will assume that
expressions with a tag that is a subtype of `Number` commute under
addition and multiplication.  The tag of a symbol can be annotated
explicitly upon creation using "`x::T`" notation:

```julia
julia> a = S"a::Number"
a

julia> tagof(a)
Number
```

## Expressions

Now that we know how to make symbols, we can start constructing
expressions.  Sylvia provides methods for a variety of functions in
base Julia, which allows expressions to be constructed by simply
applying functions to symbols:

```julia
julia> a, b = S"a::Number", S"b::Number"
(a, b)

julia> a + b
a + b

julia> acos(sin(a) + cos(b))
acos(sin(a) + cos(b))

julia> dump(a + b)
Sylvia.Sym{Number}
  head: Symbol call
  args: Array{Any}((3,))
    1: Sylvia.Sym{typeof(+)}
      head: Symbol function
      args: Array{Any}((1,))
        1: + (function of type typeof(+))
    2: Sylvia.Sym{Number}
      head: Symbol symbol
      args: Array{Any}((1,))
        1: Symbol a
    3: Sylvia.Sym{Number}
      head: Symbol symbol
      args: Array{Any}((1,))
        1: Symbol b
```

As can be seen in the example above, Sylvia uses the tag of `a` and
`b` to correctly derive the tag of the expression `a + b` as `Number`.

!!! note
    The function responsible for deriving the tag in Sylvia is called
    `Sylvia.promote_tag`.  Sylvia relies on Julia for most of the
    promotion mechanisms, with additional methods for a few special cases
    to handle correct promotion.
