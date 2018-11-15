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
    "text": "Welcome to the documentation for Sylvia.jl!This document is intended to help you get started with using the package."
},

{
    "location": "basics/#",
    "page": "Basics",
    "title": "Basics",
    "category": "page",
    "text": ""
},

{
    "location": "basics/#Basics-1",
    "page": "Basics",
    "title": "Basics",
    "category": "section",
    "text": "Sylvia is a library for working with symbolic expressions.  These expressions are stored inside mutable objects of the type Sym.  The structure of the Sym type is very similar to the Expr type found in base Julia, and consists of two fields, a head and args.  The head field describes which kind of expression object we are dealing with, and the args is a vector of objects describing the contents of the expression."
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
    "text": "The most basic expression in Sylvia is a symbol.  The simplest way to construct a symbol is using the @sym ... pattern:julia> using Sylvia;\n\njulia> @sym a\na\n\njulia> dump(a)\nSylvia.Sym{Any}\n  head: Symbol symbol\n  args: Array{Any}((1,))\n    1: Symbol aHere, the @sym macro creates a Sym object with the head symbol and binds it to the variable a.  The dump(a) showed us the internal structure of a as having the field head with the value :symbol, and the field args with the value: [:a]."
},

{
    "location": "symbols/#Tags-1",
    "page": "Symbols",
    "title": "Tags",
    "category": "section",
    "text": "The type parameter Any seen in Sym{Any} is a type annotation to the symbol referred to as its \"tag\".  It can be accessed either using the type parameter or via the function tagof, similar to the built-in function typeof.  In this case, the symbol a can refer to a variable of any type, and thus its tag is set to Any.  Like types in Julia, Sylvia uses the tag to derive traits.  For instance, Sylvia will assume that expressions with a tag that is a subtype of Number commute under addition and multiplication.  The tag of a symbol can be annotated explicitly upon creation using @sym [T] ... notation:julia> @sym [Number] a\na\n\njulia> tagof(a)\nNumber"
},

{
    "location": "symbols/#Converting-tags-1",
    "page": "Symbols",
    "title": "Converting tags",
    "category": "section",
    "text": "To convert a symbol to one with a different tag, the @! (...)::T or S\"...::T\" pattern is generally used:julia> @! a::Float64\na\n\njulia> tagof(@! a::Float64)\nFloat64\n\njulia> tagof(S\"a::Float64\")\nFloat64Both the @! macro and the S\"...\" string macro are powerful tools in Sylvia and are used for a lot more than just converting tags, as we shall see in the next section."
},

{
    "location": "symbols/#Unbound-symbols-1",
    "page": "Symbols",
    "title": "Unbound symbols",
    "category": "section",
    "text": "Sometimes, it is inconvenient to bind symbols to Julia variables. Perhaps the variable is already bound to another value, or maybe the symbol is only going to be used very locally, and binding it would take up too much space.  For these cases, Sylvia allows so–called unbound symbols to be created.  The pattern for this is again uses either the @! macro or the S\"...\" string macro:julia> @! :c\nc\n\njulia> S\":c\"\nc\n\njulia> tagof(@! :c)\nAny\n\njulia> c\nERROR: UndefVarError: c not definedIn the last line we saw, that although we can query the symbol c, it is not bound to the Julia variable c."
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
    "text": "Sylvia provides methods for a variety of functions in base Julia, which allows expressions to be constructed by simply applying functions to symbols:julia> @sym [Number] a b\n(a, b)\n\njulia> a + b\na + b\n\njulia> acos(sin(a) + cos(b))\nacos(sin(a) + cos(b))\n\njulia> dump(a + b)\nSylvia.Sym{Number}\n  head: Symbol call\n  args: Array{Any}((3,))\n    1: Sylvia.Sym{typeof(+)}\n      head: Symbol function\n      args: Array{Any}((1,))\n        1: + (function of type typeof(+))\n    2: Sylvia.Sym{Number}\n      head: Symbol symbol\n      args: Array{Any}((1,))\n        1: Symbol a\n    3: Sylvia.Sym{Number}\n      head: Symbol symbol\n      args: Array{Any}((1,))\n        1: Symbol bAs can be seen in the example above, Sylvia uses the tag of a and b to correctly derive the tag of the expression a + b as Number.note: Note\nThe function responsible for deriving the tag in Sylvia is called Sylvia.promote_tag.  Sylvia relies on Julia for most of the promotion mechanisms, with additional methods for a few special cases to handle correct promotion."
},

{
    "location": "expressions/#Functions-1",
    "page": "Expressions",
    "title": "Functions",
    "category": "section",
    "text": "While the most common base functions have been overloaded to work with Syms, user–defined functions and functions in non–base libraries will, in general, not have methods for Syms.  Sylvia provides two means of working with functions that have not been overloaded: Sylvia.@register, and manual wrapping:julia> function f end\nf (generic function with 0 methods)\n\njulia> Sylvia.@register f 1\nf (generic function with 1 method)\n\njulia> f(a)\nf(a)\n\njulia> function g end\ng (generic function with 0 methods)\n\njulia> @! g(a)\ng(a)In the first example above, we registered a function, f, with 1 argument.  To \"register\" f, the Sylvia.@register f N macro creates methods for f N arguments of type Sym, including promoting methods for all combinations involving at least one Sym and arguments of Any type.  The all–Sym method then dispatches to Sylvia.apply(f, args...), which will create the f(args...) expression.In the second example, we declared the function g, and then applied it to a inside the @! macro.  When applying functions inside the @! macro, Sylvia will check if any methods exist for the given function and arguments.  If such a method exists, it will be applied and otherwise, the expression will be returned.  In this case, no method existed for g(::Sym).  This pattern works for any type of function and argument, and so we could also apply it to the number 10:julia> @! g(10)\ng(10)\n\njulia> g(x::Integer) = x^2\ng (generic function with 1 method)\n\njulia> @! g(10)\n100\n\njulia> @! g(10.0)\ng(10.0)Here we saw that defining a method for g(::Integer) suddenly allowed @! g(10) to eagerly call that method."
},

{
    "location": "expressions/#Calling-symbols-1",
    "page": "Expressions",
    "title": "Calling symbols",
    "category": "section",
    "text": "In addition to calling functions, Sylvia allows any Sym object to be called, indexed and property accessed arbitrarily.  Together with unbound symbols, this can be useful for defining a function:julia> ex = @! function :h1(a, b, :c)\n           return a^2 + b * :c\n       end\nfunction h1(a::Number, b::Number, c)\n    return a ^ 2 + b * c\nend\n\njulia> eval(ex)\nh1 (generic function with 1 method)\n\njulia> h1(1, 2, 3)\n7Here we saw that Syms can be evaled just like Expr objects in Julia.  In fact, the Sym object itself prints code that can be copy–pasted directly into a file.  Because evaling code is a common task, the @! macro allows the keyword eval to be put before expressions, which will eval the resulting Sym in the current module:julia> @! eval function :h2(a, b, :c)\n           return a^2 + b * :c\n       end\nh2 (generic function with 1 method)\n\njulia> h2(1, 2, 3)\n7"
},

{
    "location": "expressions/#Rules-1",
    "page": "Expressions",
    "title": "Rules",
    "category": "section",
    "text": "Another use of the @! macro is for defining rules.  Rules in Sylvia are a set of patterns that transform expressions eagerly.  For instance, we could add a rule that transforms expressions of the type a + a to 2a.  The keyword set is used to add a new rule:julia> a + a\na + a\n\njulia> @! set a + a = 2a\nOrderedCollections.OrderedDict{Sylvia.Sym,Sylvia.Sym} with 1 entry:\n  a + a => 2a\n\njulia> a + a\n2a\n\njulia> b + b\nb + bNote that the rule we created only applies to symbols that are called a and whose tag is a subtype of the tag for which the rule was created.  To allow overriding rules, expressions inside the @! macro will not be resolved, unless the keyword resolve is given:julia> @! set a + a = 2.01a\n\njulia> @! a + a\na + a\n\njulia> @! resolve a + a\n2.01aUsing the resolve keyword and unbound symbols, we see that the rule only apply to symbols called a, if they have tag that is a subtype of Number:julia> @! resolve :a + :a\na + a\n\njulia> @! resolve :a::Float64 + :a::Float64\n2.01aTo remove a rule, we use the keyword unset:julia> @! unset a + a\nSylvia.Context with 0 entries\n\njulia> a + a\na + aFor inline usage, the @! resolve ... pattern can be a bit verbose. For this reason, the S\"...\" pattern is often more convenient.  The string macro pattern also obeys the resolving context in which it occurs, making it more flexible in some cases:julia> S\":a::Float64 + :a::Float64\"\n2.01a\n\njulia> @! S\":a::Float64 + :a::Float64\"\na + a"
},

{
    "location": "expressions/#Interpolation-1",
    "page": "Expressions",
    "title": "Interpolation",
    "category": "section",
    "text": "In some sense, Syms can be said to follow an opposite interpolation scheme when compared to Expr objects in Julia.  This is best illustrated by an example:julia> x = a + b\na + b\n\njulia> @! function :f(a, b)\n           return x\n       end\nfunction f(a::Number, b::Number)\n    return a + b\nend\n\njulia> @! function :f(a, b)\n           return :x\n       end\nfunction f(a::Number, b::Number)\n    return x\nendIn the first line above, we bind the Julia variable x to the Sym representing the addition of a and b.  In the second, we create a Sym representing a function definition using the arguments a and b.  The function body returns x, but is eagerly transformed into a + b, since that is what x has been bound to.  In the third line, the function definition is repeated, but this time using an unbound symbol x.  This prevents interpolation of x.  Compare this with the equivalent Julia expressions, which uses $ for interpolation:julia> :(function f(a, b)\n           return x\n       end)\n:(function f(a, b)\n      return x\n  end)\n\njulia> :(function f(a, b)\n           return $x\n       end)\n:(function f(a, b)\n      return a + b\n  end)"
},

]}
