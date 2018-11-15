# Expressions

Sylvia provides methods for a variety of functions in base Julia,
which allows expressions to be constructed by simply applying
functions to symbols:

```julia
julia> @sym [Number] a b
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

## Functions

While the most common base functions have been overloaded to work with
`Sym`s, user–defined functions and functions in non–base libraries
will, in general, not have methods for `Sym`s.  Sylvia provides two
means of working with functions that have not been overloaded:
`Sylvia.@register`, and manual wrapping:

```julia
julia> function f end
f (generic function with 0 methods)

julia> Sylvia.@register f 1
f (generic function with 1 method)

julia> f(a)
f(a)

julia> function g end
g (generic function with 0 methods)

julia> @! g(a)
g(a)
```

In the first example above, we registered a function, `f`, with `1`
argument.  To "register" `f`, the `Sylvia.@register f N` macro
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
`@! g(10)` to eagerly call that method.

## Calling symbols

In addition to calling functions, Sylvia allows any `Sym` object to be
called, indexed and property accessed arbitrarily.  Together with
unbound symbols, this can be useful for defining a function:

```julia
julia> ex = @! function :h1(a, b, :c)
           return a^2 + b * :c
       end
function h1(a::Number, b::Number, c)
    return a ^ 2 + b * c
end

julia> eval(ex)
h1 (generic function with 1 method)

julia> h1(1, 2, 3)
7
```

Here we saw that `Sym`s can be `eval`ed just like `Expr` objects in
Julia.  In fact, the `Sym` object itself prints code that can be
copy–pasted directly into a file.  Because `eval`ing code is a common
task, the `@!` macro allows the keyword `eval` to be put before
expressions, which will `eval` the resulting `Sym` in the current
module:

```julia
julia> @! eval function :h2(a, b, :c)
           return a^2 + b * :c
       end
h2 (generic function with 1 method)

julia> h2(1, 2, 3)
7
```

## Rules

Another use of the `@!` macro is for defining rules.  Rules in Sylvia
are a set of patterns that transform expressions eagerly.  For
instance, we could add a rule that transforms expressions of the type
`a + a` to `2a`.  The keyword `set` is used to add a new rule:

```julia
julia> a + a
a + a

julia> @! set a + a = 2a
OrderedCollections.OrderedDict{Sylvia.Sym,Sylvia.Sym} with 1 entry:
  a + a => 2a

julia> a + a
2a

julia> b + b
b + b
```

Note that the rule we created *only* applies to symbols that are
called `a` and whose tag is a subtype of the tag for which the rule
was created.  To allow overriding rules, expressions inside the `@!`
macro will not be resolved, unless the keyword `resolve` is given:

```julia
julia> @! set a + a = 2.01a

julia> @! a + a
a + a

julia> @! resolve a + a
2.01a
```

Using the resolve keyword and unbound symbols, we see that the rule
only apply to symbols called `a`, if they have tag that is a subtype
of `Number`:

```julia
julia> @! resolve :a + :a
a + a

julia> @! resolve :a::Float64 + :a::Float64
2.01a
```

To remove a rule, we use the keyword `unset`:

```julia
julia> @! unset a + a
Sylvia.Context with 0 entries

julia> a + a
a + a
```

For inline usage, the `@! resolve ...` pattern can be a bit verbose.
For this reason, the `S"..."` pattern is often more convenient.  The
string macro pattern also obeys the resolving context in which it
occurs, making it more flexible in some cases:

```julia
julia> S":a::Float64 + :a::Float64"
2.01a

julia> @! S":a::Float64 + :a::Float64"
a + a
```

## Interpolation

In some sense, `Sym`s can be said to follow an opposite interpolation
scheme when compared to `Expr` objects in Julia.  This is best
illustrated by an example:
```julia
julia> x = a + b
a + b

julia> @! function :f(a, b)
           return x
       end
function f(a::Number, b::Number)
    return a + b
end

julia> @! function :f(a, b)
           return :x
       end
function f(a::Number, b::Number)
    return x
end
```

In the first line above, we bind the Julia variable `x` to the `Sym`
representing the addition of `a` and `b`.  In the second, we create a
`Sym` representing a function definition using the arguments `a` and
`b`.  The function body returns `x`, but is eagerly transformed into
`a + b`, since that is what `x` has been bound to.  In the third line,
the function definition is repeated, but this time using an unbound
symbol `x`.  This prevents interpolation of `x`.  Compare this with
the equivalent Julia expressions, which uses `$` for interpolation:

```julia
julia> :(function f(a, b)
           return x
       end)
:(function f(a, b)
      return x
  end)

julia> :(function f(a, b)
           return $x
       end)
:(function f(a, b)
      return a + b
  end)
```
