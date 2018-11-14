# Expressions

Sylvia provides methods for a variety of functions in base Julia,
which allows expressions to be constructed by simply applying
functions to symbols:

```julia
julia> @sym Number :: a b
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

While the most common base functions have been overloaded to work with
`Sym`s, user–defined functions and functions in non–base libraries
will, in general, not have methods for `Sym`s.  Sylvia provides two
means of working with functions that have not been overloaded:
`Sylvia.@register_atomic`, and manual wrapping:

```julia
julia> function f end
f (generic function with 0 methods)

julia> Sylvia.@register_atomic f 1
f (generic function with 1 method)

julia> f(a)
f(a)

julia> function g end
g (generic function with 0 methods)

julia> @! g(a)
g(a)
```

In the first example above, we registered a function, `f`, with `1`
argument.  To "register" `f`, the `Sylvia.@register_atomic f N` macro
creates methods for `f` `N` arguments of type `Sym`, including
promoting methods for all combinations involving at least one `Sym`
and arguments of `Any` type.  The all–`Sym` method then dispatches to
`Sylvia.apply(f, args...)`, which will create the `f(args...)`
expression.

In the second example, we declared the function `g`, and then applied
it to `a` inside the `@!` macro.  When applying functions inside the
`@!` macro, Sylvia will check if any methods exist for the given
function and arguments.  If such a method exists, it will be applied
and otherwise, the expression will be returned.  In this case, no
method existed for `g(::Sym)`.  This pattern works for any type of
function and argument, and so we could also apply it to the number
`10`:

```julia
julia> @! g(10)
g(10)

julia> g(x::Integer) = x^2
g (generic function with 1 method)

julia> @! g(10)
100

julia> @! g(10.0)
g(10.0)
```

Here we saw that defining a method for `g(::Integer)` suddenly allowed
`@! g(10)` to call that method.

## Rules

