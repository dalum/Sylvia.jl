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
    "text": "The most basic expression in Sylvia is a symbol.  The simplest way to construct a symbol is using the @sym ...\" pattern:julia> using Sylvia;\n\njulia> @sym a\na\n\njulia> dump(a)\nSylvia.Sym{Any}\n  head: Symbol symbol\n  args: Array{Any}((1,))\n    1: Symbol aHere, the @sym macro creates a Sym object with the head symbol and binds it to the variable a.  The dump(a) showed us the internal structure of a as having the field head with the value :symbol, and the field args with the value: [:a].The type parameter Any seen in Sym{Any} is a type annotation to the symbol referred to as its \"tag\".  It can be accessed either using the type parameter or via the function tagof, similar to the built-in function typeof.  In this case, the symbol a can refer to a variable of any type, and thus its tag is set to Any.  Like types in Julia, Sylvia uses the tag to derive traits.  For instance, Sylvia will assume that expressions with a tag that is a subtype of Number commute under addition and multiplication.  The tag of a symbol can be annotated explicitly upon creation using @sym T :: ... notation:julia> @sym Number :: a\na\n\njulia> tagof(a)\nNumber"
},

{
    "location": "symbols/#Converting-tag-1",
    "page": "Symbols",
    "title": "Converting tag",
    "category": "section",
    "text": "To convert a symbol to one with a different tag, the @! ... :: T can be used:julia> @! a::Float64\na\n\njulia> tagof(@! a::Float64)\nFloat64\n\njulia> tagof(S\"a::Float64\")\nFloat64In the last line above, we encountered the string macro, S\"...\". Broadly speaking, the string macro is similar to the @! macro call: @! resolve ....  We shall delve into the @! macro in later sections."
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
    "text": "Sylvia provides methods for a variety of functions in base Julia, which allows expressions to be constructed by simply applying functions to symbols:julia> @sym Number :: a b\n(a, b)\n\njulia> a + b\na + b\n\njulia> acos(sin(a) + cos(b))\nacos(sin(a) + cos(b))\n\njulia> dump(a + b)\nSylvia.Sym{Number}\n  head: Symbol call\n  args: Array{Any}((3,))\n    1: Sylvia.Sym{typeof(+)}\n      head: Symbol function\n      args: Array{Any}((1,))\n        1: + (function of type typeof(+))\n    2: Sylvia.Sym{Number}\n      head: Symbol symbol\n      args: Array{Any}((1,))\n        1: Symbol a\n    3: Sylvia.Sym{Number}\n      head: Symbol symbol\n      args: Array{Any}((1,))\n        1: Symbol bAs can be seen in the example above, Sylvia uses the tag of a and b to correctly derive the tag of the expression a + b as Number.note: Note\nThe function responsible for deriving the tag in Sylvia is called Sylvia.promote_tag.  Sylvia relies on Julia for most of the promotion mechanisms, with additional methods for a few special cases to handle correct promotion.While the most common base functions have been overloaded to work with Syms, user–defined functions and functions in non–base libraries will, in general, not have methods for Syms.  Sylvia provides two means of working with functions that have not been overloaded: Sylvia.@register_atomic, and manual wrapping:julia> function f end\nf (generic function with 0 methods)\n\njulia> Sylvia.@register_atomic f 1\nf (generic function with 1 method)\n\njulia> f(a)\nf(a)\n\njulia> function g end\ng (generic function with 0 methods)\n\njulia> @! g(a)\ng(a)In the first example above, we registered a function, f, with 1 argument.  To \"register\" f, the Sylvia.@register_atomic f N macro creates methods for f N arguments of type Sym, including promoting methods for all combinations involving at least one Sym and arguments of Any type.  The all–Sym method then dispatches to Sylvia.apply(f, args...), which will create the f(args...) expression.In the second example, we declared the function g, and then applied it to a inside the @! macro.  When applying functions inside the @! macro, Sylvia will check if any methods exist for the given function and arguments.  If such a method exists, it will be applied and otherwise, the expression will be returned.  In this case, no method existed for g(::Sym).  This pattern works for any type of function and argument, and so we could also apply it to the number 10:julia> @! g(10)\ng(10)\n\njulia> g(x::Integer) = x^2\ng (generic function with 1 method)\n\njulia> @! g(10)\n100\n\njulia> @! g(10.0)\ng(10.0)Here we saw that defining a method for g(::Integer) suddenly allowed @! g(10) to call that method."
},

{
    "location": "expressions/#Rules-1",
    "page": "Expressions",
    "title": "Rules",
    "category": "section",
    "text": ""
},

]}
