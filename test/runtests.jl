using Test
using Sylvia

@symbols Number a b c d

@test a + b === S"a"Number + S"b"Number === S"a::Number + b::Number"Number

@assume iszero(a)
@assume a in b
@test iszero(a)
@test a in b
