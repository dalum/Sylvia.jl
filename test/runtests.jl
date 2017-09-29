using Base.Test
using Sylvia
using Sylvia: Symbolic, symbol

@symbols a b c d [Matrix{Number}] A B C D

# Conversion
@test symbol(a) == a == :a
@test [a] == Symbolic[:a]
@test convert(Int, Symbolic(1)) === Int(1)
@test convert(Symbolic{AbstractFloat,typeof(1.0)}, Symbolic(1)) === Symbolic(1.0)
@test iszero(Symbolic(0)) & iszero(Symbolic(0.0))
@test Sylvia.isone(Symbolic(1)) & Sylvia.isone(Symbolic(1.0))

# Basic identities
@test a + 0 == a
@test a + S"1 - 1" == a
@test a + b - a == b
@test a - 0 == a
@test a * 1 == a
@test a / 1 == a

@test a - a == 0
@test a * 0 == 0
@test 0 / a == 0
@test a \ 0 == 0
@test 1 ^ a == 1

@test a / 0 == Inf * a
@test -a / 0 == -Inf * a

@test a + a == 2a
@test a * 2 == 2a

@test a ^ 2 == a * a
@test a ^ -1 == 1 / a
@test a ^ -1 == a \ 1

@test a * b == b * a
@test A * B != B * A

@test -(a - b) == b - a
@test a + b + c == a + c + b == b + a + c == b + c + a == c + b + a == c + a + b
@test a + b - c == a - c + b == -c + a + b
@test (a + b) - (c + d) == a + b - c - d
@test a + (b - c) == (a + b) - c
@test a + 1 == 1 + a
@test a + 1 + 2 == 3 + a
@test -1 + a == a - 1
@test a * 2 == a * 1 * 2 == 2 * a

@test a * (a * b) == (a * a) * b
@test a * (b * c) * c == (a * b) * (c * c)

# @test 1 / (a / b) == b / a
# @test a / b \ a == b
# @test a / -b \ a == -b
@test a * b^-1 == a / b
@test a / b^-1 == a * b

# Conjugation and transpose

# @test conj(1im * a) == -1im * conj(a)
# @test (1im * a)' == -1im * a'
# @test (1im * a).' == 1im * a.'
# @test a' != a.'
# @test conj(a) != a'

# Simplify

@test a * c + b * c == Sylvia.expand((a + b) * c)
@test a * c + a * b == Sylvia.expand(a * (b + c))

# Arrays

M = [a b; c d]

@test M.' == Symbolic[a.' c.'; b.' d.']
@test M'  == Symbolic[a' c'; b' d']
@test M^2 == Symbolic[a ^ 2 + b * c  a * b + b * d
                      c * a + d * c  c * b + d ^ 2]
@test M^-1 == Symbolic[(1 + (b * c) / (a * ((-b * c) / a + d))) / a   -b / (a * ((-b * c) / a + d))
                       -c / (a * ((-b * c) / a + d))                  ((-b * c) / a + d) ^ -1]

#@test Symbolic([M 0I]) == Symbolic[ a b 0 0; c d 0 0 ]

# Functions

@def f = a - b
@def g(b, a) = a - b

@test f(4, 3) == -g(4, 3) == @λ(a-b)(4, 3) == 1

# @test_throws ArgumentError eval(@macroexpand @def f)
# @test_throws ArgumentError eval(@macroexpand @def f -> a + b)
# @test_throws ArgumentError eval(@macroexpand @def 4 = 4)
# @test_throws ArgumentError eval(@macroexpand @λ [a, b] -> a + b)

# # Symbols

# @test Sylvia.getsymbols(0) == Set([])
# @test Sylvia.getsymbols(a) == Set(Symbol[a])
# @test Sylvia.getsymbols(a') == Set(Symbol[a])
# @test Sylvia.getsymbols(a + b) == Set(Symbol[a, b])
# @test Sylvia.getsymbols([a b; b a]) == Set(Symbol[a, b])

# @test Sylvia.hassymbols(0) == Sylvia.hassymbols(S"1 + 2") == Sylvia.hassymbols(S"f(1)")

# # debug mode

# Sylvia.debug()
# @test string(a * b) == "S\"a * b\""
