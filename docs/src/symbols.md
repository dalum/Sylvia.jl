# Symbols

The most basic expression in Sylvia is a symbol.  The simplest way to
construct a symbol is using the `@sym ..."` pattern:

```julia
julia> using Sylvia;

julia> @sym a
a

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

The type parameter `Any` seen in `Sym{Any}` is a type annotation to
the symbol referred to as its "tag".  It can be accessed either using
the type parameter or via the function `tagof`, similar to the
built-in function `typeof`.  In this case, the symbol `a` can refer to
a variable of any type, and thus its tag is set to `Any`.  Like types
in Julia, Sylvia uses the tag to derive traits.  For instance, Sylvia
will assume that expressions with a tag that is a subtype of `Number`
commute under addition and multiplication.  The tag of a symbol can be
annotated explicitly upon creation using `@sym T :: ...` notation:

```julia
julia> @sym Number :: a
a

julia> tagof(a)
Number
```

## Converting tag

To convert a symbol to one with a different tag, the `@! ... :: T` can
be used:

```julia
julia> @! a::Float64
a

julia> tagof(@! a::Float64)
Float64

julia> tagof(S"a::Float64")
Float64
```

In the last line above, we encountered the string macro, `S"..."`.
Broadly speaking, the string macro is similar to the `@!` macro call:
`@! resolve ...`.  We shall delve into the `@!` macro in later
sections.
