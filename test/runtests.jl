using Base.Test
using Sylvia
using Sylvia: Symbolic, symbol

@symbols a b c d

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
@test 0 ^ a == S"0 ^ a"
@test 2 ^ a == S"2 ^ a"

@test a / 0 == Inf * a
@test -a / 0 == -Inf * a

@test a + a == 2a
@test a * 2 == 2a

@test a ^ 2 == a * a
@test a ^ -1 == 1 / a
@test a ^ -1 == a \ 1

@test a + b == S"a + b"
@test a - b == S"a - b"
@test a * b == S"a * b"
@test a * b != b * a
@test a / b == S"a / b"
@test a \ b == S"a^-1 * b"

@test -(a - b) == S"b - a"
@test a + b + c == a + c + b == b + a + c == b + c + a == c + b + a == c + a + b
@test a + b - c == a - c + b == -c + a + b
@test (a + b) - (c + d) == a + b - c - d
@test a + (b - c) == (a + b) - c
@test a + 1 == S"1 + a"
@test a + S"1 + 2" == S"3 + a"
@test -1 + a == S"a - 1"
@test a * c + b * c == S"(a + b) * c"
@test a * c + a * b == S"a * (b + c)"
@test a * 2 == a * S"1 * 2" == S"2 * a"

@test a * (a * b) == (a * a) * b
@test a * (b * c) * c == (a * b) * (c * c)

@test 1 / (a / b) == S"b / a"
@test a / b \ a == S"b"
@test a / -b \ a == S"-b"
@test a * b^-1 == S"a / b"
@test a / b^-1 == S"a * b"
@test a // b == S"a // b"

# Conjugation and transpose

@test conj(1im * a) == -1im * conj(a)
@test (1im * a)' == -1im * a'
@test (1im * a).' == 1im * a.'
@test a' != a.'
@test conj(a) != a'
@test (a * b)' * a' == S"b' * a' ^ 2"

# Arrays

A = [a b; c d]

@test A   == [S"a" S"b"; S"c" S"d"]
@test A.' == [S"a.'" S"c.'"; S"b.'" S"d.'"]
@test A'  == [S"a'" S"c'"; S"b'" S"d'"]
@test A^2 == [S"a ^ 2 + b * c"  S"a * b + b * d"
              S"c * a + d * c"  S"c * b + d ^ 2"]
@test A^-1 == [S"a ^ -1 * (1 + (b * (d - c * a ^ -1 * b) ^ -1 * c) / a)"  S"-((a ^ -1 * b) / (d - c * a ^ -1 * b))";
               S"-(((d - c * a ^ -1 * b) ^ -1 * c) / a)"                  S"(d - c * a ^ -1 * b) ^ -1"]

@test Symbolic([A 0I]) == [ S"a" S"b" S"0" S"0"; S"c" S"d" S"0" S"0" ]

# Functions

@def f = a - b
@def g(b, a) = a - b

@test f(4, 3) == -g(4, 3) == @λ(a-b)(4, 3) == 1

@test_throws ArgumentError eval(@macroexpand @def f)
@test_throws ArgumentError eval(@macroexpand @def f -> a + b)
@test_throws ArgumentError eval(@macroexpand @def 4 = 4)
@test_throws ArgumentError eval(@macroexpand @λ [a, b] -> a + b)

# Symbols

@test Sylvia.getsymbols(0) == Set([])
@test Sylvia.getsymbols(a) == Set(Symbol[a])
@test Sylvia.getsymbols(a') == Set(Symbol[a])
@test Sylvia.getsymbols(a + b) == Set(Symbol[a, b])
@test Sylvia.getsymbols([a b; b a]) == Set(Symbol[a, b])

@test Sylvia.hassymbols(0) == Sylvia.hassymbols(S"1 + 2") == Sylvia.hassymbols(S"f(1)")

# debug mode

Sylvia.debug()
@test string(a * b) == "S\"a * b\""
