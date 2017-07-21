# isless

isless(x, y) = Base.isless(x, y)

# commutes

commutes(x, y) = false
commutes(::Number, ::Number) = true
commutes(::Number, ::Any) = true
commutes(::Any, ::Number) = false

# sort

add_order(x, y) = isless(string(firstsymbol(x, x)), string(firstsymbol(y, y)))
mul_order(x, y) = commutes(x, y)

