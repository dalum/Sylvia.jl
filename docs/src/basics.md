# Basics

Sylvia is a library for working with symbolic expressions.  These
expressions are stored inside mutable objects of the type `Sym`.  The
structure of the `Sym` type is very similar to the `Expr` type found
in base Julia, and consists of two fields, a `head` and `args`.  The
`head` field describes which kind of expression object we are dealing
with, and the `args` is a vector of objects describing the contents of
the expression.
