using Base.Test
using Sylvia
using Sylvia: Symbolic, symbol

@symbols a b c d

# Conversion
@test symbol(a) == a == :a
@test [a] == Symbolic[:a]
@test convert(Int, Symbolic(1)) === Int(1)
@test convert(Symbolic{AbstractFloat}, Symbolic(1)) === Symbolic(1.0)
@test iszero(Symbolic(0)) & iszero(Symbolic(0.0))
@test isone(Symbolic(1)) & isone(Symbolic(1.0))

# Basic identities
@test a + 0 == a
@test a - a == 0
@test a - 0 == a
@test a * 1 == a
@test a / 1 == a
@test 1 \ a == a
@test a * 0 == 0
@test 0 / a == 0
@test a \ 0 == 0
@test a ^ 1 == a

@test a + a == 2a
@test a * a == a^2
