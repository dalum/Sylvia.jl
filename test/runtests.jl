using Sylvia
using Test

@sym Number :: a b c d
@sym Bool :: x y z
@sym Matrix{Float64} :: A B

@testset "identities" begin
    @test a == S"a::Number" == @!(a::Number)
    @test a + b == S"(a + b)::Number" == @!((a + b)::Number)
    @test iszero(zero(a))
    @test iszero(zero(typeof(a)))
    @test isone(one(a))
    @test isone(one(typeof(a)))
    @test a[1] == getindex(a, 1)
    @test a.b == getproperty(a, :b)
end

@testset "contexts" begin
    @scope begin
        @! iszero(a) = true
        @! a in b = true
        @scope begin
            @! a in b = false
            @test iszero(a)
            @test !(a in b)
            @! unset a in b
            @! iszero(a) = false
            @test a in b
            @test !iszero(a)
            @! clear!
            @test iszero(a)
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
    @test gather(a + b + c + d + a + b + c + d) == 2a + 2b + 2c + 2d
    @scope begin
        @! iszero(a) = true
        @! isone(b) = true
        @test gather(a + b*c + c) == 2c
    end

    @scope begin
        @! istrue(x) = true
        @! isfalse(y) = true

        @test gather(x & y) == y
        @test gather(x | y) == x
        @test gather(x | y | z) == x
        @test gather((x | y) & z) == z
    end
end

@testset "substitution" begin
    @test substitute(a + b, a => b) == b + b
    @test substitute(a + b, a => A) == A + b
    @test substitute(a + b, a => b, strict=true) == b + b
    @test substitute(a + b, a => x, strict=true) == x + b
    @test_throws ErrorException substitute(a + b, a => A, strict=true)
end

@testset "arrays" begin
    @test all(Vector(A, 2) .== [A[1], A[2]])
    @test all(Matrix(A, 2, 2) .== [A[1,1] A[1,2]; A[2,1] A[2,2]])
end

# This function definition has to live at the top level
function h end

@testset "function generation" begin
    X = randn(2, 2)
    f = @λ (a, b, c) => a + b + c
    g = @λ (A,) => Matrix(A, 2, 2)^2

    x = a + b + c
    @! eval function h(a, b, c)
        x
    end

    @test f(1, 2, 3) == 6
    @test h(1, 2, 3) == 6
    @test g(X) ≈ X^2
end
