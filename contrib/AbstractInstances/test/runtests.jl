using AbstractInstances
using Test

@testset "concrete types" begin
    for T in (Number, Real, AbstractVector, AbstractMatrix, AbstractArray)
        @test AbstractInstances.singletontype(T) <: T
        @test AbstractInstances.concretetype(T) <: T
    end
end

@testset "concrete instances" begin
    for T in (Number, Real, AbstractVector, AbstractMatrix, AbstractArray)
        s = AbstractInstances.singleton(T)
        c = AbstractInstances.oftype(T)
        @test s isa T
        @test s === AbstractInstances.singleton(T)
        @test c isa T
        @test c !== AbstractInstances.oftype(T)
    end
end
