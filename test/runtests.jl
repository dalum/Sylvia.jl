using Sylvia
using Base.Test

@symbols a b c d

# Basic identities
@test a + 0 == a
@test a - 0 == a
@test a * 1 == a
@test a / 1 == a

@test a - a == 0
@test a * 0 == 0
@test 0 / a == 0
@test a \ 0 == 0

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
@test a / b == S"a / b"
@test a \ b == S"a^-1 * b"

@test conj(a * 1im) + conj(a)*1im == 0

@test [a b; c d] == Symbolic[:a :b; :c :d]
@test [a b; c d].' == Symbolic[:(a.') :(c.'); :(b.') :(d.')]
@test [a b; c d]' == Symbolic[:(a') :(c'); :(b') :(d')]
@test [a b; c d]^2 == [S"a ^ 2 + b * c"  S"a * b + b * d"
                       S"c * a + d * c"  S"c * b + d ^ 2"]
@test [a b; c d]^-1 == [S"a ^ -1 * (1 + (b * (d - c * a ^ -1 * b) ^ -1 * c) / a)" S"-((a ^ -1 * b) / (d - c * a ^ -1 * b))";
     S"-(((d - c * a ^ -1 * b) ^ -1 * c) / a)" S"(d - c * a ^ -1 * b) ^ -1"]

@def f = a - b
@def g(b, a) = a - b

@test f(4, 3) == -g(4, 3) == (@λ a - b)(4, 3) == 1
