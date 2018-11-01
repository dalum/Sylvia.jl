using Test
using Sylvia

@symbols Number a b c d
@symbols Bool x y z
@symbols Matrix{Float64} A B

@test a + b === S"a"Number + S"b"Number === S"a::Number + b::Number"Number
@test gather(a + b + c + d + a + b + c + d) === 2a + 2b + 2c + 2d

@assume iszero(a)
@assume a in b

@test iszero(a)
@test a in b

@assume istrue(x)
@assume isfalse(y)

@test gather(x & y) === y
@test gather(x | y) === x
@test gather(x | y | z) === x
@test gather((x | y) & z) === z

@test all(Matrix(A, 2, 2) .=== [A[1,1] A[1,2]; A[2,1] A[2,2]])
