# Contexts

Rules in Sylvia are stored in objects of the type `Sylvia.Context`.
When Sylvia resolves expressions, it uses a global reference,
`Sylvia.__ACTIVE_CONTEXT__`, which points to the current active
context.  Contexts are stored in a tree–structure, with each context
pointing to a single parent.  This allows contexts to inherit and
override rules from its parent contexts, without copying or modifying
them.

## User contexts

The default context pointed to by `Sylvia.__ACTIVE_CONTEXT__` is the
default user context.  This context has a parent,
`Sylvia.GLOBAL_CONTEXT`, which itself has no parent.  To see the rules
for the current context, `@! context` can be used:

```julia
julia> @! context
Sylvia.Context with 0 entries
```

To see the rules of the parent scope, we can access the `parent` field
of the active context:

```julia
julia> (@! context).parent
Sylvia.Context with 16 entries:
  x == x         => true
  zero(zero(x))  => zero(x)
  one(one(x))    => one(x)
  +x             => x
  ...
  x | y == y | x => true
```

These rules can be a bit opaque without type information.  Using
`Sylvia.set_annotations(true)`, we can turn on explicit annotations
when printing, to see when the rules are applied.  You should see
something like this:

```julia
julia> Sylvia.set_annotations(true);

julia> (@! context).parent
Sylvia.Context with 16 entries:
  (x::Wild{Any} == x::Wild{Any})::Any                   => true
  zero(zero(x::Wild{Any})::Any)::Any                    => zero(x::Wild{Any})::Any
  one(one(x::Wild{Any})::Any)::Any                      => one(x::Wild{Any})::Any
  (+(x::Wild{Number}))::Number                          => x::Wild{Number}
  ...
  ((x::Wild{Bool} | y::Wild{Bool})::Bool == (y::Wild{B… => true
```

Let us look at the first entry above.  It says that `x == x` is `true`
for objects of type `Sym{Wild{Any}}`.  The `Wild{T}` type is a special
type in Sylvia, which is used in matching (the `Sylvia.match`
function).  Matching is used when applying rules, and matching a
`Sym{<:T}` against a `Sym{Wild{T}}` returns a match, independent of
what the contents of the `Sym`s are.  Because it is true for all
types, `T`, that, `T<:Any` the `Sym{Wild{Any}}` rule applies to all
objects, and thus this rule ensures the identity `x == x` for all
`Sym`s.

The second rule, `zero(zero(x)) = zero(x)`, similarly claims that for
any `Sym`, `x`, `zero(zero(x))` should be transformed into `zero(x)`.
This rule ensures the identity, `iszero(zero(x))`, for all `x`, since
`iszero(x) = x == zero(x)`.  To see this, note that `iszero(zero(x))`
is transformed into `zero(x) == zero(zero(x))`, which is then
transformed into the expression `zero(x) == zero(x)`.  The first rule
above is then applied to return `true`.  This is best illustrated by
example:

```julia
julia> Sylvia.set_annotations(false)
false

julia> @! iszero(zero(:a))
@! zero(a) == zero(zero(a))

julia> iszero(zero(a))
true
```

Rules like these are crucial for making `Sym`s usable in generic code.

## Scoping

Because the default user context is global, it is often best practice
to create local contexts for local rules.  This is done using the
macro `@scope`:

```julia
julia> @! clear!
Sylvia.Context with 0 entries

julia> @! set a + a = 2a
Sylvia.Context with 1 entry:
  a + a => 2a

julia> @scope let
           println(a + a)
           @! set a + a = 0
           println(a + a)
       end
@! 2a
0

julia> a + a
@! 2a
```

The `@scope` macro creates an anonymous context and makes it active
with the previous active context as its parent.  Thus, as seen in the
last line above, the local rules inside the `@scope` macro do not
affect the context outside the scope.  The `@scope` macro also accepts
a context as its first argument, which allows executing inside that
scope.  We can use this to enter the parent scope of the active
context:

```julia
julia> @scope @!(context).parent let
           @! context
       end
Sylvia.Context with 16 entries:
  x == x         => true
  zero(zero(x))  => zero(x)
  ...
  x | y == y | x => true

julia> @! context
Sylvia.Context with 1 entry:
  a + a => 2a
```

An alternative use is to create a new parentless context, which
contain no rules at all:

```julia
julia> @scope Sylvia.Context() let
           a == a
       end
@! a == a
```

The `@scope` macro is generally paired with `let` or other blocks in
Julia that introduce scopes for Julia variables.  However, `@scope`
accepts any type of expression head.  This can be useful for creating
extra rules that are valid in a given context during the creation of a
new variable, or for applying rules inside a function body that is
already scoped.  This latter case is due to the fact that `@scope f(x)
= x^2` will apply a new scope during the *creation* of the function
`f`, rather than during each call, which should be written: `f(x) =
@scope x^2`.  Doing this in the wrong order can lead to undesired
side–effects.  Consider the following example, which returns `0` if
the result of `x^2` matches `:a^2`:

```julia
julia> @! clear!
Sylvia.Context with 0 entries

julia> @scope @eval f(x) = begin
           @! set :a^2 = 0
           return x^2
       end
f (generic function with 1 method)

julia> @! context
Sylvia.Context with 0 entries

julia> f(a)
0

julia> f(2)
4

julia> @! context
Sylvia.Context with 1 entry:
  a ^ 2 => 0
```

Here, the function creates the rule in the *calling* context, rather
than the context in which it was created.  This function should have
been written in the opposite order, which also doesn't require the use
of `@eval`:

```julia
julia> f(x) = @scope begin
           @! set :a^2 = 0
           return x^2
       end
f (generic function with 1 method)

julia> f(a)
0

julia> @! context
Sylvia.Context with 0 entries
```
