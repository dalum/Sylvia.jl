# Sylvia

Welcome to the documentation for Sylvia.jl!

This document is intended to help you get started with using the
package.  If you have any suggestions, please open an issue or pull
request on [GitHub](https://github.com/dalum/Sylvia.jl).

## Introduction

Sylvia is a library for working with symbolic expressions in Julia.
"Symbolic" here means that the symbols and computations inside the
expression do not necessarily have a known value.  Instead, symbols
are representations of a large variety of possible values.  When
writing a simple expression such as `a + b`, the values `a` and `b` do
not yet have a value.  However, if `a` and `b` are both numbers, we
know based on the properties of the operator `+` that `a + b` is also
a number.  This information is useful both as optimization and
comprehension tools, i. e., for generating fast code and for
understanding the properties of an expression.

The standard way of working with expressions in Julia is using macros.
The expression objects available to a macro, however, is generated at
parse time which means that they do not know which function `+`
corresponds to, nor what types `a` and `b` has.

The goal of Sylvia is to provide a toolbox for working with
expressions that contain information beyond what is known at parse
time.  That is, the expression `a + b` in Sylvia knows that `+` is the
`+` operator from the `Base` module, and `a`, `b` have known types, in
Sylvia referred to as their *tags*.
