using Test
using Sylvia

@symbols Number a b c d
@symbols Bool x y z
@symbols Matrix{Float64} A B

@testset "identities" begin
    @test a + b === S"a"Number + S"b"Number === S"a::Number + b::Number"Number
end

@testset "contexts" begin
    @scope begin
        @set! iszero(a) => true
        @set! a in b => true
        @scope begin
            @set! a in b => false
            @test iszero(a)
            @test !(a in b)
        end
        @test iszero(a)
        @test a in b
    end
end

@testset "combine" begin
    @test a[] == Sylvia.combine(:ref, a)
    @test a[1] == Sylvia.combine(:ref, a, S"1")
    @test a[1, 2] == Sylvia.combine(:ref, a, S"1", S"2")
    @test a' == Sylvia.combine(Symbol("'"), a)
end

@testset "tags" begin
    @test Sylvia.tagof(S"1") === Int
    @test Sylvia.tagof(S"1.0") === Float64
end

@testset "simplification" begin
    @test gather(a + b + c + d + a + b + c + d) === 2a + 2b + 2c + 2d

    @scope begin
        @set! istrue(x) => true
        @set! isfalse(y) => true

        @test gather(x & y) === y
        @test gather(x | y) === x
        @test gather(x | y | z) === x
        @test gather((x | y) & z) === z
    end
end

@testset "arrays" begin
    @test all(Vector(A, 2) .=== [A[1], A[2]])
    @test all(Matrix(A, 2, 2) .=== [A[1,1] A[1,2]; A[2,1] A[2,2]])
end
