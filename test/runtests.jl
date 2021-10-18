using Test
using FunctionIndices
using FunctionIndices: True, False
using OffsetArrays

@testset "FunctionIndices" begin
    A = collect(reshape(1:12, 3, 4))
    OA = OffsetArray(A, 2:4, 0:3)
    @testset "FI" begin
        @test A[FI(iseven), FI(iseven)] == A[[2], [2, 4]]
        @test OA[FI(iseven), FI(iseven)] == OA[[2, 4], [0, 2]] == A[[1, 3], [1, 3]]
        AdjA = A'
        @test AdjA[FI(iseven), FI(iseven)] ==
              AdjA[[2, 4], [2]] ==
              A[FI(iseven), FI(iseven)]'
    end

    @testset "not" begin
        @test ones()[not(CartesianIndex())] == 1
        @test A[not(1), not(2)] ==
              A[axes(A, 1).!=1, axes(A, 2).!=2] ==
              A[not(CartesianIndex(1, 2))] ==
              A[not(1), not(2)] ==
              A[not(CartesianIndex()), not(1), not(2)]
        @test isempty(A[not(1), not(2), not(1)])
        @test !isempty(A[not(1), not(2), not(2)])
        I = rand(Bool, 3)
        J = rand(Bool, 4)
        @test A[not(I), not(J)] == A[.!I, .!J]
        OA = OffsetArray(A, 2:4, 0:3)
        @test OA[not(1), not(2)] == OA[axes(OA, 1).!=1, axes(OA, 2).!=2] == A[:, not(3)]
        @test A[not(2)] ==
              A[not(CartesianIndex(2))] ==
              A[1:length(A).!=2] ==
              OA[not(2)] ==
              OA[not(CartesianIndex(2))] ==
              OA[1:length(A).!=2]
        @test A[not(2, 3)] == A[not(2:3)] == OA[not(2, 3)] == OA[not(2:3)]
        @test A[not(2, 3), not(1, 3)] ==
              A[not(2:3), not(1:2:3)] ==
              OA[not(3, 4), not(0, 2)] ==
              OA[not(3:4), not(0:2:2)]
        AdjA = A'
        @test AdjA[not(1), not(2)] ==
              AdjA[axes(AdjA, 1).!=1, axes(AdjA, 2).!=2] ==
              A[not(2), not(1)]'
    end

    @testset "enable/disable optimization" begin
        @test to_indices(A, (not(0:2:2),))[1] isa Vector{Int}
        # disable optimization for not(::StepRange)
        FunctionIndices.optimized(
            ::Type{<:AbstractArray},
            ::Type{<:NotIndex{<:StepRange}},
        ) = False()
        @test to_indices(A, (not(0:2:2),))[1] isa Base.LogicalIndex
    end
end
