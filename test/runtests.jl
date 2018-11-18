using Sylvia
using Test

using Sylvia: commuteswith, isfalse, istrue, sym

@sym obj
@sym [Number] a b c d
@sym [Bool] x y z
@sym [Matrix{Float64}] A B
@sym [Vector{Float64}] v w

@testset "identities" begin
    @test obj == sym(:obj)
    @test a == sym(Number, :a)
    @test (a, b) == sym(Number, :a, :b)
    @test a == S"a::Number" == @!(a::Number) == @! :a::Number
    @test a + b == S"(a + b)::Number" == @!((a + b)::Number) == @! :a::Number + :b::Number
    @test S"Float64" == @! Float64
    @test S"AbstractMatrix" == @! AbstractMatrix

    @test iszero(zero(a))
    @test iszero(zero(typeof(a)))
    @test isone(one(a))
    @test isone(one(typeof(a)))
    @test iszero(zero(S"Float64"))
    @test isone(one(S"Float64"))
    @test a[1] == getindex(a, 1)
    @test a[:b] == getindex(a, S":(:b)")
    @test a.b == getproperty(a, :b)
    @test a.b == getproperty(a, S":(:b)")
    @test a(1) == a(S"1") == Sylvia.apply(a, 1)
end

@testset "conversion" begin
    @sym [Float64] q r
    @test convert(Tuple{Sylvia.Sym{Float64}, Sylvia.Sym{Float64}}, (:q, :r)) == (q, r)
    @test convert(Tuple{Sylvia.Sym, Sylvia.Sym}, (:a, :b)) == (a, b)
end

@testset "promotion" begin
    for T in (Float32, Float64, Complex{Float32}, Complex{Float64})
        @test @!(a::T) + @!(b::T) isa Sylvia.Sym{T}
        @test @!(a::T) - @!(b::T) isa Sylvia.Sym{T}
        @test @!(a::T) * @!(b::T) isa Sylvia.Sym{T}
        @test @!(a::T) / @!(b::T) isa Sylvia.Sym{T}
        @test cos(@! a::T) isa Sylvia.Sym{T}
        @test sin(@! a::T) isa Sylvia.Sym{T}
        @test exp(@! a::T) isa Sylvia.Sym{T}
        @test log(@! a::T) isa Sylvia.Sym{T}
        @test (@! a::T)^2 isa Sylvia.Sym{T}
        @test (@! a::T)^-1 isa Sylvia.Sym{T}
    end
end

@testset "wild" begin
    @sym [Wild] wild_default [Wild{Number}] wild_number [Wild{Float64}] wild_float
    @test Sylvia.ismatch(Sylvia.match(a, wild_number))
    @test Sylvia.ismatch(Sylvia.match(wild_float, wild_default))
    @test !Sylvia.ismatch(Sylvia.match(wild_default, wild_float))
    @test Sylvia.ismatch(Sylvia.match(wild_number, wild_default))
    @test Sylvia.ismatch(Sylvia.match(@!(a::Float64), wild_float))
    @test !Sylvia.ismatch(Sylvia.match(a, wild_float))
end

@testset "mock" begin
    @sym [Mock] mock_default [Mock{Real}] mock_real [Mock{Float64}] mock_float
    function f(x::Number)
        y = x + 1
        return 2y
    end
    g(x::Number) = x

    @test_throws MethodError f(mock_default)
    @test_throws MethodError f(mock_real)
    @test_throws MethodError f(mock_float)
    @test_throws MethodError g(mock_default)
    @test_throws MethodError g(mock_real)
    @test_throws MethodError g(mock_float)

    Sylvia.@register f 1
    Sylvia.@register g 1

    @test f(mock_default) == Sylvia._apply(f, mock_default)
    @test f(mock_real) == 2(mock_real + 1)
    @test f(mock_float) == Sylvia._apply(f, mock_float)
    @test g(mock_default) == Sylvia._apply(g, mock_default)
    @test g(mock_real) == mock_real
    @test g(mock_float) == Sylvia._apply(g, mock_float)
end

@testset "default rules" begin
    @test commuteswith(+, a, b)
    @test commuteswith(+, A, B)
    @test commuteswith(+, A, b)
    @test commuteswith(+, a, B)

    @test commuteswith(*, a, b)
    @test commuteswith(*, a, B)
    @test commuteswith(*, A, b)
    @test commuteswith(*, A, B) isa Sylvia.Sym

    @test commuteswith(&, x, y)
    @test commuteswith(|, x, y)
end

@testset "dynamic rules" begin
    @scope begin
        @! set iszero(a) = true
        @! set a in b = true
        @scope begin
            @! set a in b = false
            @test iszero(a)
            @test !(a in b)
            @! unset a in b
            @! set iszero(a) = false
            @test a in b
            @test !iszero(a)
            @! clear!
            @test iszero(a)
        end
        @test iszero(a)
        @test a in b
    end
end

@testset "expr" begin
    @test Sylvia.expr(a) === :a
    @test Sylvia.expr(a + b) == :(a + b)
    @test Sylvia.expr((a, b, c, d)) == :((a, b, c, d))
    @test Sylvia.expr([a, b, c, d]) == :([a, b, c, d])
    @test Sylvia.getsymbols((a, b, c, d)) == [:a, :b, :c, :d]
    @test Sylvia.getsymbols([a, b, c, d]) == [:a, :b, :c, :d]
    @test Sylvia.getops((a + b, b * c, sin(d))) == [+, *, sin]
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
        @! set iszero(a) = true
        @! set isone(b) = true
        @test gather(a + b*c + c) == 2c
    end

    @scope begin
        @! set istrue(x) = true
        @! set isfalse(y) = true

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

    @! set length(v) = 4

    @test collect(v) == Vector(v, 4)
    for (i, vi) in enumerate(v)
        @test v[i] == vi
    end
end

@testset "@!" begin
    function g end
    @test @!(g(a)) == S"g(a)"
    @! set g(a) = a + 1
    @test a + 1 == @! resolve g(a)
end

# This function definition has to live at the top level
function h end

@testset "function generation" begin
    X = randn(2, 2)
    x = a + b + c
    @! eval :f(a, b, c) = x
    @! eval :g(A) = A^2
    @! eval function h(a, b, c)
        x
    end

    @test f(1, 2, 3) == 6
    @test h(1, 2, 3) == 6
    @test g(X) ≈ X^2
end
