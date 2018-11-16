var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#Sylvia-1",
    "page": "Home",
    "title": "Sylvia",
    "category": "section",
    "text": "Welcome to the documentation for Sylvia.jl!This document is intended to help you get started with using the package.  If you have any suggestions, please open an issue or pull request on GitHub."
},

{
    "location": "#Introduction-1",
    "page": "Home",
    "title": "Introduction",
    "category": "section",
    "text": "Sylvia is a library for working with symbolic expressions in Julia. \"Symbolic\" here means that the symbols and computations inside the expression do not necessarily have a known value.  Instead, symbols are representations of a large variety of possible values.  When writing a simple expression such as a + b, the values a and b do not yet have a value.  However, if a and b are both numbers, we know based on the properties of the operator + that a + b is also a number.  This information is useful both as optimization and comprehension tools, i. e., for generating fast code and for understanding the properties of an expression.The standard way of working with expressions in Julia is using macros. The expression objects available to a macro, however, is generated at parse time which means that they do not know which function + corresponds to, nor what types a and b has.The goal of Sylvia is to provide a toolbox for working with expressions that contain information beyond what is known at parse time.  That is, the expression a + b in Sylvia knows that + is the + operator from the Base module, and a, b have known types, in Sylvia referred to as their tags."
},

{
    "location": "symbols/#",
    "page": "Symbols",
    "title": "Symbols",
    "category": "page",
    "text": ""
},

{
    "location": "symbols/#Symbols-1",
    "page": "Symbols",
    "title": "Symbols",
    "category": "section",
    "text": "The most basic expression in Sylvia is a symbol.  The simplest way to construct a symbol is using the @sym ... pattern:julia> using Sylvia;\n\njulia> @sym a\n@! a\n\njulia> dump(a)\nSylvia.Sym{Any}\n  head: Symbol symbol\n  args: Array{Any}((1,))\n    1: Symbol aHere, the @sym macro creates a Sym object with the head symbol and binds it to the variable a.  The dump(a) showed us the internal structure of a as having the field head with the value :symbol, and the field args with the value: [:a]."
},

{
    "location": "symbols/#Tags-1",
    "page": "Symbols",
    "title": "Tags",
    "category": "section",
    "text": "The type parameter Any seen in Sym{Any} is a type annotation to the symbol referred to as its \"tag\".  It can be accessed either using the type parameter or via the function tagof, similar to the built-in function typeof.  In this case, the symbol a can refer to a variable of any type, and thus its tag is set to Any.  Like types in Julia, Sylvia uses the tag to derive traits.  For instance, Sylvia will assume that expressions with a tag that is a subtype of Number commute under addition and multiplication.  The tag of a symbol can be annotated explicitly upon creation using @sym [T] ... notation:julia> @sym [Number] a\n@! a\n\njulia> tagof(a)\nNumber"
},

{
    "location": "symbols/#Converting-tags-1",
    "page": "Symbols",
    "title": "Converting tags",
    "category": "section",
    "text": "To convert a symbol to one with a different tag, the @! (...)::T or S\"...::T\" pattern is generally used:julia> @! a::Float64\n@! a\n\njulia> tagof(@! a::Float64)\nFloat64\n\njulia> tagof(S\"a::Float64\")\nFloat64Both the @! macro and the S\"...\" string macro are powerful tools in Sylvia and are used for a lot more than just converting tags, as we shall see in the next section."
},

{
    "location": "symbols/#Unbound-symbols-1",
    "page": "Symbols",
    "title": "Unbound symbols",
    "category": "section",
    "text": "Sometimes, it is inconvenient to bind symbols to Julia variables. Perhaps the variable is already bound to another value, or maybe the symbol is only going to be used very locally, and binding it would take up too much space.  For these cases, Sylvia allows so–called unbound symbols to be created.  The pattern for this is again uses either the @! macro or the S\"...\" string macro:julia> @! :c\n@! c\n\njulia> S\":c\"\n@! c\n\njulia> tagof(@! :c)\nAny\n\njulia> c\nERROR: UndefVarError: c not definedIn the last line we saw, that although we can query the symbol c, it is not bound to the Julia variable c."
},

{
    "location": "expressions/#",
    "page": "Expressions",
    "title": "Expressions",
    "category": "page",
    "text": ""
},

{
    "location": "expressions/#Expressions-1",
    "page": "Expressions",
    "title": "Expressions",
    "category": "section",
    "text": "Sylvia provides methods for a variety of functions in base Julia, which allows expressions to be constructed by simply applying functions to symbols:julia> @sym [Number] a b\n(@! a, @! b)\n\njulia> a + b\n@! a + b\n\njulia> acos(sin(a) + cos(b))\n@! acos(sin(a) + cos(b))\n\njulia> dump(a + b)\nSylvia.Sym{Number}\n  head: Symbol call\n  args: Array{Any}((3,))\n    1: Sylvia.Sym{typeof(+)}\n      head: Symbol fn\n      args: Array{Any}((1,))\n        1: + (function of type typeof(+))\n    2: Sylvia.Sym{Number}\n      head: Symbol symbol\n      args: Array{Any}((1,))\n        1: Symbol a\n    3: Sylvia.Sym{Number}\n      head: Symbol symbol\n      args: Array{Any}((1,))\n        1: Symbol bAs can be seen in the example above, Sylvia uses the tag of a and b to correctly derive the tag of the expression a + b as Number.note: Note\nThe function responsible for deriving the tag in Sylvia is called Sylvia.promote_tag.  Sylvia relies on Julia for most of the promotion mechanisms, with additional methods for a few special cases to handle correct promotion."
},

{
    "location": "expressions/#Functions-1",
    "page": "Expressions",
    "title": "Functions",
    "category": "section",
    "text": "While the most common base functions have been overloaded to work with Syms, user–defined functions and functions in non–base libraries will, in general, not have methods for Syms.  Sylvia provides two means of working with functions that have not been overloaded: Sylvia.@register, and manual wrapping:julia> function f end\nf (generic function with 0 methods)\n\njulia> Sylvia.@register f 1\nf (generic function with 1 method)\n\njulia> f(a)\n@! f(a)\n\njulia> function g end\ng (generic function with 0 methods)\n\njulia> @! g(a)\n@! g(a)In the first example above, we registered a function, f, with 1 argument.  To \"register\" f, the Sylvia.@register f N macro creates methods for f N arguments of type Sym, including promoting methods for all combinations involving at least one Sym and arguments of Any type.  The all–Sym method then dispatches to Sylvia.apply(f, args...), which will create the f(args...) expression.In the second example, we declared the function g, and then applied it to a inside the @! macro.  When applying functions inside the @! macro, Sylvia will check if any methods exist for the given function and arguments.  If such a method exists, it will be applied and otherwise, the expression will be returned.  In this case, no method existed for g(::Sym).  This pattern works for any type of function and argument, and so we could also apply it to the number 10:julia> @! g(10)\n@! g(10)\n\njulia> g(x::Integer) = x^2\ng (generic function with 1 method)\n\njulia> g(10)\n100\n\njulia> @! g(10)\n@! 100\n\njulia> @! g(10.0)\n@! g(10.0)Here we saw that defining a method for g(::Integer) suddenly allowed @! g(10) to eagerly call that method.note: Note\nWhen calling inside the @! macro, the result is always converted to a Sym."
},

{
    "location": "expressions/#Calling-symbols-1",
    "page": "Expressions",
    "title": "Calling symbols",
    "category": "section",
    "text": "In addition to calling functions, Sylvia allows any Sym object to be called, indexed and property accessed arbitrarily.  Together with unbound symbols, this can be useful for defining a function:julia> ex = @! function :h1(a, b, :c)\n           return a^2 + b * :c\n       end\n@! function h1(a::Number, b::Number, c)\n    return a ^ 2 + b * c\nend\n\njulia> eval(ex)\nh1 (generic function with 1 method)\n\njulia> h1(1, 2, 3)\n7Here we saw that Syms can be evaled just like Expr objects in Julia.  In fact, the Sym object itself prints code that can be copy–pasted directly into a file.  Because evaling code is a common task, the @! macro allows the keyword eval to be put before expressions, which will eval the resulting Sym in the current module:julia> @! eval function :h2(a, b, :c)\n           return a^2 + b * :c\n       end\nh2 (generic function with 1 method)\n\njulia> h2(1, 2, 3)\n7Because the @! ...::T pattern is used to declare/convert the tag of Syms, writing :: inside an expression using the @! macro or S\"...\" string macro cannot be used for type assertions.  To overcome this, Sylvia allows writing for colons, ::::, to represent :: in normal Julia code:julia> @! function :f(a, b)::::Number\n           a + b\n       end\n@! function f(a, b)::Number\n    a + b\nend"
},

{
    "location": "expressions/#Rules-1",
    "page": "Expressions",
    "title": "Rules",
    "category": "section",
    "text": "Another use of the @! macro is for defining rules.  Rules in Sylvia are a set of patterns that transform expressions eagerly.  For instance, we could add a rule that transforms expressions of the type a + a to 2a.  The keyword set is used to add a new rule:julia> a + a\n@! a + a\n\njulia> @! set a + a = 2a\nSylvia.Context with 1 entry:\n  a + a => 2a\n\njulia> a + a\n@! 2aTo allow overriding rules, expressions inside the @! macro will not be resolved, unless the keyword resolve is given:julia> @! a + a\n@! a + a\n\njulia> @! resolve a + a\n@! 2aUsing the resolve keyword and unbound symbols, we see that the rule only apply to symbols called a, if they have tag that is a subtype of Number:julia> @! resolve :a + :a\n@! a + a\n\njulia> @! resolve :b::Float64 + :b::Float64\n@! b + b\n\njulia> @! resolve :a::Float64 + :a::Float64\n@! 2aTo remove a rule, we use the keyword unset:julia> @! unset a + a\nSylvia.Context with 0 entries\n\njulia> a + a\n@! a + aFor inline usage, the @! resolve ... pattern can be a bit verbose. For this reason, the S\"...\" pattern is often more convenient.  The string macro pattern also obeys the resolving context in which it occurs, making it more flexible in some cases:julia> @! set a + a = 2.01a;\n\njulia> S\":a::Float64 + :a::Float64\"\n@! 2.01a\n\njulia> @! S\":a::Float64 + :a::Float64\"\n@! a + a"
},

{
    "location": "expressions/#Interpolation-1",
    "page": "Expressions",
    "title": "Interpolation",
    "category": "section",
    "text": "In some sense, Syms can be said to follow an opposite interpolation scheme when compared to Expr objects in Julia.  This is best illustrated by an example:julia> x = a + b\n@! a + b\n\njulia> @! function :f(a, b)\n           return x\n       end\n@! function f(a::Number, b::Number)\n    return a + b\nend\n\njulia> @! function :f(a, b)\n           return :x\n       end\n@! function f(a::Number, b::Number)\n    return x\nendIn the first line above, we bind the Julia variable x to the Sym representing the addition of a and b.  In the second, we create a Sym representing a function definition using the arguments a and b.  The function body returns x, but is eagerly transformed into a + b, since that is what x has been bound to.  In the third line, the function definition is repeated, but this time using an unbound symbol x.  This prevents interpolation of x.  Compare this with the equivalent Julia expressions, which uses $ for interpolation:julia> :(function f(a, b)\n           return x\n       end)\n:(function f(a, b)\n      return x\n  end)\n\njulia> :(function f(a, b)\n           return $x\n       end)\n:(function f(a, b)\n      return (@! a + b)\n  end)"
},

{
    "location": "contexts/#",
    "page": "Contexts",
    "title": "Contexts",
    "category": "page",
    "text": ""
},

{
    "location": "contexts/#Contexts-1",
    "page": "Contexts",
    "title": "Contexts",
    "category": "section",
    "text": "Rules in Sylvia are stored in objects of the type Sylvia.Context. When Sylvia resolves expressions, it uses a global reference, Sylvia.__ACTIVE_CONTEXT__, which points to the current active context.  Contexts are stored in a tree–structure, with each context pointing to a single parent.  This allows contexts to inherit and override rules from its parent contexts, without copying or modifying them."
},

{
    "location": "contexts/#User-contexts-1",
    "page": "Contexts",
    "title": "User contexts",
    "category": "section",
    "text": "The default context pointed to by Sylvia.__ACTIVE_CONTEXT__ is the default user context.  This context has a parent, Sylvia.GLOBAL_CONTEXT, which itself has no parent.  To see the rules for the current context, @! context can be used:julia> @! context\nSylvia.Context with 0 entriesTo see the rules of the parent scope, we can access the parent field of the active context:julia> (@! context).parent\nSylvia.Context with 16 entries:\n  x == x         => true\n  zero(zero(x))  => zero(x)\n  one(one(x))    => one(x)\n  +x             => x\n  ...\n  x | y == y | x => trueThese rules can be a bit opaque without type information.  Using Sylvia.set_annotations(true), we can turn on explicit annotations when printing, to see when the rules are applied.  You should see something like this:julia> Sylvia.set_annotations(true);\n\njulia> (@! context).parent\nSylvia.Context with 16 entries:\n  (x::Wild{Any} == x::Wild{Any})::Any                   => true\n  zero(zero(x::Wild{Any})::Any)::Any                    => zero(x::Wild{Any})::Any\n  one(one(x::Wild{Any})::Any)::Any                      => one(x::Wild{Any})::Any\n  (+(x::Wild{Number}))::Number                          => x::Wild{Number}\n  ...\n  ((x::Wild{Bool} | y::Wild{Bool})::Bool == (y::Wild{B… => trueLet us look at the first entry above.  It says that x == x is true for objects of type Sym{Wild{Any}}.  The Wild{T} type is a special type in Sylvia, which is used in matching (the Sylvia.match function).  Matching is used when applying rules, and matching a Sym{<:T} against a Sym{Wild{T}} returns a match, independent of what the contents of the Syms are.  Because it is true for all types, T, that, T<:Any the Sym{Wild{Any}} rule applies to all objects, and thus this rule ensures the identity x == x for all Syms.The second rule, zero(zero(x)) = zero(x), similarly claims that for any Sym, x, zero(zero(x)) should be transformed into zero(x). This rule ensures the identity, iszero(zero(x)), for all x, since iszero(x) = x == zero(x).  To see this, note that iszero(zero(x)) is transformed into zero(x) == zero(zero(x)), which is then transformed into the expression zero(x) == zero(x).  The first rule above is then applied to return true.  This is best illustrated by example:julia> Sylvia.set_annotations(false)\nfalse\n\njulia> @! iszero(zero(:a))\n@! zero(a) == zero(zero(a))\n\njulia> iszero(zero(a))\ntrueRules like these are crucial for making Syms usable in generic code."
},

{
    "location": "contexts/#Scoping-1",
    "page": "Contexts",
    "title": "Scoping",
    "category": "section",
    "text": "Because the default user context is global, it is often best practice to create local contexts for local rules.  This is done using the macro @scope:julia> @! clear!\nSylvia.Context with 0 entries\n\njulia> @! set a + a = 2a\nSylvia.Context with 1 entry:\n  a + a => 2a\n\njulia> @scope let\n           println(a + a)\n           @! set a + a = 0\n           println(a + a)\n       end\n@! 2a\n0\n\njulia> a + a\n@! 2aThe @scope macro creates an anonymous context and makes it active with the previous active context as its parent.  Thus, as seen in the last line above, the local rules inside the @scope macro do not affect the context outside the scope.  The @scope macro also accepts a context as its first argument, which allows executing inside that scope.  We can use this to enter the parent scope of the active context:julia> @scope @!(context).parent let\n           @! context\n       end\nSylvia.Context with 16 entries:\n  x == x         => true\n  zero(zero(x))  => zero(x)\n  ...\n  x | y == y | x => true\n\njulia> @! context\nSylvia.Context with 1 entry:\n  a + a => 2aAn alternative use is to create a new parentless context, which contain no rules at all:julia> @scope Sylvia.Context() let\n           a == a\n       end\n@! a == aThe @scope macro is generally paired with let or other blocks in Julia that introduce scopes for Julia variables.  However, @scope accepts any type of expression head.  This can be useful for creating extra rules that are valid in a given context during the creation of a new variable, or for applying rules inside a function body that is already scoped.  This latter case is due to the fact that @scope f(x) = x^2 will apply a new scope during the creation of the function f, rather than during each call, which should be written: f(x) = @scope x^2.  Doing this in the wrong order can lead to undesired side–effects.  Consider the following example, which returns 0 if the result of x^2 matches :a^2:julia> @! clear!\nSylvia.Context with 0 entries\n\njulia> @scope @eval f(x) = begin\n           @! set :a^2 = 0\n           return x^2\n       end\nf (generic function with 1 method)\n\njulia> @! context\nSylvia.Context with 0 entries\n\njulia> f(a)\n0\n\njulia> f(2)\n4\n\njulia> @! context\nSylvia.Context with 1 entry:\n  a ^ 2 => 0Here, the function creates the rule in the calling context, rather than the context in which it was created.  This function should have been written in the opposite order, which also doesn\'t require the use of @eval:julia> f(x) = @scope begin\n           @! set :a^2 = 0\n           return x^2\n       end\nf (generic function with 1 method)\n\njulia> f(a)\n0\n\njulia> @! context\nSylvia.Context with 0 entries"
},

]}
