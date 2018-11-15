# Symbols

The most basic expression in Sylvia is a symbol.  The simplest way to
construct a symbol is using the `@sym ...` pattern:

```julia
julia> using Sylvia;

julia> @sym a
@! a

julia> dump(a)
Sylvia.Sym{Any}
  head: Symbol symbol
  args: Array{Any}((1,))
    1: Symbol a
```

Here, the `@sym` macro creates a `Sym` object with the head `symbol`
and binds it to the variable `a`.  The `dump(a)` showed us the
internal structure of `a` as having the field `head` with the value
`:symbol`, and the field `args` with the value: `[:a]`.

## Tags

The type parameter `Any` seen in `Sym{Any}` is a type annotation to
the symbol referred to as its "tag".  It can be accessed either using
the type parameter or via the function `tagof`, similar to the
built-in function `typeof`.  In this case, the symbol `a` can refer to
a variable of any type, and thus its tag is set to `Any`.  Like types
in Julia, Sylvia uses the tag to derive traits.  For instance, Sylvia
will assume that expressions with a tag that is a subtype of `Number`
commute under addition and multiplication.  The tag of a symbol can be
annotated explicitly upon creation using `@sym [T] ...` notation:

```julia
julia> @sym [Number] a
@! a

julia> tagof(a)
Number
```

## Converting tags

To convert a symbol to one with a different tag, the `@! (...)::T` or
`S"...::T"` pattern is generally used:

```julia
julia> @! a::Float64
@! a

julia> tagof(@! a::Float64)
Float64

julia> tagof(S"a::Float64")
Float64
```

Both the `@!` macro and the `S"..."` string macro are powerful tools
in Sylvia and are used for a lot more than just converting tags, as we
shall see in the next section.

## Unbound symbols

Sometimes, it is inconvenient to bind symbols to Julia variables.
Perhaps the variable is already bound to another value, or maybe the
symbol is only going to be used very locally, and binding it would
take up too much space.  For these cases, Sylvia allows so–called
*unbound symbols* to be created.  The pattern for this is again uses
either the `@!` macro or the `S"..."` string macro:

```julia
julia> @! :c
@! c

julia> S":c"
@! c

julia> tagof(@! :c)
Any

julia> c
ERROR: UndefVarError: c not defined
```

In the last line we saw, that although we can query the symbol `c`, it
is not bound to the Julia variable `c`.
